import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import 'chat_pages.dart';
import 'learning_pages.dart';
import 'parent_pages.dart';
import 'staff_pages.dart';
import 'student_pages.dart';
import 'teacher_more_pages.dart';
import 'teacher_pages.dart';

// ================================================================ Teacher —===

/// A navigable item for the teacher portal.
class TeacherRoute {
  const TeacherRoute(this.pageIndex, this.title, this.icon, this.builder);

  final int pageIndex;
  final String Function(L10n) title;
  final IconData icon;
  final Widget Function(BuildContext context, ConsoleRepository repository, AuthUser user, ConsoleSnapshot snapshot) builder;
}

final teacherRoutes = <TeacherRoute>[
  TeacherRoute(0, (s) => s.dashboard, Icons.dashboard_outlined, (_, repo, user, snap) => TeacherDashboardScreen(snapshot: snap, repository: repo, user: user)),
  TeacherRoute(1, (s) => s.timetable, Icons.calendar_today_outlined, (_, repo, user, snap) => TeacherTimetableScreen(snapshot: snap, repository: repo, user: user)),
  TeacherRoute(2, (s) => s.attendance, Icons.fact_check_outlined, (_, repo, user, snap) => TeacherAttendanceScreen(snapshot: snap, user: user, repository: repo)),
  TeacherRoute(3, (s) => s.isArabic ? 'الدروس' : 'Lessons', Icons.edit_note_outlined, (_, repo, user, snap) => TeacherLessonsScreen(snapshot: snap, repository: repo, user: user)),
  TeacherRoute(7, (s) => s.messages, Icons.mail_outline, (_, repo, user, snap) => TeacherMessagesScreen(snapshot: snap, user: user, repository: repo)),
  TeacherRoute(8, (s) => s.chat, Icons.chat_bubble_outline, (_, repo, user, snap) => TeacherChatScreen(repository: repo, user: user)),
  TeacherRoute(9, (s) => s.more, Icons.more_horiz, (_, repo, user, snap) => TeacherMore(repository: repo)),
];

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.teacherPortal),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: TeacherDashboard(snapshot: snapshot, repository: repository, onOpen: (page, section) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TeacherLessonsScreen(snapshot: snapshot, repository: repository, user: user, initialSection: section),
              ));
            }),
          ),
        ),
      ),
    );
  }
}

class TeacherTimetableScreen extends StatelessWidget {
  const TeacherTimetableScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.timetable),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: TeacherTimetable(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class TeacherAttendanceScreen extends StatelessWidget {
  const TeacherAttendanceScreen({super.key, required this.snapshot, required this.user, required this.repository});

  final ConsoleSnapshot snapshot;
  final AuthUser user;
  final ConsoleRepository repository;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.attendance),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: TeacherAttendance(snapshot: snapshot, user: user, repository: repository, onSaved: () async => repository.load(user)),
          ),
        ),
      ),
    );
  }
}

class TeacherLessonsScreen extends StatelessWidget {
  const TeacherLessonsScreen({super.key, required this.snapshot, required this.repository, required this.user, this.initialSection = 0});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;
  final int initialSection;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.isArabic ? 'الدروس' : 'Lessons'),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: teacherLessonsHub(
              snapshot: snapshot,
              repository: repository,
              initial: initialSection,
              summaryForm: TeacherLessonForm(snapshot: snapshot, repository: repository, onSaved: () async => repository.load(user)),
            ),
          ),
        ),
      ),
    );
  }
}

class TeacherMessagesScreen extends StatelessWidget {
  const TeacherMessagesScreen({super.key, required this.snapshot, required this.user, required this.repository});

  final ConsoleSnapshot snapshot;
  final AuthUser user;
  final ConsoleRepository repository;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.messages),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: TeacherMessages(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

// ================================================================ Staff —===

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.staffPortal),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StaffDashboard(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class StaffStudentsScreen extends StatelessWidget {
  const StaffStudentsScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.students),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StaffStudents(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class StaffClassesScreen extends StatelessWidget {
  const StaffClassesScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.classes),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StaffClasses(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class StaffMessagesScreen extends StatelessWidget {
  const StaffMessagesScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.messages),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StaffMessages(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

// ================================================================ Student —===

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.studentPortal),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StudentDashboard(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class StudentTimetableScreen extends StatelessWidget {
  const StudentTimetableScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.timetable),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StudentTimetable(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class StudentHomeworkScreen extends StatelessWidget {
  const StudentHomeworkScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.homework),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: studentHomeworkPage(snapshot: snapshot, repository: repository, user: user),
          ),
        ),
      ),
    );
  }
}

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.attendance),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StudentAttendance(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class StudentGradesScreen extends StatelessWidget {
  const StudentGradesScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.grades),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StudentGrades(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class StudentBehaviourScreen extends StatelessWidget {
  const StudentBehaviourScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.behaviour),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StudentBehaviour(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class StudentMessagesScreen extends StatelessWidget {
  const StudentMessagesScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.messages),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: StudentMessages(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

// ================================================================ Parent —===

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key, required this.snapshot, required this.repository, required this.user, required this.onSelectChild});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;
  final void Function(String childId) onSelectChild;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.parentPortal),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user, childId: snapshot.selectedChildId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ParentDashboard(snapshot: snapshot, onSelectChild: onSelectChild),
          ),
        ),
      ),
    );
  }
}

