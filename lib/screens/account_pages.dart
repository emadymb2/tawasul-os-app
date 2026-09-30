import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';
import 'library_pages.dart';

/// Side menu: who is signed in, profile, account settings and sign out.
class AccountDrawer extends StatelessWidget {
  const AccountDrawer({super.key, required this.session, required this.repository, required this.portalTitle, this.pages = const []});

  /// Portal pages shown in the side menu: label, icon, action.
  final List<(String, IconData, VoidCallback)> pages;

  final SessionController session;
  final ConsoleRepository repository;
  final String portalTitle;

  void _open(BuildContext context, Widget page) {
    final strings = L10n.of(context);
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Directionality(textDirection: strings.direction, child: page),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final user = session.user!;
    return Drawer(
      backgroundColor: AppColors.cream,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.pine, borderRadius: BorderRadius.circular(AppRadii.md)),
              child: Row(
                children: [
                  AvatarCircle(label: user.name.isEmpty ? '—' : user.name.substring(0, 1), size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(color: AppColors.cream, fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(portalTitle, style: const TextStyle(color: AppColors.mintText, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final (label, icon, onTap) in pages)
              _MenuItem(icon: icon, label: label, onTap: () {
                Navigator.of(context).pop();
                onTap();
              }),
            if (pages.isNotEmpty) const Divider(color: AppColors.line),
            _MenuItem(
              icon: Icons.person_outline,
              label: strings.profile,
              onTap: () => _open(context, ProfilePage(user: user, repository: repository)),
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: strings.accountSettings,
              onTap: () => _open(context, AccountSettingsPage(user: user, repository: repository)),
            ),
            if (!repository.deniedPaths.contains(ConsoleRepository.ebookPath))
              _MenuItem(
                icon: Icons.menu_book_outlined,
                label: strings.ebooks,
                onTap: () => _open(
                  context,
                  EbookLibraryPage(
                    repository: repository,
                    personId: user.personId,
                    bookmarksEnabled: user.role == ConsoleRole.student,
                  ),
                ),
              ),
            const Spacer(),
            const Divider(color: AppColors.line),
            _MenuItem(
              icon: Icons.logout,
              label: strings.signOut,
              color: AppColors.red,
              onTap: () {
                Navigator.of(context).pop();
                session.signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color = AppColors.pine});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}

String _v(Map<String, dynamic> row, String key) {
  final value = row[key]?.toString() ?? '';
  return value == 'null' ? '' : value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SubPage extends StatelessWidget {
  const _SubPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.pine,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: child,
    );
  }
}

/// Profile — the same personal block for everyone, plus a role section:
/// school details for students, staff details for teachers/staff/admins,
/// family and children for parents.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user, required this.repository});

  final AuthUser user;
  final ConsoleRepository repository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ProfileData> _future = widget.repository.loadProfile(widget.user);

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final user = widget.user;
    return _SubPage(
      title: strings.profile,
      child: FutureBuilder<ProfileData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: Text(strings.loading, style: const TextStyle(color: AppColors.muted)));
          }
          final data = snap.data ?? const ProfileData(person: {}, extra: {}, family: [], children: []);
          final p = data.person;
          final e = data.extra;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = widget.repository.loadProfile(user));
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                HeroPanel(greeting: user.roleLabel, name: user.name, subtitle: user.username),
                WhitePanel(
                  title: strings.personalInfo,
                  child: Column(children: [
                    _InfoRow(strings.fullName, user.name),
                    if (_v(p, 'officialName').isNotEmpty) _InfoRow(strings.officialName, _v(p, 'officialName')),
                    _InfoRow(strings.username2, user.username),
                    _InfoRow(strings.roleLabel, user.roleLabel),
                    _InfoRow(strings.email, _v(p, 'email').isEmpty ? user.email : _v(p, 'email')),
                    _InfoRow(strings.phone, _v(p, 'phone1')),
                    if (_v(p, 'gender').isNotEmpty) _InfoRow(strings.gender, _v(p, 'gender')),
                    if (_v(p, 'dob').isNotEmpty) _InfoRow(strings.dob, _v(p, 'dob')),
                    if (_v(p, 'status').isNotEmpty) _InfoRow(strings.accountStatus, _v(p, 'status')),
                    if (_v(p, 'lastTimestamp').isNotEmpty) _InfoRow(strings.lastLogin, _v(p, 'lastTimestamp')),
                  ]),
                ),
                if (user.role == ConsoleRole.student)
                  WhitePanel(
                    title: strings.schoolInfo,
                    child: Column(children: [
                      _InfoRow(strings.yearGroup, _v(e, 'yearGroup')),
                      _InfoRow(strings.formGroup, _v(e, 'formGroup')),
                      if (_v(e, 'studentID').isNotEmpty) _InfoRow(strings.studentIdLabel, _v(e, 'studentID')),
                    ]),
                  ),
                if (user.role == ConsoleRole.teacher || user.role == ConsoleRole.staff || user.role == ConsoleRole.admin)
                  WhitePanel(
                    title: strings.staffInfo,
                    child: Column(children: [
                      _InfoRow(strings.staffType, _v(e, 'type')),
                      _InfoRow(strings.jobTitle, _v(e, 'jobTitle')),
                    ]),
                  ),
                if (user.role == ConsoleRole.parent) ...[
                  WhitePanel(
                    title: strings.familyInfo,
                    child: data.family.isEmpty
                        ? const EmptyState()
                        : Column(
                            children: data.family.map((row) => _InfoRow(strings.familyName, _v(row, 'familyName'))).toList()),
                  ),
                  WhitePanel(
                    title: strings.myChildren,
                    child: data.children.isEmpty
                        ? const EmptyState()
                        : Column(
                            children: data.children.map((row) {
                              final name = [_v(row, 'preferredName'), _v(row, 'surname')]
                                  .where((part) => part.isNotEmpty)
                                  .join(' ');
                              return RowTile(leading: name.isEmpty ? '—' : name.substring(0, 1), title: name);
                            }).toList(),
                          ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Account settings — language and saved-data for everyone, own contact
/// details, and for parents how the school should contact them.
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key, required this.user, required this.repository});

  final AuthUser user;
  final ConsoleRepository repository;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  List<Map<String, dynamic>> _family = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final data = await widget.repository.loadProfile(widget.user);
    if (!mounted) return;
    setState(() {
      _email.text = _v(data.person, 'email').isEmpty ? widget.user.email : _v(data.person, 'email');
      _phone.text = _v(data.person, 'phone1');
      _family = data.family.map((row) => Map<String, dynamic>.from(row)).toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _saveContact() async {
    final strings = L10n.of(context);
    setState(() => _saving = true);
    final ok = await widget.repository.updateContact(widget.user.personId, {
      'email': _email.text.trim(),
      'phone1': _phone.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    _toast(ok ? strings.saved : strings.saveFailed);
  }

  Future<void> _togglePreference(Map<String, dynamic> link, String field, bool value) async {
    final strings = L10n.of(context);
    final id = _v(link, 'tawasulFamilyAdultID');
    final previous = link[field];
    setState(() => link[field] = value ? 'Y' : 'N');
    final ok = await widget.repository.updateFamilyContact(id, {field: value ? 'Y' : 'N'});
    if (!mounted) return;
    if (!ok) setState(() => link[field] = previous);
    _toast(ok ? strings.saved : strings.saveFailed);
  }

  Future<void> _clearSaved() async {
    final strings = L10n.of(context);
    for (final role in ConsoleRole.values) {
      await widget.repository.store.remove('console_${role.name}_${widget.user.personId}_self_v2');
    }
    if (mounted) _toast(strings.cleared);
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final scope = LocaleScope.of(context);
    return _SubPage(
      title: strings.accountSettings,
      child: _loading
          ? Center(child: Text(strings.loading, style: const TextStyle(color: AppColors.muted)))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                WhitePanel(
                  title: strings.appLanguage,
                  child: Column(children: [
                    RadioListTile<String>(
                      value: 'ar',
                      groupValue: scope.languageCode,
                      activeColor: AppColors.pine,
                      title: Text(strings.arabic),
                      onChanged: (value) => scope.onChanged('ar'),
                    ),
                    RadioListTile<String>(
                      value: 'en',
                      groupValue: scope.languageCode,
                      activeColor: AppColors.pine,
                      title: Text(strings.english),
                      onChanged: (value) => scope.onChanged('en'),
                    ),
                  ]),
                ),
                WhitePanel(
                  title: strings.contactDetails,
                  child: Column(children: [
                    LabeledField(label: strings.email, controller: _email),
                    const SizedBox(height: 10),
                    LabeledField(label: strings.phone, controller: _phone),
                    const SizedBox(height: 14),
                    PrimaryButton(label: strings.save, busy: _saving, onPressed: _saveContact),
                  ]),
                ),
                if (widget.user.role == ConsoleRole.parent)
                  ..._family.map((link) => WhitePanel(
                        title: '${strings.contactPreferences} · ${_v(link, 'familyName')}',
                        child: Column(children: [
                          for (final entry in {
                            'contactCall': strings.contactByCall,
                            'contactSMS': strings.contactBySms,
                            'contactEmail': strings.contactByEmail,
                          }.entries)
                            SwitchListTile(
                              value: _v(link, entry.key) == 'Y',
                              activeColor: AppColors.pine,
                              title: Text(entry.value),
                              onChanged: (value) => _togglePreference(link, entry.key, value),
                            ),
                        ]),
                      )),
                WhitePanel(
                  title: strings.offlineBanner,
                  child: SecondaryButton(label: strings.clearOfflineData, onPressed: _clearSaved),
                ),
              ],
            ),
    );
  }
}
