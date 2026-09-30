enum ConsoleRole { teacher, parent, student, staff, admin }

enum TileTone { mint, sage, gold, green, red }

enum DraftType { teacherAttendance, teacherLessonUpdate }

class MetricTileData {
  const MetricTileData({required this.title, required this.value, this.hint = '', this.tone = TileTone.mint});
  final String title;
  final String value;
  final String hint;
  final TileTone tone;

  Map<String, dynamic> toJson() => {'title': title, 'value': value, 'hint': hint, 'tone': tone.name};
  factory MetricTileData.fromJson(Map<String, dynamic> json) => MetricTileData(
        title: json['title']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
        hint: json['hint']?.toString() ?? '',
        tone: TileTone.values.firstWhere((e) => e.name == json['tone'], orElse: () => TileTone.mint),
      );
}

class ClassItem {
  const ClassItem({required this.id, required this.name, this.courseName = '', this.studentCount = 0});
  final String id;
  final String name;
  final String courseName;
  final int studentCount;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'courseName': courseName, 'studentCount': studentCount};
  factory ClassItem.fromJson(Map<String, dynamic> json) => ClassItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        courseName: json['courseName']?.toString() ?? '',
        studentCount: int.tryParse(json['studentCount']?.toString() ?? '') ?? 0,
      );
}

class LessonItem {
  const LessonItem({required this.time, required this.subject, required this.group, this.room = '', this.id = '', this.classId = '', this.date = '', this.summary = ''});
  final String id;
  final String classId;
  final String time;
  final String subject;
  final String group;
  final String room;
  final String date;
  final String summary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'time': time,
        'subject': subject,
        'group': group,
        'room': room,
        'date': date,
        'summary': summary,
      };

  factory LessonItem.fromJson(Map<String, dynamic> json) => LessonItem(
        id: json['id']?.toString() ?? '',
        classId: json['classId']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        group: json['group']?.toString() ?? '',
        room: json['room']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        summary: json['summary']?.toString() ?? '',
      );
}

class StudentItem {
  const StudentItem({required this.name, required this.group, required this.initials, this.attendance = '', this.tone = TileTone.sage, this.id = ''});
  final String id;
  final String name;
  final String group;
  final String initials;
  final String attendance;
  final TileTone tone;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'group': group, 'initials': initials, 'attendance': attendance, 'tone': tone.name};
  factory StudentItem.fromJson(Map<String, dynamic> json) => StudentItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        group: json['group']?.toString() ?? '',
        initials: json['initials']?.toString() ?? '',
        attendance: json['attendance']?.toString() ?? '',
        tone: TileTone.values.firstWhere((e) => e.name == json['tone'], orElse: () => TileTone.sage),
      );
}

class NoticeItem {
  const NoticeItem({required this.title, required this.date, required this.kind, this.urgent = false});
  final String title;
  final String date;
  final String kind;
  final bool urgent;

  Map<String, dynamic> toJson() => {'title': title, 'date': date, 'kind': kind, 'urgent': urgent};
  factory NoticeItem.fromJson(Map<String, dynamic> json) => NoticeItem(
        title: json['title']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        kind: json['kind']?.toString() ?? '',
        urgent: json['urgent'] == true,
      );
}

class GradeItem {
  const GradeItem({required this.subject, required this.value, required this.grade});
  final String subject;
  final String value;
  final String grade;

  Map<String, dynamic> toJson() => {'subject': subject, 'value': value, 'grade': grade};
  factory GradeItem.fromJson(Map<String, dynamic> json) => GradeItem(
        subject: json['subject']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
        grade: json['grade']?.toString() ?? '',
      );
}

class InvoiceItem {
  const InvoiceItem({required this.title, required this.amount, required this.status});
  final String title;
  final String amount;
  final String status;

  Map<String, dynamic> toJson() => {'title': title, 'amount': amount, 'status': status};
  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        title: json['title']?.toString() ?? '',
        amount: json['amount']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
      );
}

class BehaviourItem {
  const BehaviourItem({required this.title, required this.date, required this.note, this.positive = true});
  final String title;
  final String date;
  final String note;
  final bool positive;

  Map<String, dynamic> toJson() => {'title': title, 'date': date, 'note': note, 'positive': positive};
  factory BehaviourItem.fromJson(Map<String, dynamic> json) => BehaviourItem(
        title: json['title']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
        positive: json['positive'] != false,
      );
}

class MessageItem {
  const MessageItem({required this.title, required this.body, required this.date, this.sender = ''});
  final String title;
  final String body;
  final String date;
  final String sender;

  Map<String, dynamic> toJson() => {'title': title, 'body': body, 'date': date, 'sender': sender};
  factory MessageItem.fromJson(Map<String, dynamic> json) => MessageItem(
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        sender: json['sender']?.toString() ?? '',
      );
}

class HomeworkItem {
  const HomeworkItem({
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.score = '',
  });

  final String subject;
  final String title;
  final String description;
  final String dueDate;
  final String status;
  final String score;

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'status': status,
        'score': score,
      };

  factory HomeworkItem.fromJson(Map<String, dynamic> json) => HomeworkItem(
        subject: json['subject']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        dueDate: json['dueDate']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        score: json['score']?.toString() ?? '',
      );
}

