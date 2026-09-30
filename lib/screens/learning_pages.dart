import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';

// Lessons, homework, grades and tests, built only on lists the school system
// serves: lessons, planner-entry-homeworks, markbook-columns, markbook-entries.
// A test is a lesson (for submissions) plus a markbook column of type "Test"
// whose description carries the questions and the time limit.

String _today() => DateTime.now().toIso8601String().split('T').first;

/// Accepts YYYY-MM-DD or DD.MM.YYYY / DD/MM/YYYY and returns YYYY-MM-DD.
String _isoDate(String value) {
  final v = value.trim();
  final m = RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})$').firstMatch(v);
  if (m != null) return '${m[3]}-${m[2]!.padLeft(2, '0')}-${m[1]!.padLeft(2, '0')}';
  return v.isEmpty ? _today() : v;
}

/// Read-only field that opens the calendar; defaults to today.
class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(_isoDate(controller.text)) ?? now,
            firstDate: DateTime(now.year - 1),
            lastDate: DateTime(now.year + 2),
          );
          if (picked != null) controller.text = picked.toIso8601String().split('T').first;
        },
      ),
    );
  }
}

/// Time field that opens the clock picker, stores HH:MM.
class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
        onTap: () async {
          final parts = controller.text.split(':');
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: int.tryParse(parts.first) ?? 8, minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0),
          );
          if (picked != null) {
            controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          }
        },
      ),
    );
  }
}

Future<void> _notify(BuildContext context, ConsoleRepository repo, String classId, String text, bool ar) async {
  final n = await repo.notifyClass(classId, text);
  if (context.mounted && n > 0) _toast(context, ar ? 'أُرسل إشعار إلى $n من المشاركين وأولياء الأمور' : 'Notified $n people');
}

String _idOf(Map<String, dynamic> body, List<String> keys) {
  final data = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
  for (final key in [...keys, 'id']) {
    final value = data[key];
    if (value != null && '$value'.isNotEmpty) return '$value';
  }
  return '';
}

String _explain(Object error, bool ar) {
  if (error is TawasulApiException) {
    if (error.statusCode == 403) {
      return ar ? 'صلاحيات دورك في النظام لا تسمح بهذا الإجراء.' : 'Your role is not allowed to do this.';
    }
    if (error.statusCode == 401) return ar ? 'انتهت الجلسة، سجّل الدخول مجددًا.' : 'Session expired, sign in again.';
    return error.message;
  }
  return ar ? 'تعذر الاتصال بالنظام.' : 'Could not reach the school system.';
}

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class TestInfo {
  TestInfo({
    required this.columnId,
    required this.lessonId,
    required this.classId,
    required this.name,
    required this.date,
    required this.minutes,
    required this.maxScore,
    required this.questions,
  });

  final String columnId;
  final String lessonId;
  final String classId;
  final String name;
  final String date;
  final int minutes;
  final String maxScore;
  final List<String> questions;

  static TestInfo? fromRow(Map<String, dynamic> row) {
    try {
      final meta = jsonDecode('${row['description'] ?? ''}');
      if (meta is! Map || meta['tawasulTest'] == null) return null;
      return TestInfo(
        columnId: '${row['tawasulMarkbookColumnID'] ?? ''}',
        lessonId: '${row['tawasulPlannerEntryID'] ?? ''}',
        classId: '${row['tawasulCourseClassID'] ?? ''}',
        name: '${row['name'] ?? ''}',
        date: '${row['date'] ?? ''}',
        minutes: int.tryParse('${meta['minutes']}') ?? 30,
        maxScore: '${row['attainmentRawMax'] ?? ''}',
        questions: (meta['questions'] as List? ?? const []).map((q) => '$q').toList(),
      );
    } catch (_) {
      return null;
    }
  }
}

class _Data {
  _Data(this.repo);
  final ConsoleRepository repo;
  TawasulApiClient get api => repo.api;

  Future<List<TestInfo>> tests(Iterable<String> classIds) async {
    final out = <TestInfo>[];
    for (final id in classIds) {
      final rows = await repo.fetchRecords('/markbook-columns', query: {'tawasulCourseClassID': id, 'type': 'Test'});
      out.addAll(rows.map(TestInfo.fromRow).whereType<TestInfo>());
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  Future<List<Map<String, dynamic>>> columns(String classId) =>
      repo.fetchRecords('/markbook-columns', query: {'tawasulCourseClassID': classId});

  Future<List<Map<String, dynamic>>> entries(String columnId) =>
      repo.fetchRecords('/markbook-entries', query: {'tawasulMarkbookColumnID': columnId});

  Future<List<Map<String, dynamic>>> submissions(String lessonId, {String? personId}) =>
      repo.fetchRecords('/planner-entry-homeworks', query: {
        'tawasulPlannerEntryID': lessonId,
        if (personId != null) 'tawasulPersonID': personId,
      });

  Future<void> saveMark({
    required String columnId,
    required String studentId,
    required String score,
    required String comment,
    String? existingId,
  }) async {
    final body = {
      'tawasulMarkbookColumnID': columnId,
      'tawasulPersonIDStudent': studentId,
      'attainmentValue': score,
      'attainmentValueRaw': score,
      'comment': comment,
    };
    if (existingId != null && existingId.isNotEmpty) {
      await api.patchMap('/markbook-entries/$existingId', body);
    } else {
      await api.postMap('/markbook-entries', body);
    }
  }

  Future<void> submit(String lessonId, String personId, String text) async {
    final clipped = text.length > 255 ? text.substring(0, 255) : text;
    await api.postMap('/planner-entry-homeworks', {
      'tawasulPlannerEntryID': int.tryParse(lessonId) ?? lessonId,
      'tawasulPersonID': int.tryParse(personId) ?? personId,
      'type': 'Link',
      'version': 'Final',
      'status': 'On Time',
      'location': clipped,
      'count': 1,
      'timestamp': DateTime.now().toIso8601String().replaceFirst('T', ' ').split('.').first,
    });
  }
}

class _Section {
  const _Section(this.ar, this.en, this.builder);
  final String ar;
  final String en;
  final Widget Function() builder;
}

class _Hub extends StatefulWidget {
  const _Hub({super.key, required this.sections, this.initial = 0});
  final List<_Section> sections;
  final int initial;
  @override
  State<_Hub> createState() => _HubState();
}

class _HubState extends State<_Hub> {
  late int _i = widget.initial.clamp(0, widget.sections.length - 1);
  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              for (var i = 0; i < widget.sections.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(ar ? widget.sections[i].ar : widget.sections[i].en),
                    selected: _i == i,
                    selectedColor: AppColors.gold,
                    onSelected: (_) => setState(() => _i = i),
                  ),
                ),
            ],
          ),
        ),
        KeyedSubtree(key: ValueKey(_i), child: widget.sections[_i].builder()),
      ],
    );
  }
}

