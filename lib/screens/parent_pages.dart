import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';
import 'chat_pages.dart';
import 'student_pages.dart';

Widget parentContent({
  required int index,
  required ConsoleSnapshot snapshot,
  required ConsoleRepository repository,
  required AuthUser user,
  required void Function(String childId) onSelectChild,
}) {
  final picker = ChildPicker(snapshot: snapshot, onSelectChild: onSelectChild);
  switch (index) {
    case 1:
      return Column(children: [picker, ParentChildClasses(snapshot: snapshot), StudentTimetable(snapshot: snapshot)]);
    case 2:
      return Column(children: [picker, StudentHomework(snapshot: snapshot)]);
    case 3:
      return Column(children: [picker, ParentAttendanceBreakdown(snapshot: snapshot), StudentAttendance(snapshot: snapshot)]);
    case 4:
      return Column(children: [picker, ParentGrades(snapshot: snapshot)]);
    case 5:
      return Column(children: [picker, ParentBehaviour(snapshot: snapshot)]);
    case 6:
      return ParentFees(snapshot: snapshot);
    case 7:
      return ParentMessages(snapshot: snapshot);
    case 8:
      return ChatListScreen(repository: repository, user: user);
    default:
      return Column(children: [ParentDashboard(snapshot: snapshot, onSelectChild: onSelectChild), picker]);
  }
}

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key, required this.snapshot, required this.onSelectChild});

  final ConsoleSnapshot snapshot;
  final void Function(String childId) onSelectChild;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final today = DateTime.now().toIso8601String().split('T').first;
    final todaysLessons = snapshot.lessons.where((lesson) => lesson.date == today).toList();
    final upcoming = snapshot.homework.where((item) => item.dueDate.isNotEmpty && item.dueDate.compareTo(today) >= 0).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return Column(
      children: [
        HeroPanel(greeting: strings.welcome, name: snapshot.personName, subtitle: strings.parentPortal),
        MetricGrid(metrics: [
          MetricTileData(title: strings.myChildren, value: '${snapshot.children.length}', tone: TileTone.mint),
          MetricTileData(title: strings.lessonsToday, value: '${todaysLessons.length}', tone: TileTone.sage),
          MetricTileData(title: strings.homeworkDue, value: '${upcoming.length}', tone: TileTone.green),
          MetricTileData(
            title: strings.attendanceRate,
            value: snapshot.attendanceRate.isEmpty ? '—' : snapshot.attendanceRate,
            tone: TileTone.gold,
          ),
        ]),
        WhitePanel(
          title: strings.childrenOverview,
          child: StudentList(
            students: snapshot.children,
            emptyMessage: strings.noChildren,
            onTap: (child) => onSelectChild(child.id),
          ),
        ),
        WhitePanel(
          title: strings.upcomingHomework,
          child: upcoming.isEmpty
              ? EmptyState(message: strings.noUpcomingHomework)
              : HomeworkList(items: upcoming.take(5).toList()),
        ),
        WhitePanel(
          title: strings.todaysLessons,
          child: LessonList(lessons: todaysLessons.isEmpty ? snapshot.lessons.take(5).toList() : todaysLessons),
        ),
        WhitePanel(title: strings.notices, child: NoticeList(notices: snapshot.notices)),
      ],
    );
  }
}

class ParentChildClasses extends StatelessWidget {
  const ParentChildClasses({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return WhitePanel(
      title: strings.childClasses,
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
    );
  }
}

class ParentAttendanceBreakdown extends StatelessWidget {
  const ParentAttendanceBreakdown({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final records = snapshot.attendance;
    final present = records.where((r) => r.status.toLowerCase().startsWith('present')).length;
    final late = records.where((r) => r.status.toLowerCase().contains('late')).length;
    final absent = records.length - present - late;
    return Column(
      children: [
        MetricGrid(metrics: [
          MetricTileData(title: strings.present, value: '$present', tone: TileTone.green),
          MetricTileData(title: strings.lateLabel, value: '$late', tone: TileTone.gold),
          MetricTileData(title: strings.absent, value: '$absent', tone: TileTone.red),
          MetricTileData(
            title: strings.attendanceRate,
            value: snapshot.attendanceRate.isEmpty ? '—' : snapshot.attendanceRate,
            tone: TileTone.mint,
          ),
        ]),
      ],
    );
  }
}

class ParentGrades extends StatelessWidget {
  const ParentGrades({super.key, required this.snapshot});

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

class ParentBehaviour extends StatelessWidget {
  const ParentBehaviour({super.key, required this.snapshot});

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

class ParentFees extends StatelessWidget {
  const ParentFees({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  bool _isPaid(InvoiceItem invoice) => invoice.status.toLowerCase().contains('paid');

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final unpaid = snapshot.invoices.where((invoice) => !_isPaid(invoice)).toList();
    final receipts = snapshot.invoices.where(_isPaid).toList();
    return Column(
      children: [
        MetricGrid(metrics: [
          MetricTileData(title: strings.invoices, value: '${snapshot.invoices.length}', tone: TileTone.sage),
          MetricTileData(title: strings.totalDue, value: '${unpaid.length}', tone: unpaid.isEmpty ? TileTone.mint : TileTone.red),
        ]),
        WhitePanel(
          title: strings.feeAlerts,
          child: unpaid.isEmpty
              ? EmptyState(message: strings.noFeeAlerts)
              : Column(
                  children: unpaid
                      .map((invoice) => RowTile(
                            leading: '!',
                            title: invoice.title,
                            subtitle: invoice.amount,
                            trailing: invoice.status.isEmpty ? strings.dueLabel : invoice.status,
                            trailingColor: AppColors.red,
                          ))
                      .toList(),
                ),
        ),
        WhitePanel(
          title: strings.invoices,
          child: snapshot.invoices.isEmpty
              ? EmptyState(message: strings.noInvoices)
              : Column(
                  children: snapshot.invoices
                      .map((invoice) => RowTile(
                            leading: invoice.title.isEmpty ? '—' : invoice.title.substring(0, 1),
                            title: invoice.title,
                            subtitle: invoice.amount,
                            trailing: invoice.status.isEmpty
                                ? (_isPaid(invoice) ? strings.paidLabel : strings.dueLabel)
                                : invoice.status,
                            trailingColor: _isPaid(invoice) ? AppColors.green : AppColors.gold,
                          ))
                      .toList(),
                ),
        ),
        WhitePanel(
          title: strings.receipts,
          child: receipts.isEmpty
              ? EmptyState(message: strings.noReceipts)
              : Column(
                  children: receipts
                      .map((invoice) => RowTile(
                            leading: '✓',
                            title: invoice.title,
                            subtitle: invoice.amount,
                            trailing: strings.paidLabel,
                            trailingColor: AppColors.green,
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class ParentMessages extends StatelessWidget {
  const ParentMessages({super.key, required this.snapshot});

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

class ChildPicker extends StatelessWidget {
  const ChildPicker({super.key, required this.snapshot, required this.onSelectChild});

  final ConsoleSnapshot snapshot;
  final void Function(String childId) onSelectChild;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    if (snapshot.children.isEmpty) {
      return WhitePanel(title: strings.myChildren, child: EmptyState(message: strings.noChildren));
    }
    return WhitePanel(
      title: strings.selectChild,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: snapshot.children
            .map((child) => ChoiceChip(
                  label: Text(child.name),
                  selected: child.id == snapshot.selectedChildId,
                  selectedColor: AppColors.mint,
                  onSelected: (_) => onSelectChild(child.id),
                ))
            .toList(),
      ),
    );
  }
}
