import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../data/console_repository.dart';
import '../widgets/tawasul_widgets.dart';
import 'chat_pages.dart';

Widget staffContent({required int index, required ConsoleSnapshot snapshot, required ConsoleRepository repository, required AuthUser user}) {
  switch (index) {
    case 1:
      return StaffStudents(snapshot: snapshot);
    case 2:
      return StaffClasses(snapshot: snapshot);
    case 3:
      return StaffMessages(snapshot: snapshot);
    case 4:
      return ChatListScreen(repository: repository, user: user);
    default:
      return StaffDashboard(snapshot: snapshot);
  }
}

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Column(
      children: [
        HeroPanel(greeting: strings.welcome, name: snapshot.personName, subtitle: strings.staffPortal),
        MetricGrid(metrics: [
          MetricTileData(title: strings.studentsCount, value: '${snapshot.students.length}', tone: TileTone.mint),
          MetricTileData(title: strings.classesCount, value: '${snapshot.classes.length}', tone: TileTone.sage),
          MetricTileData(title: strings.notices, value: '${snapshot.notices.length}', tone: TileTone.gold),
          MetricTileData(title: strings.messages, value: '${snapshot.messages.length}', tone: TileTone.green),
        ]),
        WhitePanel(title: strings.notices, child: NoticeList(notices: snapshot.notices)),
      ],
    );
  }
}

class StaffStudents extends StatelessWidget {
  const StaffStudents({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return WhitePanel(
      title: strings.allStudents,
      child: StudentList(students: snapshot.students, emptyMessage: strings.noStudents),
    );
  }
}

class StaffClasses extends StatelessWidget {
  const StaffClasses({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return WhitePanel(
      title: strings.allClasses,
      child: snapshot.classes.isEmpty
          ? const EmptyState()
          : Column(
              children: snapshot.classes
                  .map((item) => RowTile(
                        leading: item.name.isEmpty ? '—' : item.name.substring(0, 1),
                        title: item.name,
                        subtitle: item.courseName,
                        trailing: item.studentCount > 0 ? '${item.studentCount}' : '',
                      ))
                  .toList(),
            ),
    );
  }
}

class StaffMessages extends StatelessWidget {
  const StaffMessages({super.key, required this.snapshot});

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