Widget _dropdown<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );

Widget _classPicker(List<ClassItem> classes, String? value, ValueChanged<String?> onChanged, bool ar) => _dropdown<String>(
      label: ar ? 'الصف' : 'Class',
      value: value,
      items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
      onChanged: onChanged,
    );

// ================================================================ teacher ===

/// Lessons page: lesson plan, lesson summary, new homework, receive homework.
Widget teacherLessonsHub({
  required ConsoleSnapshot snapshot,
  required ConsoleRepository repository,
  required Widget summaryForm,
  int initial = 0,
}) {
  final data = _Data(repository);
  return _Hub(key: ValueKey('lessons$initial'), initial: initial, sections: [
    _Section('خطة الدرس', 'Lesson plan', () => _LessonPlanForm(snapshot: snapshot, data: data)),
    _Section('ملخص الدرس', 'Lesson summary', () => summaryForm),
    _Section('إنشاء واجب', 'New homework', () => _HomeworkForm(snapshot: snapshot, data: data)),
    _Section('استلام الواجب', 'Receive homework', () => _HomeworkInbox(snapshot: snapshot, data: data)),
  ]);
}

/// Tests page: grades, new test, marking, results.
Widget teacherLearningHub({required ConsoleSnapshot snapshot, required ConsoleRepository repository}) {
  final data = _Data(repository);
  return _Hub(sections: [
    _Section('إضافة الدرجات', 'Add grades', () => _GradesForm(snapshot: snapshot, data: data)),
    _Section('إضافة اختبار', 'New test', () => _TestForm(snapshot: snapshot, data: data)),
    _Section('تصحيح الاختبار', 'Mark test', () => _TestGrader(snapshot: snapshot, data: data)),
    _Section('النتائج', 'Results', () => _TeacherResults(snapshot: snapshot, data: data)),
  ]);
}

/// Homework lessons of the given classes, newest first.
Future<List<Map<String, dynamic>>> _homeworkLessons(_Data data, Iterable<String> classIds) async {
  final out = <Map<String, dynamic>>[];
  for (final id in classIds) {
    final rows = await data.repo.fetchRecords('/lessons', query: {'tawasulCourseClassID': id, 'homework': 'Y'});
    out.addAll(rows.where((r) => '${r['homework']}' == 'Y' && '${r['tawasulCourseClassID']}' == id));
  }
  out.sort((a, b) => '${b['homeworkDueDateTime'] ?? b['date']}'.compareTo('${a['homeworkDueDateTime'] ?? a['date']}'));
  return out;
}

List<StudentItem> _rosterOf(ConsoleSnapshot s, String classId) {
  final name = s.classes.firstWhere((c) => c.id == classId, orElse: () => const ClassItem(id: '', name: '')).name;
  final seen = <String>{};
  return s.students.where((st) => st.group == name && seen.add(st.id)).toList();
}

/// Dashboard table: per homework, how many students submitted and how many not yet.
class HomeworkStatsTable extends StatefulWidget {
  const HomeworkStatsTable({super.key, required this.snapshot, required this.repository});
  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  @override
  State<HomeworkStatsTable> createState() => _HomeworkStatsTableState();
}

class _HomeworkStatsTableState extends State<HomeworkStatsTable> {
  late final _Data _data = _Data(widget.repository);
  late final Future<List<(String, String, int, int)>> _future = _load();

  Future<List<(String, String, int, int)>> _load() async {
    final lessons = (await _homeworkLessons(_data, widget.snapshot.classes.map((c) => c.id))).take(8);
    final out = <(String, String, int, int)>[];
    for (final l in lessons) {
      final classId = '${l['tawasulCourseClassID']}';
      final roster = _rosterOf(widget.snapshot, classId).map((s) => s.id).toSet();
      final subs = await _data.submissions('${l['tawasulPlannerEntryID']}');
      final done = subs.map((r) => '${r['tawasulPersonID']}').where(roster.contains).toSet().length;
      out.add(('${l['name'] ?? ''}', '${l['className'] ?? ''}', done, (roster.length - done).clamp(0, 1 << 20)));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    return WhitePanel(
      title: ar ? 'إحصائيات تسليم الواجبات' : 'Homework submissions',
      child: FutureBuilder<List<(String, String, int, int)>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return Text(L10n.of(context).loading);
          if (snap.hasError) return EmptyState(message: _explain(snap.error!, ar));
          final rows = snap.data ?? const [];
          if (rows.isEmpty) return EmptyState(message: ar ? 'لا توجد واجبات' : 'No homework yet');
          const head = TextStyle(fontWeight: FontWeight.w800, color: AppColors.pine, fontSize: 12);
          return Table(
            columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.2)},
            children: [
              TableRow(children: [
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(ar ? 'الواجب' : 'Homework', style: head)),
                Text(ar ? 'سلّموا' : 'Submitted', style: head, textAlign: TextAlign.center),
                Text(ar ? 'لم يسلّموا' : 'Not yet', style: head, textAlign: TextAlign.center),
              ]),
              for (final (name, cls, done, left) in rows)
                TableRow(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                        Text(cls, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      ]),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 10), child: Text('$done', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800))),
                    Padding(padding: const EdgeInsets.only(top: 10), child: Text('$left', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800))),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Receive and check homework: who submitted what, who has not, and set each status.
class _HomeworkInbox extends StatefulWidget {
  const _HomeworkInbox({required this.snapshot, required this.data});
  final ConsoleSnapshot snapshot;
  final _Data data;
  @override
  State<_HomeworkInbox> createState() => _HomeworkInboxState();
}

