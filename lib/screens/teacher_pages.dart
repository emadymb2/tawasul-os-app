import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';
import 'chat_pages.dart';
import 'teacher_more_pages.dart';
import 'calendar_pages.dart';
import 'learning_pages.dart';
import 'dart:async';

String todayIso() => DateTime.now().toIso8601String().split('T').first;

Widget teacherContent({
  required int index,
  required ConsoleSnapshot snapshot,
  required AuthUser user,
  required ConsoleRepository repository,
  required Future<void> Function() onChanged,
  void Function(int page, int section)? onOpen,
  int section = 0,
}) {
  switch (index) {
    case 1:
      return SchoolDaysList(repository: repository);
    case 2:
      return TeacherAttendance(snapshot: snapshot, user: user, repository: repository, onSaved: onChanged);
    case 3:
      return teacherLessonsHub(
        snapshot: snapshot,
        repository: repository,
        initial: section,
        summaryForm: TeacherLessonForm(snapshot: snapshot, repository: repository, onSaved: onChanged),
      );
    case 4:
      return TeacherStudents(snapshot: snapshot);
    case 5:
      return TeacherGrades(snapshot: snapshot);
    case 6:
      return TeacherBehaviour(snapshot: snapshot);
    case 7:
      return TeacherMessages(snapshot: snapshot);
    case 8:
      return ChatListScreen(repository: repository, user: user);
    case 10:
      return TeacherMore(repository: repository);
    default:
      return TeacherDashboard(snapshot: snapshot, repository: repository, onOpen: onOpen ?? (_, __) {});
  }
}

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key, required this.snapshot, required this.repository, required this.onOpen});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final void Function(int page, int section) onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final today = todayIso();
    final todaysLessons = snapshot.lessons.where((lesson) => lesson.date == today).toList();
    final ar = strings.isArabic;
    return Column(
      children: [
        MessageTicker(messages: snapshot.messages),
        HeroPanel(greeting: strings.welcome, name: snapshot.personName, subtitle: strings.teacherPortal),
        WhitePanel(
          title: ar ? 'اختصارات سريعة' : 'Quick actions',
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _Shortcut(Icons.event_note_outlined, ar ? 'إضافة خطة الدرس' : 'Add lesson plan', () => onOpen(3, 0)),
              _Shortcut(Icons.assignment_outlined, ar ? 'إضافة واجب' : 'Add homework', () => onOpen(3, 2)),
              _Shortcut(Icons.edit_note_outlined, ar ? 'إضافة ملخص الدرس' : 'Add lesson summary', () => onOpen(3, 1)),
              _Shortcut(Icons.move_to_inbox_outlined, ar ? 'استلام الواجب' : 'Receive homework', () => onOpen(3, 3)),
            ],
          ),
        ),
        HomeworkStatsTable(snapshot: snapshot, repository: repository),
        MetricGrid(metrics: [
          MetricTileData(title: strings.lessonsToday, value: '${todaysLessons.length}', tone: TileTone.mint),
          MetricTileData(title: strings.classes, value: '${snapshot.classes.length}', tone: TileTone.sage),
          MetricTileData(title: strings.studentsCount, value: '${snapshot.students.length}', tone: TileTone.green),
          MetricTileData(
            title: strings.attendanceRate,
            value: snapshot.attendanceRate.isEmpty ? '—' : snapshot.attendanceRate,
            tone: TileTone.gold,
          ),
        ]),
        WhitePanel(
          title: strings.todaysLessons,
          child: LessonList(lessons: todaysLessons.isEmpty ? snapshot.lessons.take(5).toList() : todaysLessons),
        ),
        WhitePanel(title: strings.notices, child: NoticeList(notices: snapshot.notices)),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(children: [
            Icon(icon, color: AppColors.pine, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.pine, fontWeight: FontWeight.w800, fontSize: 13))),
          ]),
        ),
      ),
    );
  }
}

/// News-ticker strip of the latest messages, rotating every few seconds.
class MessageTicker extends StatefulWidget {
  const MessageTicker({super.key, required this.messages});
  final List<MessageItem> messages;
  @override
  State<MessageTicker> createState() => _MessageTickerState();
}