class AttendanceRecord {
  const AttendanceRecord({required this.date, required this.status, this.note = '', this.context = ''});

  final String date;
  final String status;
  final String note;
  final String context;

  Map<String, dynamic> toJson() => {'date': date, 'status': status, 'note': note, 'context': context};
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        date: json['date']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
        context: json['context']?.toString() ?? '',
      );
}

class OfflineDraft {
  const OfflineDraft({required this.id, required this.type, required this.endpoint, required this.method, required this.payload, required this.createdAt});

  final String id;
  final DraftType type;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'createdAt': createdAt,
      };

  factory OfflineDraft.fromJson(Map<String, dynamic> json) => OfflineDraft(
        id: json['id']?.toString() ?? '',
        type: DraftType.values.firstWhere((entry) => entry.name == json['type'], orElse: () => DraftType.teacherAttendance),
        endpoint: json['endpoint']?.toString() ?? '',
        method: json['method']?.toString() ?? 'POST',
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class ConsoleSnapshot {
  const ConsoleSnapshot({
    required this.role,
    required this.personName,
    this.classes = const [],
    this.lessons = const [],
    this.students = const [],
    this.children = const [],
    this.selectedChildId = '',
    this.notices = const [],
    this.grades = const [],
    this.invoices = const [],
    this.behaviour = const [],
    this.messages = const [],
    this.homework = const [],
    this.attendance = const [],
    this.attendanceRate = '',
    this.pendingDraftCount = 0,
    this.isOffline = false,
  });

  final ConsoleRole role;
  final String personName;
  final List<ClassItem> classes;
  final List<LessonItem> lessons;
  final List<StudentItem> students;
  final List<StudentItem> children;
  final String selectedChildId;
  final List<NoticeItem> notices;
  final List<GradeItem> grades;
  final List<InvoiceItem> invoices;
  final List<BehaviourItem> behaviour;
  final List<MessageItem> messages;
  final List<HomeworkItem> homework;
  final List<AttendanceRecord> attendance;
  final String attendanceRate;
  final int pendingDraftCount;
  final bool isOffline;

  ConsoleSnapshot copyWith({bool? isOffline, int? pendingDraftCount, String? selectedChildId}) => ConsoleSnapshot(
        role: role,
        personName: personName,
        classes: classes,
        lessons: lessons,
        students: students,
        children: children,
        selectedChildId: selectedChildId ?? this.selectedChildId,
        notices: notices,
        grades: grades,
        invoices: invoices,
        behaviour: behaviour,
        messages: messages,
        homework: homework,
        attendance: attendance,
        attendanceRate: attendanceRate,
        pendingDraftCount: pendingDraftCount ?? this.pendingDraftCount,
        isOffline: isOffline ?? this.isOffline,
      );

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'personName': personName,
        'classes': classes.map((e) => e.toJson()).toList(),
        'lessons': lessons.map((e) => e.toJson()).toList(),
        'students': students.map((e) => e.toJson()).toList(),
        'children': children.map((e) => e.toJson()).toList(),
        'selectedChildId': selectedChildId,
        'notices': notices.map((e) => e.toJson()).toList(),
        'grades': grades.map((e) => e.toJson()).toList(),
        'invoices': invoices.map((e) => e.toJson()).toList(),
        'behaviour': behaviour.map((e) => e.toJson()).toList(),
        'messages': messages.map((e) => e.toJson()).toList(),
        'homework': homework.map((e) => e.toJson()).toList(),
        'attendance': attendance.map((e) => e.toJson()).toList(),
        'attendanceRate': attendanceRate,
        'pendingDraftCount': pendingDraftCount,
      };

  static List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) mapper) =>
      (value as List? ?? const []).whereType<Map>().map((e) => mapper(Map<String, dynamic>.from(e))).toList();

  factory ConsoleSnapshot.fromJson(Map<String, dynamic> json) => ConsoleSnapshot(
        role: ConsoleRole.values.firstWhere((e) => e.name == json['role'], orElse: () => ConsoleRole.student),
        personName: json['personName']?.toString() ?? '',
        classes: _list(json['classes'], ClassItem.fromJson),
        lessons: _list(json['lessons'], LessonItem.fromJson),
        students: _list(json['students'], StudentItem.fromJson),
        children: _list(json['children'], StudentItem.fromJson),
        selectedChildId: json['selectedChildId']?.toString() ?? '',
        notices: _list(json['notices'], NoticeItem.fromJson),
        grades: _list(json['grades'], GradeItem.fromJson),
        invoices: _list(json['invoices'], InvoiceItem.fromJson),
        behaviour: _list(json['behaviour'], BehaviourItem.fromJson),
        messages: _list(json['messages'], MessageItem.fromJson),
        homework: _list(json['homework'], HomeworkItem.fromJson),
        attendance: _list(json['attendance'], AttendanceRecord.fromJson),
        attendanceRate: json['attendanceRate']?.toString() ?? '',
        pendingDraftCount: int.tryParse(json['pendingDraftCount']?.toString() ?? '') ?? 0,
      );
}