class _HomeworkInboxState extends State<_HomeworkInbox> {
  late final Future<List<Map<String, dynamic>>> _lessons =
      _homeworkLessons(widget.data, widget.snapshot.classes.map((c) => c.id));
  String? _lessonId;
  Future<List<Map<String, dynamic>>>? _subs;

  void _pick(String id) => setState(() {
        _lessonId = id;
        _subs = widget.data.submissions(id);
      });

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    return WhitePanel(
      title: ar ? 'استلام الواجب والتحقق منه' : 'Receive and check homework',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _lessons,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return Text(L10n.of(context).loading);
          if (snap.hasError) return EmptyState(message: _explain(snap.error!, ar));
          final lessons = snap.data ?? const [];
          if (lessons.isEmpty) return EmptyState(message: ar ? 'لا توجد واجبات' : 'No homework yet');
          final current = _lessonId ?? '${lessons.first['tawasulPlannerEntryID']}';
          if (_subs == null) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && _subs == null) _pick(current); });
          final lesson = lessons.firstWhere((l) => '${l['tawasulPlannerEntryID']}' == current, orElse: () => lessons.first);
          final roster = _rosterOf(widget.snapshot, '${lesson['tawasulCourseClassID']}');
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _dropdown<String>(
              label: ar ? 'الواجب' : 'Homework',
              value: current,
              items: lessons
                  .map((l) => DropdownMenuItem(
                        value: '${l['tawasulPlannerEntryID']}',
                        child: Text('${'${l['homeworkDueDateTime'] ?? ''}'.split(' ').first} · ${l['name'] ?? ''} · ${l['className'] ?? ''}', overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) { if (v != null) _pick(v); },
            ),
            Text('${lesson['homeworkDetails'] ?? ''}', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _subs,
              builder: (context, s) {
                if (s.connectionState != ConnectionState.done) return Text(L10n.of(context).loading);
                if (s.hasError) return EmptyState(message: _explain(s.error!, ar));
                final byPerson = {for (final r in s.data ?? const <Map<String, dynamic>>[]) '${r['tawasulPersonID']}': r};
                if (roster.isEmpty && byPerson.isEmpty) return const EmptyState();
                final ids = {...roster.map((r) => r.id), ...byPerson.keys};
                final names = {for (final r in roster) r.id: r.name};
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(
                    '${ar ? 'سلّموا' : 'Submitted'}: ${byPerson.length} · ${ar ? 'لم يسلّموا' : 'Not yet'}: ${(ids.length - byPerson.length).clamp(0, 1 << 20)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.pine),
                  ),
                  const SizedBox(height: 8),
                  for (final id in ids) _row(id, names[id] ?? '${byPerson[id]?['surname'] ?? ''} ${byPerson[id]?['preferredName'] ?? id}', byPerson[id], ar),
                ]);
              },
            ),
          ]);
        },
      ),
    );
  }

  Widget _row(String personId, String name, Map<String, dynamic>? sub, bool ar) {
    final statuses = {'On Time': ar ? 'في الوقت' : 'On time', 'Late': ar ? 'متأخر' : 'Late', 'Exemption': ar ? 'معفى' : 'Exempt'};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppRadii.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name.trim().isEmpty ? personId : name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink))),
          StatusPill(
            label: sub == null ? (ar ? 'لم يسلّم' : 'Not submitted') : (ar ? 'سلّم' : 'Submitted'),
            color: sub == null ? AppColors.red : AppColors.green,
          ),
        ]),
        if (sub != null) ...[
          const SizedBox(height: 6),
          SelectableText('${sub['location'] ?? ''}'),
          Text('${sub['timestamp'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            for (final e in statuses.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: '${sub['status']}' == e.key,
                selectedColor: AppColors.mint,
                onSelected: (_) async {
                  try {
                    await widget.data.api.patchMap('/planner-entry-homeworks/${sub['tawasulPlannerEntryHomeworkID']}', {'status': e.key});
                    if (!mounted) return;
                    _toast(context, ar ? 'تم التحقق' : 'Checked');
                    _pick(_lessonId!);
                  } catch (err) {
                    if (mounted) _toast(context, _explain(err, ar));
                  }
                },
              ),
          ]),
        ],
      ]),
    );
  }
}

class _LessonPlanForm extends StatefulWidget {
  const _LessonPlanForm({required this.snapshot, required this.data});
  final ConsoleSnapshot snapshot;
  final _Data data;
  @override
  State<_LessonPlanForm> createState() => _LessonPlanFormState();
}

class _LessonPlanFormState extends State<_LessonPlanForm> {
  final _name = TextEditingController();
  final _date = TextEditingController(text: _today());
  final _start = TextEditingController(text: '08:00');
  final _end = TextEditingController(text: '08:45');
  final _goals = TextEditingController();
  final _plan = TextEditingController();
  String? _classId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    final classes = widget.snapshot.classes;
    final classId = _classId ?? (classes.isEmpty ? null : classes.first.id);
    return WhitePanel(
      title: ar ? 'إنشاء خطة الدرس' : 'Create lesson plan',
      child: classes.isEmpty
          ? EmptyState(message: ar ? 'لا توجد صفوف' : 'No classes')
          : Column(children: [
              _classPicker(classes, classId, (v) => setState(() => _classId = v), ar),
              LabeledField(label: ar ? 'عنوان الدرس' : 'Lesson title', controller: _name),
              _DateField(label: ar ? 'التاريخ' : 'Date', controller: _date),
              _TimeField(label: ar ? 'يبدأ' : 'Starts', controller: _start),
              _TimeField(label: ar ? 'ينتهي' : 'Ends', controller: _end),
              LabeledField(label: ar ? 'الأهداف' : 'Objectives', controller: _goals, maxLines: 3),
              LabeledField(label: ar ? 'خطوات الدرس والأنشطة' : 'Steps and activities', controller: _plan, maxLines: 6),
              PrimaryButton(
                label: ar ? 'حفظ الخطة' : 'Save plan',
                busy: _busy,
                onPressed: () => _save(classId!, ar),
              ),
            ]),
    );
  }

  Future<void> _save(String classId, bool ar) async {
    if (_name.text.trim().isEmpty) { _toast(context, ar ? 'العنوان مطلوب' : 'Title is required'); return; }
    setState(() => _busy = true);
    final title = _name.text.trim();
    try {
      await widget.data.api.postMap('/lessons', {
        'tawasulCourseClassID': classId,
        'date': _isoDate(_date.text),
        'timeStart': '${_start.text.trim()}:00',
        'timeEnd': '${_end.text.trim()}:00',
        'name': _name.text.trim(),
        'summary': _goals.text.trim(),
        'description': _plan.text.trim(),
        'homework': 'N',
        'viewableStudents': 'Y',
        'viewableParents': 'Y',
      });
      if (!mounted) return;
      _name.clear();
      _goals.clear();
      _plan.clear();
      _toast(context, ar ? 'حُفظت خطة الدرس' : 'Lesson plan saved');
      await _notify(context, widget.data.repo, classId, ar ? 'خطة درس جديدة: $title' : 'New lesson plan: $title', ar);
    } catch (e) {
      if (mounted) _toast(context, _explain(e, ar));
    }
    if (mounted) setState(() => _busy = false);
  }
}