class ParentTimetableScreen extends StatelessWidget {
  const ParentTimetableScreen({super.key, required this.snapshot, required this.repository, required this.user, required this.onSelectChild});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;
  final void Function(String childId) onSelectChild;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final picker = ChildPicker(snapshot: snapshot, onSelectChild: onSelectChild);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.timetable),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user, childId: snapshot.selectedChildId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [picker, ParentChildClasses(snapshot: snapshot), StudentTimetable(snapshot: snapshot)]),
          ),
        ),
      ),
    );
  }
}

class ParentHomeworkScreen extends StatelessWidget {
  const ParentHomeworkScreen({super.key, required this.snapshot, required this.repository, required this.user, required this.onSelectChild});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;
  final void Function(String childId) onSelectChild;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final picker = ChildPicker(snapshot: snapshot, onSelectChild: onSelectChild);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.homework),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user, childId: snapshot.selectedChildId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [picker, StudentHomework(snapshot: snapshot)]),
          ),
        ),
      ),
    );
  }
}

class ParentAttendanceScreen extends StatelessWidget {
  const ParentAttendanceScreen({super.key, required this.snapshot, required this.repository, required this.user, required this.onSelectChild});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;
  final void Function(String childId) onSelectChild;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final picker = ChildPicker(snapshot: snapshot, onSelectChild: onSelectChild);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.attendance),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user, childId: snapshot.selectedChildId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [picker, ParentAttendanceBreakdown(snapshot: snapshot), StudentAttendance(snapshot: snapshot)]),
          ),
        ),
      ),
    );
  }
}

class ParentGradesScreen extends StatelessWidget {
  const ParentGradesScreen({super.key, required this.snapshot, required this.repository, required this.user, required this.onSelectChild});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;
  final void Function(String childId) onSelectChild;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final picker = ChildPicker(snapshot: snapshot, onSelectChild: onSelectChild);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.grades),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user, childId: snapshot.selectedChildId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [picker, ParentGrades(snapshot: snapshot)]),
          ),
        ),
      ),
    );
  }
}

class ParentBehaviourScreen extends StatelessWidget {
  const ParentBehaviourScreen({super.key, required this.snapshot, required this.repository, required this.user, required this.onSelectChild});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;
  final void Function(String childId) onSelectChild;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final picker = ChildPicker(snapshot: snapshot, onSelectChild: onSelectChild);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.behaviour),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user, childId: snapshot.selectedChildId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [picker, ParentBehaviour(snapshot: snapshot)]),
          ),
        ),
      ),
    );
  }
}

class ParentFeesScreen extends StatelessWidget {
  const ParentFeesScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.fees),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user, childId: snapshot.selectedChildId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ParentFees(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

class ParentMessagesScreen extends StatelessWidget {
  const ParentMessagesScreen({super.key, required this.snapshot, required this.repository, required this.user});

  final ConsoleSnapshot snapshot;
  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(strings.messages),
        ),
        body: RefreshIndicator(
          onRefresh: () async => repository.load(user, childId: snapshot.selectedChildId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ParentMessages(snapshot: snapshot),
          ),
        ),
      ),
    );
  }
}

// ================================================================ Chat screens ===

class TeacherChatScreen extends StatelessWidget {
  const TeacherChatScreen({super.key, required this.repository, required this.user});

  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) => ChatListScreen(repository: repository, user: user);
}

class StaffChatScreen extends StatelessWidget {
  const StaffChatScreen({super.key, required this.repository, required this.user});

  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) => ChatListScreen(repository: repository, user: user);
}

class StudentChatScreen extends StatelessWidget {
  const StudentChatScreen({super.key, required this.repository, required this.user});

  final ConsoleRepository repository;
  final AuthUser user;

  @override
  Widget build(BuildContext context) => ChatListScreen(repository: repository, user: user);
}

class ParentChatScreen extends StatelessWidget {
  const ParentChatScreen({super.key, required this.repository, required this.user, required this.onSelectChild});

  final ConsoleRepository repository;
  final AuthUser user;
  final void Function(String childId) onSelectChild;

  @override
  Widget build(BuildContext context) => ChatListScreen(repository: repository, user: user);
}

// ================================================================ Portal bar ===

class PortalTabBar extends StatelessWidget implements PreferredSizeWidget {
  const PortalTabBar({super.key, required this.routes, required this.currentIndex, required this.onNavigate});

  final List<TeacherRoute> routes;
  final int currentIndex;
  final void Function(int index) onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(children: [
          for (final route in routes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: route.pageIndex == currentIndex ? AppColors.pine : AppColors.cream,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: route.pageIndex == currentIndex ? null : () => onNavigate(route.pageIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(children: [
                      Icon(route.icon,
                          size: 16,
                          color: route.pageIndex == currentIndex ? Colors.white : AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        route.title(s),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: route.pageIndex == currentIndex ? FontWeight.w800 : FontWeight.w600,
                          color: route.pageIndex == currentIndex ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
