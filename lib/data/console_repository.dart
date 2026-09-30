import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/offline_store.dart';
import '../core/session.dart';

/// Loads every console straight from the school core, caches the last
/// successful read for offline use, and queues writes made while offline.
class ConsoleRepository {
  ConsoleRepository({required this.api, required this.store});

  final TawasulApiClient api;
  final OfflineStore store;

  static const _draftQueueKey = 'tawasul_offline_drafts_v1';

  StreamSubscription<List<ConnectivityResult>>? _connectivity;

  /// School-system lists this person's role may not read (403). Pages that
  /// depend only on these are hidden from the role entirely.
  final Set<String> deniedPaths = <String>{};

  void startConnectivitySync() {
    _connectivity?.cancel();
    _connectivity = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((result) => result != ConnectivityResult.none);
      if (online) syncPendingDrafts();
    });
  }

  void dispose() {
    _connectivity?.cancel();
  }

  // ------------------------------------------------------------- loading ---

  String _cacheKey(AuthUser user, String? childId) =>
      'console_${user.role.name}_${user.personId}_${childId ?? 'self'}_v2';

  Future<ConsoleSnapshot> load(AuthUser user, {String? childId}) async {
    await syncPendingDrafts();
    final pending = (await _drafts()).length;
    try {
      final snapshot = await _loadFromApi(user, childId);
      await store.writeJson(_cacheKey(user, childId), snapshot.toJson());
      await store.writeJson('denied_${user.personId}', {'paths': deniedPaths.toList()});
      return snapshot.copyWith(pendingDraftCount: pending, isOffline: false);
    } catch (_) {
      final denied = await store.readJson('denied_${user.personId}');
      if (denied != null && denied['paths'] is List) {
        deniedPaths.addAll((denied['paths'] as List).map((path) => path.toString()));
      }
      final cached = await store.readJson(_cacheKey(user, childId));
      if (cached != null) {
        return ConsoleSnapshot.fromJson(cached).copyWith(isOffline: true, pendingDraftCount: pending);
      }
      rethrow;
    }
  }

  Future<ConsoleSnapshot> _loadFromApi(AuthUser user, String? childId) async {
    switch (user.role) {
      case ConsoleRole.teacher:
        return _loadTeacher(user);
      case ConsoleRole.parent:
        return _loadParent(user, childId);
      case ConsoleRole.student:
        return _loadStudent(user);
      case ConsoleRole.staff:
        return _loadStaff(user);
      case ConsoleRole.admin:
        return _loadAdmin(user);
    }
  }

  // --------------------------------------------------------------- admin ---

  /// Administrators: school-wide overview — classes, students, invoices,
  /// attendance rate, notices and messages. Every list is fetched
  /// defensively; missing endpoints yield empty pages rather than errors.
  Future<ConsoleSnapshot> _loadAdmin(AuthUser user) async {
    final allClasses = await _safeList('/classes', {'pageSize': '200'});
    final classes = allClasses
        .map((row) => ClassItem(
              id: row['tawasulCourseClassID']?.toString() ?? '',
              name: row['name']?.toString() ?? '',
              courseName: row['courseName']?.toString() ?? '',
              studentCount: int.tryParse(row['studentCount']?.toString() ?? '') ?? 0,
            ))
        .toList();

    final enrolments = await _safeList('/class-enrolments', {'pageSize': '500'});
    final students = <String, StudentItem>{};
    for (final row in enrolments.where((row) => row['role']?.toString() == 'Student')) {
      final id = row['tawasulPersonID']?.toString() ?? '';
      if (id.isEmpty) continue;
      final name = _fullName(row);
      students[id] = StudentItem(
        id: id,
        name: name,
        group: row['className']?.toString() ?? '',
        initials: _initials(name),
      );
    }

    final invoiceRows = await _safeList('/invoices', {'pageSize': '200', 'sort': '-invoiceDueDate'});
    final invoices = invoiceRows.map(_invoiceFrom).toList();

    final attendanceRows = await _safeList('/attendance', {'pageSize': '200', 'sort': '-date'});
    final attendance = attendanceRows.map(_attendanceFrom).toList();

    return ConsoleSnapshot(
      role: ConsoleRole.admin,
      personName: user.name,
      classes: classes,
      students: students.values.toList(),
      invoices: invoices,
      attendance: attendance,
      attendanceRate: _rate(attendance),
      notices: await _notices(user),
      messages: await _messagesFor(user),
    );
  }

  // --------------------------------------------------------------- staff ---

  /// Non-teaching staff: school-wide read view — classes, students, notices,
  /// messages. Every list is fetched defensively; missing endpoints yield
  /// empty pages rather than errors.
  Future<ConsoleSnapshot> _loadStaff(AuthUser user) async {
    final allClasses = await _safeList('/classes', {'pageSize': '200'});
    final classes = allClasses
        .map((row) => ClassItem(
              id: row['tawasulCourseClassID']?.toString() ?? '',
              name: row['name']?.toString() ?? '',
              courseName: row['courseName']?.toString() ?? '',
              studentCount: int.tryParse(row['studentCount']?.toString() ?? '') ?? 0,
            ))
        .toList();

    final enrolments = await _safeList('/class-enrolments', {'pageSize': '500'});
    final students = <String, StudentItem>{};
    for (final row in enrolments.where((row) => row['role']?.toString() == 'Student')) {
      final id = row['tawasulPersonID']?.toString() ?? '';
      if (id.isEmpty) continue;
      final name = _fullName(row);
      students[id] = StudentItem(
        id: id,
        name: name,
        group: row['className']?.toString() ?? '',
        initials: _initials(name),
      );
    }

    return ConsoleSnapshot(
      role: ConsoleRole.staff,
      personName: user.name,
      classes: classes,
      students: students.values.toList(),
      notices: await _notices(user),
      messages: await _messagesFor(user),
    );
  }

  // ------------------------------------------------------------- teacher ---

  Future<ConsoleSnapshot> _loadTeacher(AuthUser user) async {
    // Classes this teacher is attached to; the core does the filtering.
    final myEnrolments = await _safeList('/class-enrolments', {
      'tawasulPersonID': user.personId,
      'role': 'Teacher',
      'pageSize': '200',
    });
    final myClassIds = myEnrolments
        .map((row) => row['tawasulCourseClassID']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final allClasses = await _safeList('/classes', {'pageSize': '200'});
    final classes = allClasses
        .where((row) => myClassIds.contains(row['tawasulCourseClassID']?.toString()))
        .map((row) => ClassItem(
              id: row['tawasulCourseClassID']?.toString() ?? '',
              name: row['name']?.toString() ?? '',
              courseName: row['courseName']?.toString() ?? '',
              studentCount: int.tryParse(row['studentCount']?.toString() ?? '') ?? 0,
            ))
        .toList();
    final classIds = classes.map((item) => item.id).where((id) => id.isNotEmpty).toSet();

    // Roster, lessons, attendance and markbook entries, one class at a time.
    final enrolments = <Map<String, dynamic>>[];
    final lessonRows = <Map<String, dynamic>>[];
    final attendanceRows = <Map<String, dynamic>>[];
    final gradeRows = <Map<String, dynamic>>[];
    for (final id in classIds) {
      enrolments.addAll(await _safeList('/class-enrolments', {
        'tawasulCourseClassID': id,
        'role': 'Student',
        'pageSize': '200',
      }));
      lessonRows.addAll(await _safeList('/lessons', {
        'tawasulCourseClassID': id,
        'pageSize': '200',
        'sort': 'date',
      }));
      attendanceRows.addAll(await _safeList('/attendance', {
        'tawasulCourseClassID': id,
        'pageSize': '200',
        'sort': '-date',
      }));
      gradeRows.addAll(await _safeList('/markbook-entries', {
        'tawasulCourseClassID': id,
        'pageSize': '200',
      }));
    }

    final lessons = lessonRows.map(_lessonFrom).toList();

    final students = enrolments
        .map((row) => StudentItem(
              id: row['tawasulPersonID']?.toString() ?? '',
              name: _fullName(row),
              group: row['className']?.toString() ?? '',
              initials: _initials(_fullName(row)),
            ))
        .toList();
    final uniqueStudents = <String, StudentItem>{for (final student in students) '${student.id}|${student.group}': student};

    final attendance = attendanceRows.map(_attendanceFrom).toList();
    final notices = await _notices(user);
    final grades = gradeRows.map(_gradeFrom).toList();

    final studentIds = uniqueStudents.values.map((student) => student.id).toSet();
    final behaviourRows = await _safeList('/behaviour', {'pageSize': '500', 'sort': '-date'});
    final behaviour = behaviourRows
        .where((row) => studentIds.isEmpty || studentIds.contains(row['tawasulPersonID']?.toString()))
        .map((row) => BehaviourItem(
              title: row['type']?.toString() ?? row['descriptor']?.toString() ?? '',
              date: row['date']?.toString() ?? '',
              note: _stripHtml(row['comment']?.toString() ?? ''),
              positive: row['type']?.toString().toLowerCase() != 'negative',
            ))
        .toList();

    return ConsoleSnapshot(
      role: ConsoleRole.teacher,
      personName: user.name,
      classes: classes,
      lessons: lessons,
      students: uniqueStudents.values.toList(),
      notices: notices,
      grades: grades,
      behaviour: behaviour,
      messages: await _messagesFor(user),
      homework: _homeworkFrom(lessonRows),
      attendance: attendance,
      attendanceRate: _rate(attendance),
    );
  }

  // -------------------------------------------------------------- parent ---

  Future<ConsoleSnapshot> _loadParent(AuthUser user, String? childId) async {
    // Families this parent belongs to — filtered by the core itself.
    var adults = await _safeList('/family-adults', {'tawasulPersonID': user.personId});
    adults = adults.where((row) => row['tawasulPersonID']?.toString() == user.personId).toList();
    final familyIds = adults
        .where((row) => row['childDataAccess']?.toString() != 'N')
        .map((row) => row['tawasulFamilyID']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final childRows = <Map<String, dynamic>>[];
    for (final familyId in familyIds) {
      childRows.addAll((await _safeList('/family-children', {'tawasulFamilyID': familyId}))
          .where((row) => row['tawasulFamilyID']?.toString() == familyId));
    }
    final seen = <String>{};
    final children = childRows
        .where((row) => seen.add(row['tawasulPersonID']?.toString() ?? ''))
        .map((row) => StudentItem(
              id: row['tawasulPersonID']?.toString() ?? '',
              name: _fullName(row),
              group: row['familyName']?.toString() ?? '',
              initials: _initials(_fullName(row)),
            ))
        .where((child) => child.id.isNotEmpty)
        .toList();

    // Every child's own attendance, so the overview shows each rate.
    final attendanceByChild = <String, List<Map<String, dynamic>>>{};
    for (final child in children) {
      attendanceByChild[child.id] = await _attendanceRowsFor(child.id);
    }

    final enrichedChildren = children
        .map((child) {
          final records = (attendanceByChild[child.id] ?? const [])
              .where((row) => row['tawasulPersonID']?.toString() == child.id)
              .map(_attendanceFrom)
              .toList();
          return StudentItem(
            id: child.id,
            name: child.name,
            group: child.group,
            initials: child.initials,
            attendance: _rate(records),
          );
        })
        .toList();

    final selectedId = (childId != null && children.any((child) => child.id == childId))
        ? childId
        : (children.isEmpty ? '' : children.first.id);

    final childData = selectedId.isEmpty
        ? const ConsoleSnapshot(role: ConsoleRole.parent, personName: '')
        : await _studentData(selectedId, attendanceRows: attendanceByChild[selectedId]);

    return ConsoleSnapshot(
      role: ConsoleRole.parent,
      personName: user.name,
      children: enrichedChildren,
      selectedChildId: selectedId,
      classes: childData.classes,
      lessons: childData.lessons,
      homework: childData.homework,
      attendance: childData.attendance,
      attendanceRate: childData.attendanceRate,
      invoices: await _invoicesFor(children.map((child) => child.id).toSet()),
      behaviour: await _behaviourFor(selectedId),
      grades: await _gradesFor(selectedId),
      messages: await _messagesFor(user),
      notices: await _notices(user),
    );
  }

  /// Invoices are keyed by the student they were raised for
  /// (`tawasulPersonID`), so each child's invoices are asked for directly.
  Future<List<InvoiceItem>> _invoicesFor(Set<String> childIds) async {
    final rows = <String, Map<String, dynamic>>{};
    for (final id in childIds) {
      for (final row in await _safeList('/invoices', {'tawasulPersonID': id, 'sort': '-invoiceDueDate'})) {
        if (row['tawasulPersonID']?.toString() != id) continue;
        rows[row['tawasulFinanceInvoiceID']?.toString() ?? '${rows.length}'] = row;
      }
    }
    return rows.values.map(_invoiceFrom).toList();
  }

  InvoiceItem _invoiceFrom(Map<String, dynamic> row) {
    final title = (row['notes'] ?? row['name'] ?? row['title'] ?? '').toString();
    final due = row['invoiceDueDate']?.toString() ?? '';
    final student = _fullName(row);
    final amount = (row['invoiceTotal'] ?? row['finalAmount'] ?? row['amount'] ?? '').toString();
    return InvoiceItem(
      title: title.isEmpty ? '#${row['tawasulFinanceInvoiceID'] ?? ''}' : _stripHtml(title),
      amount: [amount, student, due].where((part) => part.trim().isNotEmpty).join(' · '),
      status: row['status']?.toString() ?? '',
    );
  }

  /// Attendance rows for one person, filtered by the core itself.
  Future<List<Map<String, dynamic>>> _attendanceRowsFor(String personId) {
    if (personId.isEmpty) return Future.value(const []);
    return _safeList('/attendance', {'tawasulPersonID': personId, 'pageSize': '200', 'sort': '-date'});
  }

  Future<List<BehaviourItem>> _behaviourFor(String personId) async {
    if (personId.isEmpty) return const [];
    final rows = await _safeList('/behaviour', {'tawasulPersonID': personId, 'pageSize': '200', 'sort': '-date'});
    return rows
        .map((row) => BehaviourItem(
              title: row['type']?.toString() ?? row['descriptor']?.toString() ?? '',
              date: row['date']?.toString() ?? '',
              note: _stripHtml(row['comment']?.toString() ?? ''),
              positive: row['type']?.toString().toLowerCase() != 'negative',
            ))
        .toList();
  }

  /// Markbook entries key the student as `tawasulPersonIDStudent`, so the
  /// core filters on that field rather than the generic person ID.
  Future<List<GradeItem>> _gradesFor(String personId) async {
    if (personId.isEmpty) return const [];
    final rows = await _safeList('/markbook-entries', {'tawasulPersonIDStudent': personId, 'pageSize': '200'});
    return rows.map(_gradeFrom).toList();
  }

  /// Messages addressed to this person. The core lists recipients in
  /// message receipts, so those decide what the person can see; anything
  /// they sent themselves is included too.
  Future<List<MessageItem>> _messagesFor(AuthUser user) async {
    final receipts = await _safeList('/message-receipts', {'tawasulPersonID': user.personId, 'pageSize': '200'});
    final addressed = receipts
        .map((row) => row['tawasulMessengerID']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final rows = await _safeList('/messages', {'pageSize': '50', 'sort': '-timestamp'});
    return rows
        .where((row) =>
            addressed.contains(row['tawasulMessengerID']?.toString()) ||
            row['tawasulPersonID']?.toString() == user.personId)
        .map((row) => MessageItem(
              title: row['subject']?.toString() ?? row['title']?.toString() ?? '',
              body: _stripHtml(row['body']?.toString() ?? row['text']?.toString() ?? ''),
              date: (row['timestamp']?.toString() ?? '').split(' ').first,
              sender: _fullName(row),
            ))
        .toList();
  }

  GradeItem _gradeFrom(Map<String, dynamic> row) => GradeItem(
        subject: row['className']?.toString() ?? row['courseName']?.toString() ?? '',
        value: row['attainmentValue']?.toString() ?? row['value']?.toString() ?? '',
        grade: row['attainmentGrade']?.toString() ?? row['grade']?.toString() ?? '',
      );

  // ------------------------------------------------------------- student ---

  Future<ConsoleSnapshot> _loadStudent(AuthUser user) async {
    final data = await _studentData(user.personId);
    return ConsoleSnapshot(
      role: ConsoleRole.student,
      personName: user.name,
      classes: data.classes,
      lessons: data.lessons,
      homework: data.homework,
      attendance: data.attendance,
      attendanceRate: data.attendanceRate,
      notices: await _notices(user),
      grades: await _gradesFor(user.personId),
      behaviour: await _behaviourFor(user.personId),
      messages: await _messagesFor(user),
    );
  }

  /// Timetable, homework and attendance for one student person ID. Every
  /// list is filtered by the core (per student / per class).
  Future<ConsoleSnapshot> _studentData(String personId, {List<Map<String, dynamic>>? attendanceRows}) async {
    final enrolments = (await _safeList('/class-enrolments', {'tawasulPersonID': personId, 'role': 'Student'}))
        .where((row) => row['tawasulPersonID']?.toString() == personId && row['role']?.toString() == 'Student')
        .where((row) => row['dateUnenrolled'] == null || row['dateUnenrolled'].toString().isEmpty)
        .toList();

    final classes = <String, ClassItem>{};
    for (final row in enrolments) {
      final id = row['tawasulCourseClassID']?.toString() ?? '';
      if (id.isEmpty) continue;
      classes[id] = ClassItem(id: id, name: row['className']?.toString() ?? '', courseName: row['courseName']?.toString() ?? '');
    }

    final lessonRows = <Map<String, dynamic>>[];
    for (final id in classes.keys) {
      lessonRows.addAll((await _safeList('/lessons', {'tawasulCourseClassID': id, 'sort': 'date'}))
          .where((row) => row['tawasulCourseClassID']?.toString() == id)
          .where((row) => row['viewableStudents']?.toString() != 'N' || row['viewableParents']?.toString() != 'N'));
    }
    lessonRows.sort((x, y) => '${x['date']} ${x['timeStart']}'.compareTo('${y['date']} ${y['timeStart']}'));

    final classNames = {for (final item in classes.values) item.id: item.name};
    final attendance = (attendanceRows ?? await _attendanceRowsFor(personId))
        .where((row) => row['tawasulPersonID']?.toString() == personId)
        .map((row) {
          final record = _attendanceFrom(row);
          final where = classNames[row['tawasulCourseClassID']?.toString()] ?? row['context']?.toString() ?? '';
          final reason = [row['reason'], row['comment']]
              .map((part) => part?.toString() ?? '')
              .where((part) => part.isNotEmpty)
              .join(' · ');
          return AttendanceRecord(
            date: record.date,
            status: record.status,
            note: [where, reason].where((part) => part.isNotEmpty).join(' · '),
            context: record.context,
          );
        })
        .toList();

    return ConsoleSnapshot(
      role: ConsoleRole.student,
      personName: '',
      classes: classes.values.toList(),
      lessons: lessonRows.map(_lessonFrom).toList(),
      homework: _homeworkFrom(lessonRows),
      attendance: attendance,
      attendanceRate: _rate(attendance),
    );
  }

  // ------------------------------------------------------------- writing ---

  /// Saves one attendance mark per student; queues them when offline.
  Future<bool> saveAttendance({
    required String classId,
    required String date,
    required Map<String, String> statusByStudentId,
    required String takerId,
  }) async {
    var allSent = true;
    for (final entry in statusByStudentId.entries) {
      final sent = await _sendOrQueue(
        DraftType.teacherAttendance,
        '/attendance',
        {
          'tawasulPersonID': entry.key,
          'date': date,
          'type': entry.value,
          'direction': 'In',
          'context': 'Class',
          'tawasulCourseClassID': classId,
          'tawasulPersonIDTaker': takerId,
        },
      );
      allSent = allSent && sent;
    }
    return allSent;
  }

  /// Publishes a lesson entry (with optional homework) for a class.
  Future<bool> publishLesson({
    required String classId,
    required String date,
    required String timeStart,
    required String timeEnd,
    required String name,
    String summary = '',
    String homeworkDetails = '',
    String homeworkDue = '',
  }) {
    return _sendOrQueue(DraftType.teacherLessonUpdate, '/lessons', {
      'tawasulCourseClassID': classId,
      'date': date,
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'name': name,
      'summary': summary,
      'viewableStudents': 'Y',
      'viewableParents': 'Y',
      if (homeworkDetails.isNotEmpty) 'homework': 'Y',
      if (homeworkDetails.isNotEmpty) 'homeworkDetails': homeworkDetails,
      if (homeworkDue.isNotEmpty) 'homeworkDueDateTime': '$homeworkDue 08:00:00',
    });
  }

  /// Returns true when the write reached the server, false when it was queued.
  Future<bool> _sendOrQueue(DraftType type, String endpoint, Map<String, dynamic> payload) async {
    try {
      await api.postMap(endpoint, payload);
      return true;
    } catch (_) {
      final drafts = await _drafts();
      drafts.add(OfflineDraft(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        endpoint: endpoint,
        method: 'POST',
        payload: payload,
        createdAt: DateTime.now().toIso8601String(),
      ));
      await _saveDrafts(drafts);
      return false;
    }
  }

  Future<int> pendingDraftCount() async => (await _drafts()).length;

  Future<void> syncPendingDrafts() async {
    final drafts = await _drafts();
    if (drafts.isEmpty) return;
    final remaining = <OfflineDraft>[];
    for (final draft in drafts) {
      try {
        await api.postMap(draft.endpoint, draft.payload);
      } catch (_) {
        remaining.add(draft);
      }
    }
    await _saveDrafts(remaining);
  }

  Future<List<OfflineDraft>> _drafts() async {
    final rows = await store.readJsonList(_draftQueueKey);
    return rows.map(OfflineDraft.fromJson).toList();
  }

  Future<void> _saveDrafts(List<OfflineDraft> drafts) =>
      store.writeJsonList(_draftQueueKey, drafts.map((draft) => draft.toJson()).toList());

  // ------------------------------------------------------------- helpers ---

  /// Reads one extra school page (groups, expenses, library ...) on demand.
  /// Throws [TawasulApiException] so the page can explain a refusal.
  /// Asks for one row of each list to learn whether this role may read it.
  Future<void> probe(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        await api.getMap(path, query: {'pageSize': '1'});
        deniedPaths.remove(path);
      } on TawasulApiException catch (error) {
        if (error.statusCode == 403) deniedPaths.add(path);
      } catch (_) {}
    }
  }

  // ------------------------------------------------------------ e-books ---

  static const ebookPath = '/library-items';

  /// Every place the school core can hold a digital book, scanned in turn:
  /// the Library catalogue, shared Resources and department resources.
  /// The result says why nothing showed up when the list is empty.
  Future<EbookCatalog> ebooks() async {
    final books = <EbookItem>[];
    final counts = <String, int>{};
    final denied = <String>[];

    Future<List<Map<String, dynamic>>> read(String path) async {
      try {
        final rows = await _safeListStrict(path);
        counts[path] = rows.length;
        return rows;
      } on TawasulApiException catch (error) {
        if (error.isUnauthorized) rethrow;
        if (error.statusCode == 403) denied.add(path);
        counts[path] = 0;
        return const [];
      }
    }

    // 1. Library catalogue (Library > Manage Catalog).
    for (final row in await read(ebookPath)) {
      final fields = _libraryFields(row['fields']);
      final image = row['imageLocation']?.toString() ?? '';
      final link = _pdfLinkIn([...fields.values, image, row['comment']?.toString() ?? '']) ??
          _anyLinkIn(fields.values) ??
          '';
      final isDigital = row['tawasulLibraryTypeID']?.toString() == '00014' || link.isNotEmpty;
      if (!isDigital) continue;
      books.add(EbookItem(
        id: row['tawasulLibraryItemID']?.toString() ?? '',
        source: 'library-items',
        title: _stripHtml(row['name']?.toString() ?? ''),
        author: _stripHtml(row['producer']?.toString() ?? ''),
        description: _stripHtml(row['comment']?.toString() ?? ''),
        link: link,
        cover: row['imageType']?.toString() == 'Link' && !_isPdf(image) ? image : '',
      ));
    }

    // 2. Shared resources (Planner > Resources): File or Link entries.
    for (final row in await read('/resources/export')) {
      final link = _pdfLinkIn([row['content']?.toString() ?? '']);
      if (link == null) continue;
      books.add(EbookItem(
        id: row['tawasulResourceID']?.toString() ?? '',
        source: 'resources',
        title: _stripHtml(row['name']?.toString() ?? ''),
        description: _stripHtml(row['description']?.toString() ?? ''),
        link: link,
      ));
    }

    // 3. Department resources.
    for (final row in await read('/department-resources')) {
      final link = _pdfLinkIn([row['url']?.toString() ?? '']);
      if (link == null) continue;
      books.add(EbookItem(
        id: row['tawasulDepartmentResourceID']?.toString() ?? '',
        source: 'department-resources',
        title: _stripHtml(row['name']?.toString() ?? ''),
        link: link,
      ));
    }

    books.sort((x, y) => x.title.compareTo(y.title));
    final scanned = counts.values.fold<int>(0, (sum, n) => sum + n);
    final EbookEmptyReason reason;
    if (books.isNotEmpty) {
      reason = EbookEmptyReason.none;
    } else if (denied.length == counts.length) {
      reason = EbookEmptyReason.noPermission;
    } else if (scanned == 0) {
      reason = EbookEmptyReason.catalogueEmpty;
    } else {
      reason = EbookEmptyReason.noPdfLinks;
    }
    return EbookCatalog(books: books, reason: reason, recordsScanned: scanned);
  }

  /// Like [_safeList] but lets a 403 through so the caller can explain it.
  Future<List<Map<String, dynamic>>> _safeListStrict(String path) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 1; page <= 25; page++) {
      final body = await api.getMap(path, query: {'pageSize': '200', 'page': '$page'});
      final chunk = TawasulApiClient.extractList(body);
      rows.addAll(chunk);
      final meta = body['meta'];
      final totalPages = meta is Map ? int.tryParse('${meta['totalPages']}') ?? 1 : 1;
      if (chunk.isEmpty || page >= totalPages) break;
    }
    return rows;
  }

  bool _isPdf(String value) => value.toLowerCase().split('?').first.trim().endsWith('.pdf');

  /// The school core keeps uploads as site-relative paths (uploads/2026/09/book.pdf)
  /// that the web server serves directly, so they need no API file transfer.
  String _absolute(String value) {
    final v = value.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final site = Uri.parse(api.baseUrl);
    final path = v.startsWith('/') ? v.substring(1) : v;
    return '${site.scheme}://${site.host}/$path';
  }

  static final _urlPattern = RegExp('(https?://[^\\s"\'<>]+|/?uploads/[^\\s"\'<>]+)', caseSensitive: false);

  String? _pdfLinkIn(Iterable<String> values) {
    for (final value in values) {
      final text = value.trim();
      if (text.isEmpty) continue;
      if (_isPdf(text) && !text.contains(' ')) return _absolute(text);
      for (final match in _urlPattern.allMatches(text)) {
        final found = match.group(0)!;
        if (_isPdf(found)) return _absolute(found);
      }
    }
    return null;
  }

  String? _anyLinkIn(Iterable<String> values) {
    for (final value in values) {
      final text = value.trim();
      if (text.startsWith('http://') || text.startsWith('https://')) return text;
    }
    return null;
  }

  Map<String, String> _libraryFields(dynamic raw) {
    try {
      final value = raw is String ? jsonDecode(raw) : raw;
      if (value is Map) return value.map((key, v) => MapEntry(key.toString(), v?.toString() ?? ''));
    } catch (_) {}
    return const {};
  }

  /// The PDF itself: the item's own link when it has one, otherwise the
  /// file attached to the catalogue record in the school system.
  Future<Uint8List> ebookBytes(EbookItem book) async {
    if (book.link.isNotEmpty) return api.getBytes(book.link);
    final body = await api.getMap('/files/${book.source}/${book.id}');
    final data = body['data'];
    final entries = data is List ? data : (data is Map ? (data['files'] ?? data.values.toList()) : const []);
    for (final entry in (entries as List).whereType<Map>()) {
      final url = (entry['url'] ?? entry['downloadUrl'] ?? '').toString();
      final field = (entry['field'] ?? entry['name'] ?? '').toString();
      final attached = entry['attached'] != false && entry['exists'] != false;
      if (!attached) continue;
      if (url.isNotEmpty) return api.getBytes(url);
      if (field.isNotEmpty) {
        return api.getBytes('/files/${book.source}/${book.id}/$field', query: {'disposition': 'inline'});
      }
    }
    throw TawasulApiException('No file attached', statusCode: 404);
  }

  // ---------------------------------------------------------- bookmarks ---

  String _readingKey(String personId, EbookItem book) => 'ebook_reading_${personId}_${book.source}_${book.id}';

  /// Where the reader stopped in this book and the pages they bookmarked.
  /// Kept on the device so it works offline.
  Future<ReadingState> readingState(String personId, EbookItem book) async {
    final json = await store.readJson(_readingKey(personId, book));
    if (json == null) return const ReadingState();
    return ReadingState(
      lastPage: int.tryParse('${json['lastPage']}') ?? 0,
      totalPages: int.tryParse('${json['totalPages']}') ?? 0,
      bookmarks: ((json['bookmarks'] as List?) ?? const [])
          .map((page) => int.tryParse('$page') ?? 0)
          .where((page) => page > 0)
          .toList()
        ..sort(),
    );
  }

  Future<void> saveReadingState(String personId, EbookItem book, ReadingState state) =>
      store.writeJson(_readingKey(personId, book), {
        'lastPage': state.lastPage,
        'totalPages': state.totalPages,
        'bookmarks': state.bookmarks,
      });

  // ------------------------------------------------------------- profile ---

  /// The person's own record plus the role-specific record (student
  /// enrolment, staff record or family link). Missing pieces stay empty.
  Future<ProfileData> loadProfile(AuthUser user) async {
    Map<String, dynamic> person = {};
    try {
      final body = await api.getMap('/users/${user.personId}');
      if (body['data'] is Map) person = Map<String, dynamic>.from(body['data'] as Map);
    } catch (_) {}
    Map<String, dynamic> extra = {};
    List<Map<String, dynamic>> family = [];
    List<Map<String, dynamic>> children = [];
    switch (user.role) {
      case ConsoleRole.student:
        final rows = await _safeList('/students', {'tawasulPersonID': user.personId});
        extra = rows.firstWhere((row) => row['tawasulPersonID']?.toString() == user.personId, orElse: () => {});
      case ConsoleRole.teacher:
      case ConsoleRole.staff:
      case ConsoleRole.admin:
        final rows = await _safeList('/staff', {'tawasulPersonID': user.personId});
        extra = rows.firstWhere((row) => row['tawasulPersonID']?.toString() == user.personId, orElse: () => {});
      case ConsoleRole.parent:
        family = (await _safeList('/family-adults', {'tawasulPersonID': user.personId}))
            .where((row) => row['tawasulPersonID']?.toString() == user.personId)
            .toList();
        for (final link in family) {
          final id = link['tawasulFamilyID']?.toString() ?? '';
          if (id.isEmpty) continue;
          children.addAll((await _safeList('/family-children', {'tawasulFamilyID': id}))
              .where((row) => row['tawasulFamilyID']?.toString() == id));
        }
    }
    return ProfileData(person: person, extra: extra, family: family, children: children);
  }

  /// Updates the person's own contact details. Returns false when the
  /// school system refuses (for example the role may not edit its record).
  Future<bool> updateContact(String personId, Map<String, String> fields) async {
    try {
      await api.patchMap('/users/$personId', fields);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Parent contact preferences live on the family-adult link.
  Future<bool> updateFamilyContact(String familyAdultId, Map<String, String> fields) async {
    try {
      await api.patchMap('/family-adults/$familyAdultId', fields);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sends a school-system notification to everyone in a class (teachers and
  /// students) and to the parents of its students. Returns how many were sent.
  Future<int> notifyClass(String classId, String text,
      {String link = '/index.php?q=/modules/Planner/planner.php'}) async {
    final people = <String>{};
    final students = <String>{};
    for (final r in await _safeList('/class-enrolments', {'tawasulCourseClassID': classId})) {
      if ('${r['tawasulCourseClassID']}' != classId) continue;
      if (r['dateUnenrolled'] != null && '${r['dateUnenrolled']}'.isNotEmpty) continue;
      final id = '${r['tawasulPersonID'] ?? ''}';
      if (id.isEmpty) continue;
      people.add(id);
      if ('${r['role']}' == 'Student') students.add(id);
    }
    final families = <String>{};
    for (final s in students) {
      for (final c in await _safeList('/family-children', {'tawasulPersonID': s})) {
        if ('${c['tawasulPersonID']}' == s && '${c['tawasulFamilyID'] ?? ''}'.isNotEmpty) families.add('${c['tawasulFamilyID']}');
      }
    }
    for (final f in families) {
      for (final a in await _safeList('/family-adults', {'tawasulFamilyID': f})) {
        if ('${a['tawasulFamilyID']}' == f && '${a['tawasulPersonID'] ?? ''}'.isNotEmpty) people.add('${a['tawasulPersonID']}');
      }
    }
    var sent = 0;
    for (final id in people) {
      try {
        await api.postMap('/notifications', {'tawasulPersonID': id, 'text': text, 'actionLink': link, 'status': 'New'});
        sent++;
      } catch (_) {}
    }
    return sent;
  }

  // ------------------------------------------------------- chat / messenger ---

  /// Returns chats this person participates in, sorted by most recent activity.
  Future<List<Map<String, dynamic>>> loadChats(AuthUser user) async {
    final rows = await _safeList('/chats', {'tawasulPersonID': user.personId});
    // Enrich with the last message preview for each chat.
    for (final row in rows) {
      final msgs = await _safeList('/chat-messages', {'chat_id': row['chat_id']?.toString() ?? '', 'pageSize': '1'});
      if (msgs.isNotEmpty) {
        row['lastMessageContent'] = msgs.first['content']?.toString() ?? '';
        row['lastMessageTimestamp'] = msgs.first['timestampCreated']?.toString() ?? '';
      } else {
        row['lastMessageContent'] = '';
        row['lastMessageTimestamp'] = '';
      }
    }
    return rows;
  }

  /// Loads messages for a specific chat.
  Future<List<Map<String, dynamic>>> loadChatMessages(String chatId) async {
    return _safeList('/chat-messages', {'chat_id': chatId, 'sortBy': 'timestampCreated', 'sortOrder': 'ASC'});
  }

  /// Loads participants for a specific chat.
  Future<List<Map<String, dynamic>>> loadChatParticipants(String chatId) async {
    return _safeList('/chat-participants', {'chat_id': chatId});
  }

  /// Sends a new message to a chat.
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String personId,
    required String content,
    String type = 'text',
  }) async {
    return api.postMap('/chat-messages', {
      'chat_id': chatId,
      'tawasulPersonID': personId,
      'type': type,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> fetchRecords(String path, {Map<String, String>? query}) =>
      api.getList(path, query: {'pageSize': '100', ...?query});

  Future<List<Map<String, dynamic>>> _safeList(String path, Map<String, String> query) async {
    try {
      final params = {'pageSize': '200', ...query};
      final rows = <Map<String, dynamic>>[];
      for (var page = 1; page <= 25; page++) {
        final body = await api.getMap(path, query: {...params, 'page': '$page'});
        final chunk = TawasulApiClient.extractList(body);
        rows.addAll(chunk);
        final meta = body['meta'];
        final totalPages = meta is Map ? int.tryParse('${meta['totalPages']}') ?? 1 : 1;
        if (chunk.isEmpty || page >= totalPages) break;
      }
      deniedPaths.remove(path);
      return rows;
    } on TawasulApiException catch (error) {
      if (error.isUnauthorized) rethrow;
      if (error.statusCode == 403) deniedPaths.add(path);
      return const [];
    }
  }

  Future<List<NoticeItem>> _notices(AuthUser user) async {
    // The core exposes no sort for notifications; asking for one is rejected.
    final rows = await _safeList('/notifications', {'pageSize': '30', 'tawasulPersonID': user.personId});
    return rows
        .where((row) => row['tawasulPersonID']?.toString() == user.personId)
        .map((row) => NoticeItem(
              title: row['text']?.toString() ?? '',
              date: (row['timestamp']?.toString() ?? '').split(' ').first,
              kind: row['moduleName']?.toString() ?? '',
              urgent: row['status']?.toString() == 'New',
            ))
        .toList();
  }

  LessonItem _lessonFrom(Map<String, dynamic> row) => LessonItem(
        id: row['tawasulPlannerEntryID']?.toString() ?? '',
        classId: row['tawasulCourseClassID']?.toString() ?? '',
        time: _shortTime(row['timeStart']) + (row['timeEnd'] == null ? '' : ' - ${_shortTime(row['timeEnd'])}'),
        subject: row['name']?.toString() ?? '',
        group: row['className']?.toString() ?? '',
        room: row['courseNameShort']?.toString() ?? '',
        date: row['date']?.toString() ?? '',
        summary: row['summary']?.toString() ?? '',
      );

  List<HomeworkItem> _homeworkFrom(Iterable<Map<String, dynamic>> rows) => rows
      .where((row) => row['homework']?.toString() == 'Y')
      .map((row) => HomeworkItem(
            subject: row['className']?.toString() ?? '',
            title: row['name']?.toString() ?? '',
            description: _stripHtml(row['homeworkDetails']?.toString() ?? ''),
            dueDate: (row['homeworkDueDateTime']?.toString() ?? '').split(' ').first,
            status: row['homeworkSubmission']?.toString() == 'Y' ? 'submission' : 'open',
          ))
      .toList();

  AttendanceRecord _attendanceFrom(Map<String, dynamic> row) => AttendanceRecord(
        date: row['date']?.toString() ?? '',
        status: row['type']?.toString() ?? '',
        note: _fullName(row),
        context: row['context']?.toString() ?? '',
      );

  String _rate(List<AttendanceRecord> records) {
    if (records.isEmpty) return '';
    final present = records.where((record) => record.status.toLowerCase().startsWith('present')).length;
    return '${((present / records.length) * 100).round()}%';
  }

  String _fullName(Map<String, dynamic> row) {
    final first = row['preferredName']?.toString() ?? row['firstName']?.toString() ?? '';
    final last = row['surname']?.toString() ?? '';
    return [first, last].where((part) => part.isNotEmpty).join(' ').trim();
  }

  String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return _firstLetter(parts.first);
    return '${_firstLetter(parts.first)}${_firstLetter(parts[1])}';
  }

  String _shortTime(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  String _stripHtml(String value) => value.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _firstLetter(String value) => value.isEmpty ? '' : value.substring(0, 1);

class ProfileData {
  const ProfileData({required this.person, required this.extra, required this.family, required this.children});
  final Map<String, dynamic> person;
  final Map<String, dynamic> extra;
  final List<Map<String, dynamic>> family;
  final List<Map<String, dynamic>> children;
}

class EbookItem {
  const EbookItem({
    required this.id,
    required this.title,
    this.source = 'library-items',
    this.author = '',
    this.description = '',
    this.link = '',
    this.cover = '',
  });
  final String id;
  final String title;
  final String source;
  final String author;
  final String description;
  final String link;
  final String cover;
}

enum EbookEmptyReason { none, catalogueEmpty, noPdfLinks, noPermission }

class EbookCatalog {
  const EbookCatalog({required this.books, required this.reason, required this.recordsScanned});
  final List<EbookItem> books;
  final EbookEmptyReason reason;
  final int recordsScanned;
}

class ReadingState {
  const ReadingState({this.lastPage = 0, this.totalPages = 0, this.bookmarks = const []});
  final int lastPage;
  final int totalPages;
  final List<int> bookmarks;

  ReadingState copyWith({int? lastPage, int? totalPages, List<int>? bookmarks}) => ReadingState(
        lastPage: lastPage ?? this.lastPage,
        totalPages: totalPages ?? this.totalPages,
        bookmarks: bookmarks ?? this.bookmarks,
      );
}