class _HomeworkForm extends StatefulWidget {
  const _HomeworkForm({required this.snapshot, required this.data});
  final ConsoleSnapshot snapshot;
  final _Data data;
  @override
  State<_HomeworkForm> createState() => _HomeworkFormState();
}

class _HomeworkFormState extends State<_HomeworkForm> {
  final _details = TextEditingController();
  final _due = TextEditingController(text: _today());
  String? _lessonId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    final lessons = widget.snapshot.lessons.where((l) => l.id.isNotEmpty).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final lessonId = _lessonId ?? (lessons.isEmpty ? null : lessons.first.id);
    return WhitePanel(
      title: ar ? 'إنشاء الواجب' : 'Create homework',
      child: lessons.isEmpty
          ? EmptyState(message: ar ? 'أنشئ درسًا أولًا' : 'Create a lesson first')
          : Column(children: [
              _dropdown<String>(
                label: ar ? 'الدرس' : 'Lesson',
                value: lessonId,
                items: lessons
                    .map((l) => DropdownMenuItem(value: l.id, child: Text('${l.date} · ${l.subject} · ${l.group}')))
                    .toList(),
                onChanged: (v) => setState(() => _lessonId = v),
              ),
              LabeledField(label: ar ? 'تفاصيل الواجب' : 'Homework details', controller: _details, maxLines: 4),
              _DateField(label: ar ? 'موعد التسليم' : 'Due date', controller: _due),
              PrimaryButton(label: ar ? 'نشر الواجب' : 'Publish homework', busy: _busy, onPressed: () => _save(lessonId!, ar)),
            ]),
    );
  }

  Future<void> _save(String lessonId, bool ar) async {
    if (_details.text.trim().isEmpty || _due.text.trim().isEmpty) {
      { _toast(context, ar ? 'التفاصيل وموعد التسليم مطلوبان' : 'Details and due date are required'); return; }
    }
    setState(() => _busy = true);
    final due = _isoDate(_due.text);
    try {
      await widget.data.api.patchMap('/lessons/$lessonId', {
        'homework': 'Y',
        'homeworkDetails': _details.text.trim(),
        'homeworkDueDateTime': '${_isoDate(_due.text)} 08:00:00',
      });
      if (!mounted) return;
      _details.clear();
      _due.text = _today();
      _toast(context, ar ? 'نُشر الواجب' : 'Homework published');
      final lesson = widget.snapshot.lessons.firstWhere((l) => l.id == lessonId, orElse: () => const LessonItem(time: '', subject: '', group: ''));
      if (lesson.classId.isNotEmpty) {
        await _notify(context, widget.data.repo, lesson.classId,
            ar ? 'واجب جديد في ${lesson.subject}، التسليم $due' : 'New homework in ${lesson.subject}, due $due', ar);
      }
    } catch (e) {
      if (mounted) _toast(context, _explain(e, ar));
    }
    if (mounted) setState(() => _busy = false);
  }
}

/// One row per student: optional answer, score and comment.
class _MarkSheet extends StatefulWidget {
  const _MarkSheet({
    super.key,
    required this.students,
    required this.columnId,
    required this.data,
    this.answers = const {},
    this.maxScore = '',
  });
  final List<StudentItem> students;
  final String columnId;
  final _Data data;
  final Map<String, String> answers;
  final String maxScore;
  @override
  State<_MarkSheet> createState() => _MarkSheetState();
}