class _MessageTickerState extends State<MessageTicker> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && widget.messages.length > 1) setState(() => _i = (_i + 1) % widget.messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = L10n.of(context).isArabic;
    final m = widget.messages.isEmpty ? null : widget.messages[_i % widget.messages.length];
    final text = m == null
        ? (ar ? 'لا توجد رسائل جديدة' : 'No new messages')
        : [m.sender, m.title.isEmpty ? m.body : m.title].where((p) => p.isNotEmpty).join(': ');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.pine, borderRadius: BorderRadius.circular(AppRadii.md)),
      child: Row(children: [
        const Icon(Icons.campaign_outlined, color: AppColors.gold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(text, key: ValueKey(_i), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.cream, fontWeight: FontWeight.w700)),
          ),
        ),
        if (widget.messages.length > 1)
          Text('${_i + 1}/${widget.messages.length}', style: const TextStyle(color: AppColors.mintText, fontSize: 11)),
      ]),
    );
  }
}

class TeacherTimetable extends StatelessWidget {
  const TeacherTimetable({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final byDate = <String, List<LessonItem>>{};
    for (final lesson in snapshot.lessons) {
      byDate.putIfAbsent(lesson.date, () => []).add(lesson);
    }
    final dates = byDate.keys.toList()..sort();
    if (dates.isEmpty) {
      return WhitePanel(title: strings.timetable, child: const EmptyState());
    }
    return Column(
      children: dates
          .map((date) => WhitePanel(title: date, child: LessonList(lessons: byDate[date]!)))
          .toList(),
    );
  }
}

class TeacherStudents extends StatelessWidget {
  const TeacherStudents({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Column(
      children: [
        WhitePanel(
          title: strings.classes,
          child: snapshot.classes.isEmpty
              ? EmptyState(message: strings.noClasses)
              : Column(
                  children: snapshot.classes
                      .map((item) => RowTile(
                            leading: item.courseName.isEmpty ? '—' : item.courseName.substring(0, 1),
                            title: item.name,
                            subtitle: item.courseName,
                            trailing: item.studentCount == 0 ? '' : '${item.studentCount}',
                          ))
                      .toList(),
                ),
        ),
        WhitePanel(title: strings.classRoster, child: StudentList(students: snapshot.students)),
      ],
    );
  }
}

class TeacherAttendance extends StatefulWidget {
  const TeacherAttendance({
    super.key,
    required this.snapshot,
    required this.user,
    required this.repository,
    required this.onSaved,
  });

  final ConsoleSnapshot snapshot;
  final AuthUser user;
  final ConsoleRepository repository;
  final Future<void> Function() onSaved;

  @override
  State<TeacherAttendance> createState() => _TeacherAttendanceState();
}

class _TeacherAttendanceState extends State<TeacherAttendance> {
  String? _classId;
  final Map<String, String> _status = {};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final classes = widget.snapshot.classes;
    final classId = _classId ?? (classes.isEmpty ? null : classes.first.id);
    final roster = widget.snapshot.students.where((student) {
      if (classId == null) return false;
      final match = classes.firstWhere((item) => item.id == classId, orElse: () => const ClassItem(id: '', name: ''));
      return student.group == match.name;
    }).toList();

    return Column(
      children: [
        WhitePanel(
          title: strings.attendance,
          child: classes.isEmpty
              ? EmptyState(message: strings.noClasses)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: classId,
                      decoration: InputDecoration(
                        labelText: strings.theClass,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                      items: classes
                          .map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _classId = value;
                        _status.clear();
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text('${strings.date}: ${todayIso()}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 12),
                    if (roster.isEmpty)
                      const EmptyState()
                    else
                      ...roster.map((student) => _StudentAttendanceRow(
                            student: student,
                            value: _status[student.id] ?? 'Present',
                            onChanged: (value) => setState(() => _status[student.id] = value),
                          )),
                    if (roster.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: strings.saveAttendance,
                        busy: _busy,
                        onPressed: () => _save(classId!, roster, strings),
                      ),
                    ],
                  ],
                ),
        ),
        WhitePanel(
          title: strings.attendance,
          child: AttendanceList(records: widget.snapshot.attendance.take(20).toList(), showName: true),
        ),
      ],
    );
  }

  Future<void> _save(String classId, List<StudentItem> roster, L10n strings) async {
    setState(() => _busy = true);
    final marks = {for (final student in roster) student.id: _status[student.id] ?? 'Present'};
    final sent = await widget.repository.saveAttendance(
      classId: classId,
      date: todayIso(),
      statusByStudentId: marks,
      takerId: widget.user.personId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sent ? strings.saved : strings.savedOffline)),
    );
    await widget.onSaved();
  }
}

