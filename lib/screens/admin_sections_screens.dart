import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import 'admin_section_detail_screens.dart';
import 'admin_sections.dart';
import 'admin_manage_pages.dart';

/// One admin menu section (mirrors a group of the school website's menu).
class AdminSection {
  const AdminSection(this.ar, this.en, this.icon, this.pages);

  final String ar;
  final String en;
  final IconData icon;
  final List<AdminPageSpec> pages;

  String title(L10n s) => s.isArabic ? ar : en;
}

/// One page inside a section; backed by one or more record types.
class AdminPageSpec {
  const AdminPageSpec(this.ar, this.en, this.paths);

  final String ar;
  final String en;
  final List<String> paths;

  String title(L10n s) => s.isArabic ? ar : en;
}

final Map<String, AdminResource> _knownResources = {
  for (final r in [...userAdminResources, ...financeResources, ...schoolResources, ...examResources]) r.path: r,
};

String _humanize(String path) {
  final words = path.replaceAll('/', '').split('-');
  final t = words.join(' ');
  return t.isEmpty ? path : t[0].toUpperCase() + t.substring(1);
}

AdminResource _resourceFor(AdminPageSpec page, String path, int index, IconData icon) {
  if (index == 0) return AdminResource(path, page.ar, page.en, icon);
  final known = _knownResources[path];
  if (known != null) return known;
  final en = _humanize(path);
  return AdminResource(path, '${page.ar} — $en', en, icon);
}

/// Looks up a dedicated section-level screen for the given section index.
Widget? adminSectionScreenFor(int sectionIndex, ConsoleRepository repository) {
  if (sectionIndex < 0 || sectionIndex >= adminSectionScreens.length) return null;
  return adminSectionScreens[sectionIndex](repository);
}

/// Admin "Sections" tab: every section as a card grid.
class AdminSectionsHome extends StatelessWidget {
  const AdminSectionsHome({super.key, required this.repository});

  final ConsoleRepository repository;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'أقسام الإدارة' : 'Admin sections'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (int i = 0; i < adminSections.length; i++)
            _SectionCard(
              section: adminSections[i],
              onTap: () {
                final dedicated = adminSectionScreenFor(i, repository);
                if (dedicated != null) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => dedicated));
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _AdminSectionScreen(section: adminSections[i], repository: repository),
                  ));
                }
              },
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.onTap});

  final AdminSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Icon(section.icon, size: 28, color: AppColors.pine),
        title: Text(section.title(s), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16)),
        subtitle: Text('${section.pages.length} ${s.isArabic ? 'صفحة' : 'pages'}', style: const TextStyle(color: AppColors.muted)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}

class _AdminSectionScreen extends StatelessWidget {
  const _AdminSectionScreen({required this.section, required this.repository});

  final AdminSection section;
  final ConsoleRepository repository;

  void _open(BuildContext context, AdminPageSpec page) {
    // 1. Try dedicated user-admin screens (Users, Roles, etc.)
    final dedicated = userAdminScreenFor(page, repository.api);
    if (dedicated != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => dedicated));
      return;
    }
    // 2. Try section-specific dedicated screens
    final sectionScreen = adminPageScreens[page.paths.first];
    if (sectionScreen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => sectionScreen(repository, section.icon)));
      return;
    }
    // 3. Fall back to generic resource list / multi-resource page
    final resources = [
      for (var i = 0; i < page.paths.length; i++) _resourceFor(page, page.paths[i], i, section.icon),
    ];
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => resources.length == 1
          ? ResourceListScreen(resource: resources.first, api: repository.api)
          : _AdminPageScreen(title: page.title(L10n.of(context)), resources: resources, repository: repository),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(section.title(s))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: section.pages
            .map((page) => Card(
                  child: ListTile(
                    leading: Icon(section.icon, color: AppColors.pine),
                    title: Text(page.title(s), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                    onTap: () => _open(context, page),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// A page with several related record types (e.g. Families + adults + children).
class _AdminPageScreen extends StatelessWidget {
  const _AdminPageScreen({required this.title, required this.resources, required this.repository});

  final String title;
  final List<AdminResource> resources;
  final ConsoleRepository repository;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => Card(
                  child: ListTile(
                    leading: Icon(r.icon, color: AppColors.pine),
                    title: Text(r.title(s), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ResourceListScreen(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