class _MarkSheetState extends State<_MarkSheet> {
  final _score = <String, TextEditingController>{};
  final _note = <String, TextEditingController>{};
  final _existing = <String, String>{};
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final s in widget.students) {
      _score[s.id] = TextEditingController();
      _note[s.id] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    try {
      for (final row in await widget.data.entries(widget.columnId)) {
        final id = '${row['tawasulPersonIDStudent'] ?? ''}';
        if (!_score.containsKey(id)) continue;
        _existing[id] = '${row['tawasulMarkbookEntryID'] ?? ''}';
        _score[id]!.text = '${row['attainmentValueRaw'] ?? row['attainmentValue'] ?? ''}';
        _note[id]!.text = '${row['comment'] ?? ''}';
      }
    } catch (e) {
      _error = _explain(e, true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    if (_loading) return Text(L10n.of(context).loading, style: const TextStyle(color: AppColors.muted));
    if (_error != null) return EmptyState(message: _error);
    if (widget.students.isEmpty) return EmptyState(message: ar ? 'لا يوجد طلاب' : 'No students');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final s in widget.students)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.pine)),
            if (widget.answers.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(AppRadii.md)),
                child: Text(widget.answers[s.id] ?? (ar ? 'لم يسلّم' : 'Not submitted')),
              ),
            Row(children: [
              SizedBox(
                width: 110,
                child: LabeledField(
                  label: widget.maxScore.isEmpty ? (ar ? 'الدرجة' : 'Score') : '${ar ? 'من' : 'of'} ${widget.maxScore}',
                  controller: _score[s.id]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: LabeledField(label: ar ? 'ملاحظة' : 'Comment', controller: _note[s.id]!)),
            ]),
          ]),
        ),
      PrimaryButton(label: ar ? 'حفظ الدرجات' : 'Save marks', busy: _busy, onPressed: () => _save(ar)),
    ]);
  }

  Future<void> _save(bool ar) async {
    setState(() => _busy = true);
    var saved = 0;
    String? failure;
    for (final s in widget.students) {
      final score = _score[s.id]!.text.trim();
      if (score.isEmpty) continue;
      try {
        await widget.data.saveMark(
          columnId: widget.columnId,
          studentId: s.id,
          score: score,
          comment: _note[s.id]!.text.trim(),
          existingId: _existing[s.id],
        );
        saved++;
      } catch (e) {
        failure = _explain(e, ar);
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(context, failure ?? (ar ? 'حُفظت $saved درجة' : 'Saved $saved marks'));
  }
}

class _GradesForm extends StatefulWidget {
  const _GradesForm({required this.snapshot, required this.data});
  final ConsoleSnapshot snapshot;
  final _Data data;
  @override
  State<_GradesForm> createState() => _GradesFormState();
}

class _GradesFormState extends State<_GradesForm> {
  String? _classId;
  String? _columnId;
  List<Map<String, dynamic>> _columns = [];
  final _newName = TextEditingController();
  final _newMax = TextEditingController(text: '100');
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final classes = widget.snapshot.classes;
    if (classes.isNotEmpty) _pickClass(classes.first.id);
  }

  Future<void> _pickClass(String? id) async {
    setState(() {
      _classId = id;
      _columnId = null;
      _columns = [];
    });
    if (id == null) return;
    try {
      final rows = await widget.data.columns(id);
      if (mounted) setState(() => _columns = rows);
    } catch (e) {
      if (mounted) _toast(context, _explain(e, L10n.of(context).isArabic));
    }
  }

  List<StudentItem> _studentsOf(String classId) {
    return widget.snapshot.students;
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    final classes = widget.snapshot.classes;
    if (classes.isEmpty) return WhitePanel(title: ar ? 'إضافة الدرجات' : 'Add grades', child: EmptyState(message: ar ? 'لا توجد صفوف' : 'No classes'));
    final column = _columns.where((c) => '${c['tawasulMarkbookColumnID']}' == _columnId).firstOrNull;
    return WhitePanel(
      title: ar ? 'إضافة الدرجات' : 'Add grades',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _classPicker(classes, _classId, _pickClass, ar),
        _dropdown<String>(
          label: ar ? 'عمود التقييم' : 'Assessment',
          value: _columnId,
          items: _columns
              .map((c) => DropdownMenuItem(value: '${c['tawasulMarkbookColumnID']}', child: Text('${c['name']} · ${c['type']}')))
              .toList(),
          onChanged: (v) => setState(() => _columnId = v),
        ),
        Text(ar ? 'أو أنشئ تقييمًا جديدًا' : 'Or create a new assessment', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 8),
        LabeledField(label: ar ? 'اسم التقييم' : 'Assessment name', controller: _newName),
        LabeledField(label: ar ? 'الدرجة العظمى' : 'Max score', controller: _newMax),
        SecondaryButton(label: ar ? 'إنشاء التقييم' : 'Create assessment', onPressed: _busy ? () {} : () => _create(ar)),
        const SizedBox(height: 16),
        if (_columnId != null)
          _MarkSheet(
            key: ValueKey(_columnId),
            students: _studentsOf(_classId!),
            columnId: _columnId!,
            data: widget.data,
            maxScore: '${column?['attainmentRawMax'] ?? ''}',
          ),
      ]),
    );
  }

  Future<void> _create(bool ar) async {
    if (_classId == null || _newName.text.trim().isEmpty) { _toast(context, ar ? 'الاسم مطلوب' : 'Name is required'); return; }
    setState(() => _busy = true);
    try {
      final body = await widget.data.api.postMap('/markbook-columns', {
        'tawasulCourseClassID': _classId,
        'type': 'Assessment',
        'name': _newName.text.trim(),
        'date': _today(),
        'attainment': 'Y',
        'attainmentRawMax': _newMax.text.trim(),
        'effort': 'N',
        'comment': 'Y',
        'complete': 'N',
        'viewableStudents': 'Y',
        'viewableParents': 'Y',
      });
      _newName.clear();
      await _pickClass(_classId);
      final id = _idOf(body, ['tawasulMarkbookColumnID']);
      if (mounted && id.isNotEmpty) setState(() => _columnId = id);
    } catch (e) {
      if (mounted) _toast(context, _explain(e, ar));
    }
    if (mounted) setState(() => _busy = false);
  }
}

class _TestForm extends StatefulWidget {
  const _TestForm({required this.snapshot, required this.data});
  final ConsoleSnapshot snapshot;
  final _Data data;
  @override
  State<_TestForm> createState() => _TestFormState();
}

