import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';
import 'account_pages.dart';
import 'learning_pages.dart';
import 'admin_pages.dart';
import 'parent_pages.dart';
import 'staff_pages.dart';
import 'student_pages.dart';
import 'teacher_more_pages.dart';
import 'teacher_pages.dart';

class ConsoleTab {
  const ConsoleTab(this.index, this.label, this.icon, [this.paths = const [], this.inMenu = false]);

  /// Shown in the side menu instead of the bottom bar.
  final bool inMenu;

  /// Position of the page in the role's page list (what the content switch uses).
  final int index;
  final String label;
  final IconData icon;

  /// School-system lists the page is built from. When the role may read none
  /// of them, the page is hidden from that role.
  final List<String> paths;
}

class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key, required this.session, required this.repository});

  final SessionController session;
  final ConsoleRepository repository;

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  int _index = 0;
  int _section = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;
  String? _error;
  ConsoleSnapshot? _snapshot;
  String? _childId;

  AuthUser get _user => widget.session.user!;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      final strings = L10n.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.pressBackAgain)),
      );
      return false;
    }
    return true;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await widget.repository.load(_user, childId: _childId);
      if (!snapshot.isOffline) {
        await widget.repository.probe([
          ConsoleRepository.ebookPath,
          if (_user.role == ConsoleRole.teacher) ...teacherExtraPages.map((page) => page.path),
        ]);
      }
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _childId = snapshot.selectedChildId.isEmpty ? _childId : snapshot.selectedChildId;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'load';
      });
    }
  }

  void _selectChild(String childId) {
    setState(() => _childId = childId);
    _load();
  }

  List<ConsoleTab> _allTabs(L10n strings) {
    switch (_user.role) {
      case ConsoleRole.teacher:
        return [
          ConsoleTab(0, strings.dashboard, Icons.dashboard_outlined),
          ConsoleTab(1, strings.timetable, Icons.calendar_today_outlined, ['/school-terms', '/days-of-weeks']),
          ConsoleTab(2, strings.attendance, Icons.fact_check_outlined, ['/attendance']),
          ConsoleTab(3, strings.isArabic ? 'الدروس' : 'Lessons', Icons.edit_note_outlined, ['/lessons']),
          ConsoleTab(9, strings.isArabic ? 'الاختبارات' : 'Tests', Icons.quiz_outlined, ['/lessons', '/markbook-columns']),
          ConsoleTab(7, strings.messages, Icons.mail_outline, ['/messages']),
          ConsoleTab(4, strings.students, Icons.groups_outlined, ['/class-enrolments'], true),
          ConsoleTab(5, strings.grades, Icons.grade_outlined, ['/markbook-entries'], true),
          ConsoleTab(6, strings.behaviour, Icons.emoji_people_outlined, ['/behaviour'], true),
          ConsoleTab(8, strings.more, Icons.more_horiz, teacherExtraPages.map((page) => page.path).toList(), true),
        ];
      case ConsoleRole.parent:
        return [
          ConsoleTab(0, strings.dashboard, Icons.dashboard_outlined),
          ConsoleTab(1, strings.timetable, Icons.calendar_today_outlined, ['/lessons', '/class-enrolments']),
          ConsoleTab(2, strings.homework, Icons.menu_book_outlined, ['/lessons']),
          ConsoleTab(3, strings.attendance, Icons.fact_check_outlined, ['/attendance']),
          ConsoleTab(4, strings.grades, Icons.grade_outlined, ['/markbook-entries']),
          ConsoleTab(5, strings.behaviour, Icons.emoji_people_outlined, ['/behaviour']),
          ConsoleTab(6, strings.fees, Icons.receipt_long_outlined, ['/invoices']),
          ConsoleTab(7, strings.messages, Icons.mail_outline, ['/messages']),
        ];
      case ConsoleRole.student:
        return [
          ConsoleTab(0, strings.dashboard, Icons.dashboard_outlined),
          ConsoleTab(1, strings.timetable, Icons.calendar_today_outlined, ['/school-terms', '/days-of-weeks']),
          ConsoleTab(2, strings.homework, Icons.menu_book_outlined, ['/lessons']),
          ConsoleTab(7, strings.isArabic ? 'الاختبارات' : 'Tests', Icons.quiz_outlined, ['/markbook-columns', '/planner-entry-homeworks']),
          ConsoleTab(6, strings.messages, Icons.mail_outline, ['/messages']),
          ConsoleTab(3, strings.attendance, Icons.fact_check_outlined, ['/attendance'], true),
          ConsoleTab(4, strings.grades, Icons.grade_outlined, ['/markbook-entries'], true),
          ConsoleTab(5, strings.behaviour, Icons.emoji_people_outlined, ['/behaviour'], true),
        ];
      case ConsoleRole.staff:
        return [
          ConsoleTab(0, strings.dashboard, Icons.dashboard_outlined),
          ConsoleTab(1, strings.students, Icons.groups_outlined, ['/class-enrolments']),
          ConsoleTab(2, strings.classes, Icons.class_outlined, ['/classes']),
          ConsoleTab(3, strings.messages, Icons.mail_outline, ['/messages']),
        ];
      case ConsoleRole.admin:
        return [
          ConsoleTab(0, strings.dashboard, Icons.dashboard_outlined),
          ConsoleTab(1, strings.isArabic ? 'الأقسام' : 'Sections', Icons.apps_outlined),
          ConsoleTab(6, strings.isArabic ? 'الجداول' : 'Timetable', Icons.calendar_month_outlined),
          ConsoleTab(4, strings.messages, Icons.mail_outline, ['/messages']),
        ];
    }
  }

  /// Only the pages this person's role may actually read.
  List<ConsoleTab> _tabs(L10n strings) {
    final denied = widget.repository.deniedPaths;
    return _allTabs(strings)
        .where((tab) => tab.paths.isEmpty || !tab.paths.every(denied.contains))
        .toList();
  }

  String _portalEyebrow(L10n strings) {
    switch (_user.role) {
      case ConsoleRole.teacher:
        return strings.myClasses;
      case ConsoleRole.parent:
        return strings.myChildren;
      case ConsoleRole.student:
        return strings.mySchool;
      case ConsoleRole.staff:
        return strings.staffPortal;
      case ConsoleRole.admin:
        return strings.adminPortal;
    }
  }

  String _portalTitle(L10n strings) {
    switch (_user.role) {
      case ConsoleRole.teacher:
        return strings.teacherPortal;
      case ConsoleRole.parent:
        return strings.parentPortal;
      case ConsoleRole.student:
        return strings.studentPortal;
      case ConsoleRole.staff:
        return strings.staffPortal;
      case ConsoleRole.admin:
        return strings.adminPortal;
    }
  }

  Widget _content(ConsoleSnapshot snapshot, int pageIndex) {
    switch (_user.role) {
      case ConsoleRole.teacher:
        if (pageIndex == 9) return teacherLearningHub(snapshot: snapshot, repository: widget.repository);
        return teacherContent(
          index: pageIndex,
          snapshot: snapshot,
          user: _user,
          repository: widget.repository,
          onChanged: _load,
          section: _section,
          onOpen: (page, section) => setState(() {
            _index = page;
            _section = section;
          }),
        );
      case ConsoleRole.parent:
        return parentContent(
          index: pageIndex,
          snapshot: snapshot,
          onSelectChild: _selectChild,
        );
      case ConsoleRole.student:
        if (pageIndex == 7) return studentLearningHub(snapshot: snapshot, repository: widget.repository, user: _user);
        return studentContent(index: pageIndex, snapshot: snapshot, repository: widget.repository, user: _user);
      case ConsoleRole.staff:
        return staffContent(index: pageIndex, snapshot: snapshot);
      case ConsoleRole.admin:
        return adminContent(index: pageIndex, snapshot: snapshot, repository: widget.repository);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final allowed = _tabs(strings);
    final tabs = allowed.where((tab) => !tab.inMenu).toList();
    final menuTabs = allowed.where((tab) => tab.inMenu).toList();
    final snapshot = _snapshot;
    // _index is the page's own index; hidden pages can never be selected.
    final open = allowed.any((tab) => tab.index == _index);
    final pageIndex = open ? _index : (tabs.isEmpty ? 0 : tabs.first.index);
    final selected = tabs.indexWhere((tab) => tab.index == pageIndex);

    return Directionality(
      textDirection: strings.direction,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.cream,
          drawer: AccountDrawer(
            session: widget.session,
            repository: widget.repository,
            portalTitle: _portalTitle(strings),
            pages: [
              for (final tab in menuTabs)
                (tab.label, tab.icon, () => setState(() {
                  _index = tab.index;
                  _section = 0;
                })),
            ],
          ),
          body: Column(
            children: [
              TawasulTopBar(
                title: strings.appName,
                subtitle: _portalTitle(strings),
                onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              if (snapshot != null)
                OfflineRibbon(isOffline: snapshot.isOffline, pendingDrafts: snapshot.pendingDraftCount),
              Expanded(
                child: _loading
                    ? Center(child: Text(strings.loading, style: const TextStyle(color: AppColors.muted)))
                    : _error != null
                        ? _ErrorView(message: strings.networkError, retryLabel: strings.retry, onRetry: _load)
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (pageIndex == 0)
                                    PageHeader(eyebrow: _portalEyebrow(strings), title: _portalTitle(strings)),
                                  _content(snapshot!, pageIndex),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
          bottomNavigationBar: tabs.length < 2 ? null : NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: AppColors.gold,
              labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                    color: states.contains(WidgetState.selected) ? AppColors.pine : AppColors.muted,
                    fontSize: 11,
                    fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
                  )),
              iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                    color: states.contains(WidgetState.selected) ? AppColors.pine : AppColors.muted,
                  )),
            ),
            child: NavigationBar(
              height: 68,
              selectedIndex: selected < 0 ? 0 : selected,
              onDestinationSelected: (value) => setState(() {
                _index = tabs[value].index;
                _section = 0;
              }),
              destinations: tabs
                  .map((tab) => NavigationDestination(icon: Icon(tab.icon), label: tab.label))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.retryLabel, required this.onRetry});

  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.muted, size: 34),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            SizedBox(width: 180, child: PrimaryButton(label: retryLabel, onPressed: onRetry)),
          ],
        ),
      ),
    );
  }
}
