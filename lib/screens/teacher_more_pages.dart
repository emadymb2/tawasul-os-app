import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/l10n.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';

/// Extra teacher pages that exist in the teacher menu on the school website
/// and that the teacher's own login may read through the school system.
class TeacherExtraPage {
  const TeacherExtraPage({required this.title, required this.icon, required this.path});

  final String Function(L10n strings) title;
  final IconData icon;
  final String path;
}

final teacherExtraPages = <TeacherExtraPage>[
  TeacherExtraPage(title: (s) => s.messengerGroups, icon: Icons.groups_2_outlined, path: '/groups'),
  TeacherExtraPage(title: (s) => s.activityAttendance, icon: Icons.sports_soccer_outlined, path: '/activity-attendances'),
  TeacherExtraPage(title: (s) => s.externalAssessments, icon: Icons.assignment_outlined, path: '/external-assessment-students'),
  TeacherExtraPage(title: (s) => s.crowdAssessment, icon: Icons.forum_outlined, path: '/crowd-assess-discusses'),
  TeacherExtraPage(title: (s) => s.investigations, icon: Icons.search_outlined, path: '/in-investigations'),
  TeacherExtraPage(title: (s) => s.library, icon: Icons.local_library_outlined, path: '/library-shelfs'),
  TeacherExtraPage(title: (s) => s.myExpenses, icon: Icons.payments_outlined, path: '/expenses'),
];

class TeacherMore extends StatelessWidget {
  const TeacherMore({super.key, required this.repository});

  final ConsoleRepository repository;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return WhitePanel(
      title: strings.morePages,
      child: Column(
        children: teacherExtraPages
            .where((page) => !repository.deniedPaths.contains(page.path))
            .map((page) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(page.icon, color: AppColors.pine),
                  title: Text(page.title(strings),
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => Directionality(
                      textDirection: strings.direction,
                      child: _RecordsPage(page: page, repository: repository),
                    ),
                  )),
                ))
            .toList(),
      ),
    );
  }
}

class _RecordsPage extends StatefulWidget {
  const _RecordsPage({required this.page, required this.repository});

  final TeacherExtraPage page;
  final ConsoleRepository repository;

  @override
  State<_RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<_RecordsPage> {
  late Future<List<Map<String, dynamic>>> _future = widget.repository.fetchRecords(widget.page.path);

  Future<void> _reload() async {
    setState(() => _future = widget.repository.fetchRecords(widget.page.path));
    await _future.catchError((_) => <Map<String, dynamic>>[]);
  }

  static const _titleKeys = ['name', 'title', 'subject', 'description', 'text', 'comment', 'reason', 'title'];
  static const _dateKeys = ['date', 'timestamp', 'timestampCreated', 'purchaseDate', 'timestampTaken'];

  String _pick(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString() ?? '';
      if (value.isNotEmpty) return value.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final title = widget.page.title(strings);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.pine,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            Widget child;
            if (snap.connectionState != ConnectionState.done) {
              child = Padding(
                padding: const EdgeInsets.all(24),
                child: Text(strings.loading, style: const TextStyle(color: AppColors.muted)),
              );
            } else if (snap.hasError) {
              final error = snap.error;
              final forbidden = error is TawasulApiException && error.statusCode == 403;
              child = EmptyState(message: forbidden ? strings.noPermission : strings.networkError);
            } else if (snap.data!.isEmpty) {
              child = const EmptyState();
            } else {
              child = Column(
                children: snap.data!.map((row) {
                  final name = _pick(row, _titleKeys);
                  final date = _pick(row, _dateKeys).split(' ').first;
                  final status = row['status']?.toString() ?? '';
                  return RowTile(
                    leading: name.isEmpty ? '—' : name.substring(0, 1),
                    title: name.isEmpty ? '—' : name,
                    subtitle: date,
                    trailing: status,
                  );
                }).toList(),
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [WhitePanel(title: title, child: child)],
            );
          },
        ),
      ),
    );
  }
}