class _TestFormState extends State<_TestForm> {
  final _name = TextEditingController();
  final _date = TextEditingController(text: _today());
  final _minutes = TextEditingController(text: '30');
  final _max = TextEditingController(text: '100');
  final _questions = <TextEditingController>[TextEditingController()];
  String? _classId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    final classes = widget.snapshot.classes;
    final classId = _classId ?? (classes.isEmpty ? null : classes.first.id);
    return WhitePanel(
      title: ar ? 'إضافة اختبار' : 'New test',
      child: classes.isEmpty
          ? EmptyState(message: ar ? 'لا توجد صفوف' : 'No classes')
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _classPicker(classes, classId, (v) => setState(() => _classId = v), ar),
              LabeledField(label: ar ? 'اسم الاختبار' : 'Test name', controller: _name),
              _DateField(label: ar ? 'التاريخ' : 'Date', controller: _date),
              LabeledField(label: ar ? 'المدة بالدقائق' : 'Duration (minutes)', controller: _minutes),
              LabeledField(label: ar ? 'الدرجة العظمى' : 'Max score', controller: _max),
              for (var i = 0; i < _questions.length; i++)
                LabeledField(label: '${ar ? 'السؤال' : 'Question'} ${i + 1}', controller: _questions[i], maxLines: 2),
              SecondaryButton(
                label: ar ? 'إضافة سؤال' : 'Add question',
                onPressed: () => setState(() => _questions.add(TextEditingController())),
              ),
              const SizedBox(height: 10),
              PrimaryButton(label: ar ? 'نشر الاختبار' : 'Publish test', busy: _busy, onPressed: () => _save(classId!, ar)),
            ]),
    );
  }

  Future<void> _save(String classId, bool ar) async {
    final questions = _questions.map((c) => c.text.trim()).where((q) => q.isNotEmpty).toList();
    if (_name.text.trim().isEmpty || questions.isEmpty) {
      { _toast(context, ar ? 'الاسم وسؤال واحد على الأقل مطلوبان' : 'A name and at least one question are required'); return; }
    }
    setState(() => _busy = true);
    final date = _isoDate(_date.text);
    try {
      final lesson = await widget.data.api.postMap('/lessons', {
        'tawasulCourseClassID': classId,
        'date': date,
        'timeStart': '08:00:00',
        'timeEnd': '08:45:00',
        'name': '${ar ? 'اختبار' : 'Test'}: ${_name.text.trim()}',
        'summary': _name.text.trim(),
        'homework': 'Y',
        'homeworkDetails': questions.join('\n'),
        'homeworkDueDateTime': '$date 23:59:00',
        'viewableStudents': 'Y',
        'viewableParents': 'N',
      });
      final lessonId = _idOf(lesson, ['tawasulPlannerEntryID']);
      await widget.data.api.postMap('/markbook-columns', {
        'tawasulCourseClassID': classId,
        if (lessonId.isNotEmpty) 'tawasulPlannerEntryID': lessonId,
        'type': 'Test',
        'name': _name.text.trim(),
        'description': jsonEncode({'tawasulTest': 1, 'minutes': int.tryParse(_minutes.text.trim()) ?? 30, 'questions': questions}),
        'date': date,
        'attainment': 'Y',
        'attainmentRawMax': _max.text.trim(),
        'effort': 'N',
        'comment': 'Y',
        'complete': 'N',
        'viewableStudents': 'Y',
        'viewableParents': 'Y',
      });
      if (!mounted) return;
      _name.clear();
      setState(() => _questions
        ..clear()
        ..add(TextEditingController()));
      _toast(context, ar ? 'نُشر الاختبار' : 'Test published');
    } catch (e) {
      if (mounted) _toast(context, _explain(e, ar));
    }
    if (mounted) setState(() => _busy = false);
  }
}

class _TestPicker extends StatelessWidget {
  const _TestPicker({required this.future, required this.builder});
  final Future<List<TestInfo>> future;
  final Widget Function(List<TestInfo> tests) builder;
  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    return FutureBuilder<List<TestInfo>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(padding: const EdgeInsets.all(16), child: Text(L10n.of(context).loading));
        }
        if (snap.hasError) return EmptyState(message: _explain(snap.error!, ar));
        final tests = snap.data ?? const [];
        if (tests.isEmpty) return EmptyState(message: ar ? 'لا توجد اختبارات' : 'No tests yet');
        return builder(tests);
      },
    );
  }
}

class _TestGrader extends StatefulWidget {
  const _TestGrader({required this.snapshot, required this.data});
  final ConsoleSnapshot snapshot;
  final _Data data;
  @override
  State<_TestGrader> createState() => _TestGraderState();
}

class _TestGraderState extends State<_TestGrader> {
  late final Future<List<TestInfo>> _tests = widget.data.tests(widget.snapshot.classes.map((c) => c.id));
  TestInfo? _test;
  Future<Map<String, String>>? _answers;

  Future<Map<String, String>> _loadAnswers(TestInfo t) async {
    if (t.lessonId.isEmpty) return {};
    final rows = await widget.data.submissions(t.lessonId);
    return {for (final r in rows) '${r['tawasulPersonID']}': '${r['location'] ?? ''}'};
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    return WhitePanel(
      title: ar ? 'تصحيح الاختبار' : 'Mark test',
      child: _TestPicker(
        future: _tests,
        builder: (tests) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _dropdown<String>(
            label: ar ? 'الاختبار' : 'Test',
            value: _test?.columnId,
            items: tests.map((t) => DropdownMenuItem(value: t.columnId, child: Text('${t.date} · ${t.name}'))).toList(),
            onChanged: (v) => setState(() {
              _test = tests.firstWhere((t) => t.columnId == v);
              _answers = _loadAnswers(_test!);
            }),
          ),
          if (_test != null) ...[
            for (var i = 0; i < _test!.questions.length; i++)
              Text('${i + 1}. ${_test!.questions[i]}', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, String>>(
              future: _answers,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return Text(L10n.of(context).loading);
                if (snap.hasError) return EmptyState(message: _explain(snap.error!, ar));
                return _MarkSheet(
                  key: ValueKey(_test!.columnId),
                  students: widget.snapshot.students,
                  columnId: _test!.columnId,
                  data: widget.data,
                  answers: snap.data ?? const {},
                  maxScore: _test!.maxScore,
                );
              },
            ),
          ],
        ]),
      ),
    );
  }
}

class _TeacherResults extends StatefulWidget {
  const _TeacherResults({required this.snapshot, required this.data});
  final ConsoleSnapshot snapshot;
  final _Data data;
  @override
  State<_TeacherResults> createState() => _TeacherResultsState();
}

class _TeacherResultsState extends State<_TeacherResults> {
  late final Future<List<(TestInfo, List<double>)>> _future = _load();

