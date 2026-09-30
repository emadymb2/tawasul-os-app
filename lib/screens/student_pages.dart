import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';
import '../core/session.dart';
import '../data/console_repository.dart';
import 'calendar_pages.dart';
import 'chat_pages.dart';
import 'learning_pages.dart';

Widget studentContent({
  required int index,
  required ConsoleSnapshot snapshot,
  required ConsoleRepository repository,
  required AuthUser user,
}) {
  switch (index) {
    case 1:
      return SchoolMonthCalendar(repository: repository);
    case 2:
      return studentHomeworkPage(snapshot: snapshot, repository: repository, user: user);
    case 3:
      return StudentAttendance(snapshot: snapshot);
    case 4:
      return StudentGrades(snapshot: snapshot);
    case 5:
      return StudentBehaviour(snapshot: snapshot);
    case 6:
      return StudentMessages(snapshot: snapshot);
    case 8:
      return ChatListScreen(repository: repository, user: user);
    default:
      return StudentDashboard(snapshot: snapshot);
  }
}

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final today = DateTime.now().toIso8601String().split('T').first;
    final todaysLessons = snapshot.lessons.where((lesson) => lesson.date == today).toList();
    return Column(
      children: [
        HeroPanel(greeting: strings.welcome, name: snapshot.personName, subtitle: strings.studentPortal),
        MetricGrid(metrics: [
          MetricTileData(title: strings.lessonsToday, value: '${todaysLessons.length}', tone: TileTone.mint),
          MetricTileData(title: strings.homeworkDue, value: '${snapshot.homework.length}', tone: TileTone.sage),
          MetricTileData(title: strings.classes, value: '${snapshot.classes.length}', tone: TileTone.green),
          MetricTileData(
            title: strings.attendanceRate,
            value: snapshot.attendanceRate.isEmpty ? '—' : snapshot.attendanceRate,
            tone: TileTone.gold,
          ),
        ]),
        TodayHomeworkPanel(snapshot: snapshot),
        WhitePanel(
          title: strings.todaysLessons,
          child: LessonList(lessons: todaysLessons.isEmpty ? snapshot.lessons.take(5).toList() : todaysLessons),
        ),
        WhitePanel(title: strings.notices, child: NoticeList(notices: snapshot.notices)),
      ],
    );
  }
}

class StudentTimetable extends StatelessWidget {
  const StudentTimetable({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final byDate = <String, List<LessonItem>>{};
    for (final lesson in snapshot.lessons) {
      byDate.putIfAbsent(lesson.date, () => []).add(lesson);
    }
    final dates = byDate.keys.toList()..sort();
    return Column(
      children: [
        WhitePanel(
          title: strings.classes,
          child: snapshot.classes.isEmpty
              ? const EmptyState()
              : Column(
                  children: snapshot.classes
                      .map((item) => RowTile(
                            leading: item.name.isEmpty ? '—' : item.name.substring(0, 1),
                            title: item.name,
                            subtitle: item.courseName,
                          ))
                      .toList(),
                ),
        ),
        if (dates.isEmpty)
          WhitePanel(title: strings.lessons, child: const EmptyState())
        else
          ...dates.map((date) => WhitePanel(title: date, child: LessonList(lessons: byDate[date]!))),
      ],
    );
  }
}

class StudentHomework extends StatelessWidget {
  const StudentHomework({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return WhitePanel(title: strings.homework, child: HomeworkList(items: snapshot.homework));
  }
}

class StudentAttendance extends StatelessWidget {
  const StudentAttendance({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Column(
      children: [
        MetricGrid(metrics: [
          MetricTileData(
            title: strings.attendanceRate,
            value: snapshot.attendanceRate.isEmpty ? '—' : snapshot.attendanceRate,
            tone: TileTone.green,
          ),
          MetricTileData(title: strings.attendance, value: '${snapshot.attendance.length}', tone: TileTone.mint),
        ]),
        WhitePanel(title: strings.attendance, child: AttendanceList(records: snapshot.attendance)),
      ],
    );
  }
}

class StudentGrades extends StatelessWidget {
  const StudentGrades({super.key, required this.snapshot});

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

class StudentBehaviour extends StatelessWidget {
  const StudentBehaviour({super.key, required this.snapshot});

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

class StudentMessages extends StatelessWidget {
  const StudentMessages({super.key, required this.snapshot});

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