class _StudentAttendanceRow extends StatelessWidget {
  const _StudentAttendanceRow({required this.student, required this.value, required this.onChanged});

  final StudentItem student;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final options = {'Present': strings.present, 'Late': strings.lateLabel, 'Absent': strings.absent};
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student.name, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: options.entries
                .map((entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: value == entry.key,
                      selectedColor: AppColors.mint,
                      onSelected: (_) => onChanged(entry.key),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class TeacherLessonForm extends StatefulWidget {
  const TeacherLessonForm({super.key, required this.snapshot, required this.repository, required this.onSaved});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final Future<void> Function() onSaved;

  @override
  State<TeacherLessonForm> createState() => _TeacherLessonFormState();
}

class _TeacherLessonFormState extends State<TeacherLessonForm> {
  final _title = TextEditingController();
  final _summary = TextEditingController();
  String? _classId;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final classes = widget.snapshot.classes;
    final classId = _classId ?? (classes.isEmpty ? null : classes.first.id);

    return WhitePanel(
      title: strings.lessonSummary,
      child: classes.isEmpty
          ? EmptyState(message: strings.noClasses)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: classId,
                  decoration: InputDecoration(
                    labelText: strings.theClass,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  ),
                  items: classes.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                  onChanged: (value) => setState(() => _classId = value),
                ),
                const SizedBox(height: 14),
                LabeledField(label: strings.title, controller: _title),
                LabeledField(label: strings.summary, controller: _summary, maxLines: 4),
                PrimaryButton(
                  label: strings.publishSummary,
                  busy: _busy,
                  onPressed: () => _publish(classId!, strings),
                ),
              ],
            ),
    );
  }

  Future<void> _publish(String classId, L10n strings) async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.titleRequired)));
      return;
    }
    setState(() => _busy = true);
    final sent = await widget.repository.publishLesson(
      classId: classId,
      date: todayIso(),
      timeStart: '08:00:00',
      timeEnd: '08:45:00',
      name: _title.text.trim(),
      summary: _summary.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    final lessonTitle = _title.text.trim();
    _title.clear();
    _summary.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sent ? strings.saved : strings.savedOffline)),
    );
    if (sent) {
      final n = await widget.repository.notifyClass(
          classId, strings.isArabic ? 'ملخص درس جديد: $lessonTitle' : 'New lesson summary: $lessonTitle');
      if (mounted && n > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(strings.isArabic ? 'أُرسل إشعار إلى $n من المشاركين وأولياء الأمور' : 'Notified $n people')));
      }
    }
    await widget.onSaved();
  }
}

class TeacherGrades extends StatelessWidget {
  const TeacherGrades({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return WhitePanel(
      title: strings.grades,
      child: snapshot.grades.isEmpty
          ? EmptyState(message: strings.noGrades)
          : Column(
              children: snapshot.grades
                  .map((grade) => RowTile(
                        leading: grade.subject.isEmpty ? '—' : grade.subject.substring(0, 1),
                        title: grade.subject,
                        subtitle: grade.value,
                        trailing: grade.grade,
                      ))
                  .toList(),
            ),
    );
  }
}

class TeacherBehaviour extends StatelessWidget {
  const TeacherBehaviour({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return WhitePanel(
      title: strings.behaviour,
      child: snapshot.behaviour.isEmpty
          ? EmptyState(message: strings.noBehaviour)
          : Column(
              children: snapshot.behaviour
                  .map((item) => RowTile(
                        leading: item.date.length >= 10 ? item.date.substring(8, 10) : '—',
                        title: item.title,
                        subtitle: [item.date, item.note].where((part) => part.isNotEmpty).join(' · '),
                        trailing: item.positive ? '+' : '−',
                        trailingColor: item.positive ? AppColors.green : AppColors.red,
                      ))
                  .toList(),
            ),
    );
  }
}

class TeacherMessages extends StatelessWidget {
  const TeacherMessages({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return WhitePanel(
      title: strings.messages,
      child: snapshot.messages.isEmpty
          ? EmptyState(message: strings.noMessages)
          : Column(
              children: snapshot.messages
                  .map((message) => RowTile(
                        leading: message.sender.isEmpty ? '—' : message.sender.substring(0, 1),
                        title: message.title.isEmpty ? message.body : message.title,
                        subtitle: [message.sender, message.date].where((part) => part.isNotEmpty).join(' · '),
                      ))
                  .toList(),
            ),
    );
  }
}