  Future<List<(TestInfo, List<double>)>> _load() async {
    final tests = await widget.data.tests(widget.snapshot.classes.map((c) => c.id));
    final out = <(TestInfo, List<double>)>[];
    for (final t in tests) {
      final scores = (await widget.data.entries(t.columnId))
          .map((r) => double.tryParse('${r['attainmentValueRaw'] ?? r['attainmentValue'] ?? ''}'))
          .whereType<double>()
          .toList();
      out.add((t, scores));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    final classNames = {for (final c in widget.snapshot.classes) c.id: c.name};
    return WhitePanel(
      title: ar ? 'الاختبارات ونتائجها' : 'Tests and results',
      child: FutureBuilder<List<(TestInfo, List<double>)>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return Text(L10n.of(context).loading);
          if (snap.hasError) return EmptyState(message: _explain(snap.error!, ar));
          final rows = snap.data ?? const [];
          if (rows.isEmpty) return EmptyState(message: ar ? 'لا توجد اختبارات' : 'No tests yet');
          return Column(
            children: rows.map((row) {
              final (t, scores) = row;
              final avg = scores.isEmpty ? '—' : (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1);
              return RowTile(
                leading: t.name.isEmpty ? '—' : t.name.substring(0, 1),
                title: t.name,
                subtitle: '${classNames[t.classId] ?? ''} · ${t.date} · ${ar ? 'مصحح' : 'marked'} ${scores.length}',
                trailing: '${ar ? 'المتوسط' : 'Avg'} $avg${t.maxScore.isEmpty ? '' : '/${t.maxScore}'}',
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ================================================================ student ===

Set<String> _studentClassIds(ConsoleSnapshot s) =>
    {...s.classes.map((c) => c.id), ...s.lessons.map((l) => l.classId)}..removeWhere((id) => id.isEmpty);

Widget studentLearningHub({required ConsoleSnapshot snapshot, required ConsoleRepository repository, required AuthUser user}) {
  final data = _Data(repository);
  return _Hub(sections: [
    _Section('بدء الاختبار', 'Start test', () => _StudentTests(snapshot: snapshot, data: data, user: user)),
    _Section('نتائج الاختبارات', 'Test results', () => _StudentResults(snapshot: snapshot, data: data, user: user)),
  ]);
}

class _HomeworkSubmit extends StatefulWidget {
  const _HomeworkSubmit({required this.snapshot, required this.data, required this.user});
  final ConsoleSnapshot snapshot;
  final _Data data;
  final AuthUser user;
  @override
  State<_HomeworkSubmit> createState() => _HomeworkSubmitState();
}

class _HomeworkSubmitState extends State<_HomeworkSubmit> {
  late Future<List<(Map<String, dynamic>, bool)>> _future = _load();
  final _answer = <String, TextEditingController>{};

  Future<List<(Map<String, dynamic>, bool)>> _load() async {
    final testLessons = (await widget.data.tests(_studentClassIds(widget.snapshot))).map((t) => t.lessonId).toSet();
    final out = <(Map<String, dynamic>, bool)>[];
    for (final id in _studentClassIds(widget.snapshot)) {
      final rows = await widget.data.repo.fetchRecords('/lessons', query: {'tawasulCourseClassID': id, 'homework': 'Y'});
      for (final r in rows) {
        final lessonId = '${r['tawasulPlannerEntryID']}';
        if (r['homework'] != 'Y' || testLessons.contains(lessonId)) continue;
        final done = (await widget.data.submissions(lessonId, personId: widget.user.personId)).isNotEmpty;
        out.add((r, done));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    return WhitePanel(
      title: ar ? 'الواجبات' : 'Homework',
      child: FutureBuilder<List<(Map<String, dynamic>, bool)>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return Text(L10n.of(context).loading);
          if (snap.hasError) return EmptyState(message: _explain(snap.error!, ar));
          final rows = snap.data ?? const [];
          if (rows.isEmpty) return EmptyState(message: ar ? 'لا توجد واجبات' : 'No homework');
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final (r, done) in rows) _item(r, done, ar),
          ]);
        },
      ),
    );
  }

  Widget _item(Map<String, dynamic> r, bool done, bool ar) {
    final id = '${r['tawasulPlannerEntryID']}';
    final due = '${r['homeworkDueDateTime'] ?? ''}'.split(' ').first;
    return InkWell(
      onTap: () => _open(r, done, ar),
      child: RowTile(
        leading: '${r['name'] ?? ''}'.isEmpty ? '—' : '${r['name']}'.substring(0, 1),
        title: '${r['name'] ?? ''}',
        subtitle: '${r['className'] ?? ''} · ${ar ? 'التسليم' : 'Due'} $due',
        trailing: done ? (ar ? 'تم التسليم' : 'Submitted') : (ar ? 'مفتوح' : 'Open'),
        trailingColor: done ? AppColors.green : AppColors.pine,
        key: ValueKey(id),
      ),
    );
  }

  Future<void> _open(Map<String, dynamic> r, bool done, bool ar) async {
    final id = '${r['tawasulPlannerEntryID']}';
    final c = _answer.putIfAbsent(id, TextEditingController.new);
    var busy = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: L10n.of(context).direction,
        child: StatefulBuilder(
          builder: (dialogContext, setDialog) => AlertDialog(
            title: Text('${r['name'] ?? ''}'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${r['className'] ?? ''}', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 8),
                Text('${r['homeworkDetails'] ?? ''}'),
                const SizedBox(height: 8),
                Text('${ar ? 'التسليم قبل' : 'Due'} ${r['homeworkDueDateTime'] ?? ''}', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                if (done)
                  StatusPill(label: ar ? 'تم التسليم' : 'Submitted', color: AppColors.green)
                else ...[
                  LabeledField(label: ar ? 'إجابتك أو رابط الملف' : 'Your answer or a file link', controller: c, maxLines: 3),
                  PrimaryButton(
                    label: ar ? 'تسليم الواجب' : 'Submit homework',
                    busy: busy,
                    onPressed: () async {
                      if (c.text.trim().isEmpty) return;
                      setDialog(() => busy = true);
                      try {
                        await widget.data.submit(id, widget.user.personId, c.text.trim());
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                        if (!mounted) return;
                        _toast(context, ar ? 'تم التسليم' : 'Submitted');
                        setState(() => _future = _load());
                      } catch (e) {
                        setDialog(() => busy = false);
                        if (mounted) _toast(context, _explain(e, ar));
                      }
                    },
                  ),
                ],
              ]),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(ar ? 'إغلاق' : 'Close'))],
          ),
        ),
      ),
    );
  }
}

class _StudentTests extends StatefulWidget {
  const _StudentTests({required this.snapshot, required this.data, required this.user});
  final ConsoleSnapshot snapshot;
  final _Data data;
  final AuthUser user;
  @override
  State<_StudentTests> createState() => _StudentTestsState();
}

class _StudentTestsState extends State<_StudentTests> {
  late Future<List<(TestInfo, bool)>> _future = _load();
  TestInfo? _active;

  Future<List<(TestInfo, bool)>> _load() async {
    final out = <(TestInfo, bool)>[];
    for (final t in await widget.data.tests(_studentClassIds(widget.snapshot))) {
      final done = t.lessonId.isEmpty ||
          (await widget.data.submissions(t.lessonId, personId: widget.user.personId)).isNotEmpty;
      out.add((t, done));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    if (_active != null) {
      return _TestRunner(
        test: _active!,
        onSubmit: (answers) async {
          await widget.data.submit(_active!.lessonId, widget.user.personId, answers);
        },
        onClose: () => setState(() {
          _active = null;
          _future = _load();
        }),
      );
    }
    return WhitePanel(
      title: ar ? 'الاختبارات' : 'Tests',
      child: FutureBuilder<List<(TestInfo, bool)>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return Text(L10n.of(context).loading);
          if (snap.hasError) return EmptyState(message: _explain(snap.error!, ar));
          final rows = snap.data ?? const [];
          if (rows.isEmpty) return EmptyState(message: ar ? 'لا توجد اختبارات' : 'No tests');
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final (t, done) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  RowTile(
                    leading: t.name.isEmpty ? '—' : t.name.substring(0, 1),
                    title: t.name,
                    subtitle: '${t.date} · ${t.minutes} ${ar ? 'دقيقة' : 'min'} · ${t.questions.length} ${ar ? 'أسئلة' : 'questions'}',
                    trailing: done ? (ar ? 'مُسلَّم' : 'Done') : '',
                  ),
                  if (!done)
                    PrimaryButton(label: ar ? 'بدء الاختبار' : 'Start test', onPressed: () => setState(() => _active = t)),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}

class _TestRunner extends StatefulWidget {
  const _TestRunner({required this.test, required this.onSubmit, required this.onClose});
  final TestInfo test;
  final Future<void> Function(String answers) onSubmit;
  final VoidCallback onClose;
  @override
  State<_TestRunner> createState() => _TestRunnerState();
}

class _TestRunnerState extends State<_TestRunner> {
  late final List<TextEditingController> _answers =
      List.generate(widget.test.questions.length, (_) => TextEditingController());
  late int _left = widget.test.minutes * 60;
  Timer? _timer;
  bool _sent = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) _submit(auto: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submit({bool auto = false}) async {
    if (_sent || _busy) return;
    _timer?.cancel();
    setState(() => _busy = true);
    final ar = L10n.of(context).isArabic;
    final text = [for (var i = 0; i < _answers.length; i++) '${i + 1}) ${_answers[i].text.trim()}'].join(' | ');
    try {
      await widget.onSubmit(text);
      if (!mounted) return;
      setState(() => _sent = true);
      _toast(context, auto ? (ar ? 'انتهى الوقت وسُلّم الاختبار' : 'Time is up, test submitted') : (ar ? 'سُلّم الاختبار' : 'Test submitted'));
      widget.onClose();
    } catch (e) {
      if (mounted) _toast(context, _explain(e, ar));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    final m = (_left.clamp(0, 1 << 30) ~/ 60).toString().padLeft(2, '0');
    final s = (_left.clamp(0, 1 << 30) % 60).toString().padLeft(2, '0');
    return WhitePanel(
      title: widget.test.name,
      trailing: Text('$m:$s', style: TextStyle(fontWeight: FontWeight.w900, color: _left < 60 ? AppColors.red : AppColors.pine)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(ar ? 'يمكن التسليم مرة واحدة فقط، ويُسلَّم تلقائيًا عند انتهاء الوقت.' : 'One submission only; it is sent automatically when time runs out.',
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),
        for (var i = 0; i < widget.test.questions.length; i++)
          LabeledField(label: '${i + 1}. ${widget.test.questions[i]}', controller: _answers[i], maxLines: 3),
        PrimaryButton(label: ar ? 'تسليم الاختبار' : 'Submit test', busy: _busy, onPressed: _submit),
      ]),
    );
  }
}

class _StudentResults extends StatelessWidget {
  const _StudentResults({required this.snapshot, required this.data, required this.user});
  final ConsoleSnapshot snapshot;
  final _Data data;
  final AuthUser user;

  Future<List<(TestInfo, Map<String, dynamic>?)>> _load() async {
    final tests = await data.tests(_studentClassIds(snapshot));
    final mine = await data.repo.fetchRecords('/markbook-entries', query: {'tawasulPersonIDStudent': user.personId});
    final byColumn = {for (final r in mine) '${r['tawasulMarkbookColumnID']}': r};
    return [for (final t in tests) (t, byColumn[t.columnId])];
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    return WhitePanel(
      title: ar ? 'نتائج الاختبارات' : 'Test results',
      child: FutureBuilder<List<(TestInfo, Map<String, dynamic>?)>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return Text(L10n.of(context).loading);
          if (snap.hasError) return EmptyState(message: _explain(snap.error!, ar));
          final rows = snap.data ?? const [];
          if (rows.isEmpty) return EmptyState(message: ar ? 'لا توجد اختبارات' : 'No tests');
          return Column(children: [
            for (final (t, e) in rows)
              RowTile(
                leading: t.name.isEmpty ? '—' : t.name.substring(0, 1),
                title: t.name,
                subtitle: [t.date, '${e?['comment'] ?? ''}'].where((p) => p.isNotEmpty).join(' · '),
                trailing: e == null
                    ? (ar ? 'لم يُصحَّح' : 'Not marked')
                    : '${e['attainmentValueRaw'] ?? e['attainmentValue'] ?? ''}${t.maxScore.isEmpty ? '' : '/${t.maxScore}'}',
              ),
          ]);
        },
      ),
    );
  }
}


/// Student homework page: tap a homework to open it in a pop-up with a submit button.
Widget studentHomeworkPage({required ConsoleSnapshot snapshot, required ConsoleRepository repository, required AuthUser user}) =>
    _HomeworkSubmit(snapshot: snapshot, data: _Data(repository), user: user);

/// Homework due today for the student dashboard.
class TodayHomeworkPanel extends StatelessWidget {
  const TodayHomeworkPanel({super.key, required this.snapshot});
  final ConsoleSnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    final today = _today();
    final items = snapshot.homework.where((h) => h.dueDate == today).toList();
    return WhitePanel(
      title: ar ? 'واجب اليوم' : "Today's homework",
      child: items.isEmpty ? EmptyState(message: ar ? 'لا يوجد واجب مستحق اليوم' : 'Nothing due today') : HomeworkList(items: items),
    );
  }
}
