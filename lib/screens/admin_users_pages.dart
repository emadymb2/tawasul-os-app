part of 'admin_manage_pages.dart';

// إدارة المستخدم — dedicated, hand-built screens (no shared template).
// Users, Roles, Username formats, Password resets, User status log.

const _userPagePaths = {'/users', '/roles', '/username-formats', '/person-resets', '/person-status-logs'};

/// Returns the dedicated screen for a User Admin page, or null if none.
Widget? userAdminScreenFor(AdminPageSpec page, TawasulApiClient api) {
  if (page.paths.length != 1 || !_userPagePaths.contains(page.paths.first)) return null;
  switch (page.paths.first) {
    case '/users':
      return UsersAdminScreen(api: api);
    case '/roles':
      return RolesAdminScreen(api: api);
    case '/username-formats':
      return UsernameFormatsScreen(api: api);
    case '/person-resets':
      return PasswordResetsScreen(api: api);
    case '/person-status-logs':
      return StatusLogScreen(api: api);
  }
  return null;
}

// ------------------------------------------------------------- shared bits --

const _statuses = ['Full', 'Expected', 'Left', 'Pending Approval'];
const _genders = ['M', 'F', 'Other', 'Unspecified'];
const _titles = ['', 'Mr.', 'Ms.', 'Mrs.', 'Miss', 'Mx.', 'Dr.'];

String _statusLabel(BuildContext c, String v) => switch (v) {
      'Full' => _t(c, 'نشط', 'Full'),
      'Expected' => _t(c, 'متوقع', 'Expected'),
      'Left' => _t(c, 'غادر', 'Left'),
      'Pending Approval' => _t(c, 'بانتظار الموافقة', 'Pending approval'),
      _ => v,
    };

String _genderLabel(BuildContext c, String v) => switch (v) {
      'M' => _t(c, 'ذكر', 'Male'),
      'F' => _t(c, 'أنثى', 'Female'),
      'Other' => _t(c, 'آخر', 'Other'),
      _ => _t(c, 'غير محدد', 'Unspecified'),
    };

Color _statusColor(String v) => switch (v) {
      'Full' => AppColors.pine,
      'Expected' => AppColors.gold,
      'Left' => AppColors.red,
      _ => AppColors.muted,
    };

String _s(dynamic v) => v == null ? '' : '$v';

String _personName(Map<String, dynamic> u) {
  final first = _s(u['preferredName']).isNotEmpty ? _s(u['preferredName']) : _s(u['firstName']);
  final name = [first, _s(u['surname'])].where((e) => e.isNotEmpty).join(' ');
  return name.isNotEmpty ? name : _s(u['username']);
}

String _initials(Map<String, dynamic> u) {
  final n = _personName(u).trim();
  if (n.isEmpty) return '?';
  final parts = n.split(RegExp(r'\s+'));
  return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message, this.onRetry);
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(_t(context, 'إعادة المحاولة', 'Retry'))),
          ]),
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(this.title, this.icon, this.children);
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(icon, color: AppColors.pine, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.muted))),
        Expanded(child: SelectableText(value, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(_t(c, 'حذف $what؟', 'Delete $what?')),
      content: Text(_t(c, 'سيُحذف نهائياً من النظام المدرسي.', 'It will be permanently deleted from the school system.')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t(c, 'إلغاء', 'Cancel'))),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(_t(c, 'حذف', 'Delete'), style: const TextStyle(color: AppColors.red)),
        ),
      ],
    ),
  );
  return ok == true;
}

void _snack(BuildContext c, String msg) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));

/// Roles and people, loaded once and shared by the user pages.
class _Directory {
  static List<Map<String, dynamic>>? _roles;
  static Map<String, Map<String, dynamic>>? _people;

  static Future<List<Map<String, dynamic>>> roles(TawasulApiClient api) async =>
      _roles ??= await api.getList('/roles', query: {'pageSize': '200'});

  static Future<Map<String, Map<String, dynamic>>> people(TawasulApiClient api, {bool refresh = false}) async {
    if (_people != null && !refresh) return _people!;
    final rows = await api.getList('/users', query: {'pageSize': '500'});
    return _people = {for (final r in rows) _s(r['tawasulPersonID']): r};
  }

  static void invalidatePeople() => _people = null;

  static String roleName(String id) {
    for (final r in _roles ?? const <Map<String, dynamic>>[]) {
      if (_s(r['tawasulRoleID']) == id) return _s(r['name']);
    }
    return id;
  }
}

// ------------------------------------------------------------------ Users --

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key, required this.api});
  final TawasulApiClient api;

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _roles = [];
  String? _role;
  String? _status;
  int _page = 1, _totalPages = 1, _total = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_roles.isEmpty) _roles = await _Directory.roles(widget.api);
      final filtered = _role != null || _status != null;
      final body = await widget.api.getMap('/users', query: {
        'pageSize': filtered ? '500' : '30',
        'page': filtered ? '1' : '$_page',
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
      });
      var rows = TawasulApiClient.extractList(body);
      final meta = body['meta'];
      if (filtered) {
        rows = rows
            .where((r) => _role == null || _s(r['tawasulRoleIDAll']).split(',').contains(_role))
            .where((r) => _status == null || _s(r['status']) == _status)
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _totalPages = filtered ? 1 : (meta is Map ? int.tryParse('${meta['totalPages']}') ?? 1 : 1);
        _total = filtered ? rows.length : (meta is Map ? int.tryParse('${meta['total']}') ?? rows.length : rows.length);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorText(context, e);
      });
    }
  }

  Future<void> _open(Map<String, dynamic> u) async {
    final changed = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => UserProfileScreen(api: widget.api, user: u)));
    if (changed == true) _load();
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => UserFormScreen(api: widget.api)));
    if (saved == true) _load();
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'المستخدمون', 'Users'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(_t(context, 'مستخدم جديد', 'New user')),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              _page = 1;
              _load();
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: _t(context, 'ابحث بالاسم أو اسم المستخدم أو البريد', 'Search name, username or email'),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            _filterChip(_t(context, 'كل الأدوار', 'All roles'), _role == null, () {
              _role = null;
              _load();
            }),
            for (final r in _roles)
              _filterChip(_s(r['name']), _role == _s(r['tawasulRoleID']), () {
                _role = _s(r['tawasulRoleID']);
                _load();
              }),
          ]),
        ),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            _filterChip(_t(context, 'كل الحالات', 'All statuses'), _status == null, () {
              _status = null;
              _load();
            }),
            for (final st in _statuses)
              _filterChip(_statusLabel(context, st), _status == st, () {
                _status = st;
                _load();
              }),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(_t(context, '$_total مستخدم', '$_total users'), style: const TextStyle(color: AppColors.muted)),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorBox(_error!, _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _rows.isEmpty
                          ? ListView(children: [
                              const SizedBox(height: 80),
                              Center(child: Text(_t(context, 'لا يوجد مستخدمون', 'No users found'))),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              itemCount: _rows.length,
                              itemBuilder: (_, i) => _UserTile(user: _rows[i], onTap: () => _open(_rows[i])),
                            ),
                    ),
        ),
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: _page > 1
                    ? () {
                        _page--;
                        _load();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page / $_totalPages'),
              IconButton(
                onPressed: _page < _totalPages
                    ? () {
                        _page++;
                        _load();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _s(user['status']);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.mint,
          child: Text(_initials(user), style: const TextStyle(color: AppColors.pine, fontWeight: FontWeight.w800)),
        ),
        title: Text(_personName(user), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
        subtitle: Text('@${_s(user['username'])} · ${_s(user['rolePrimary'])}', style: const TextStyle(color: AppColors.muted)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          _Pill(_statusLabel(context, status), _statusColor(status)),
          if (_s(user['canLogin']) == 'N')
            const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.lock_outline, size: 16, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.api, required this.user});
  final TawasulApiClient api;
  final Map<String, dynamic> user;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Map<String, dynamic> _u = widget.user;
  bool _changed = false;
  List<Map<String, dynamic>>? _log;

  String get _id => _s(_u['tawasulPersonID']);

  @override
  void initState() {
    super.initState();
    _Directory.roles(widget.api).then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {});
    _loadLog();
  }

  Future<void> _loadLog() async {
    try {
      final rows = await widget.api.getList('/person-status-logs', query: {'pageSize': '500'});
      if (mounted) setState(() => _log = rows.where((r) => _s(r['tawasulPersonID']) == _id).toList());
    } catch (_) {
      if (mounted) setState(() => _log = []);
    }
  }

  Future<void> _reload() async {
    try {
      final body = await widget.api.getMap('/users/${Uri.encodeComponent(_id)}');
      final data = body['data'];
      if (data is Map<String, dynamic> && mounted) setState(() => _u = data);
    } catch (_) {}
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => UserFormScreen(api: widget.api, user: _u)));
    if (saved == true) {
      _changed = true;
      await _reload();
      _loadLog();
    }
  }

  Future<void> _delete() async {
    if (!await _confirmDelete(context, _t(context, 'المستخدم', 'user'))) return;
    try {
      await widget.api.deleteMap('/users/${Uri.encodeComponent(_id)}');
      _Directory.invalidatePeople();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _snack(context, _errorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _s(_u['status']);
    final roles = _s(_u['tawasulRoleIDAll']).split(',').where((e) => e.isNotEmpty).map(_Directory.roleName).join('، ');
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t(context, 'ملف المستخدم', 'User profile')),
          actions: [
            IconButton(tooltip: _t(context, 'تعديل', 'Edit'), onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
            IconButton(
                tooltip: _t(context, 'حذف', 'Delete'),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: AppColors.red)),
          ],
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: AppColors.pine,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.gold,
                  child: Text(_initials(_u),
                      style: const TextStyle(color: AppColors.pine, fontSize: 24, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text([_s(_u['title']), _personName(_u)].where((e) => e.isNotEmpty).join(' '),
                        style: const TextStyle(color: AppColors.cream, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('@${_s(_u['username'])}', style: TextStyle(color: AppColors.cream.withOpacity(0.8))),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _Pill(_s(_u['rolePrimary']).isNotEmpty ? _s(_u['rolePrimary']) : _Directory.roleName(_s(_u['tawasulRoleIDPrimary'])),
                          AppColors.gold),
                      _Pill(_statusLabel(context, status), AppColors.mint),
                      _Pill(_s(_u['canLogin']) == 'Y' ? _t(context, 'يمكنه الدخول', 'Can log in') : _t(context, 'الدخول موقوف', 'Login disabled'),
                          AppColors.cream),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
          _SectionCard(_t(context, 'الحساب', 'Account'), Icons.manage_accounts_outlined, [
            _InfoLine(_t(context, 'اسم المستخدم', 'Username'), _s(_u['username'])),
            _InfoLine(_t(context, 'كل الأدوار', 'All roles'), roles),
            _InfoLine(_t(context, 'آخر دخول', 'Last login'), _s(_u['lastTimestamp'])),
          ]),
          _SectionCard(_t(context, 'البيانات الشخصية', 'Personal'), Icons.badge_outlined, [
            _InfoLine(_t(context, 'الاسم الأول', 'First name'), _s(_u['firstName'])),
            _InfoLine(_t(context, 'اسم العائلة', 'Surname'), _s(_u['surname'])),
            _InfoLine(_t(context, 'الاسم المفضل', 'Preferred name'), _s(_u['preferredName'])),
            _InfoLine(_t(context, 'الاسم الرسمي', 'Official name'), _s(_u['officialName'])),
            _InfoLine(_t(context, 'الجنس', 'Gender'), _genderLabel(context, _s(_u['gender']))),
            _InfoLine(_t(context, 'تاريخ الميلاد', 'Date of birth'), _s(_u['dob'])),
            _InfoLine(_t(context, 'بلد الميلاد', 'Country of birth'), _s(_u['countryOfBirth'])),
            _InfoLine(_t(context, 'اللغة الأولى', 'First language'), _s(_u['languageFirst'])),
          ]),
          _SectionCard(_t(context, 'التواصل', 'Contact'), Icons.contact_phone_outlined, [
            _InfoLine(_t(context, 'البريد', 'Email'), _s(_u['email'])),
            _InfoLine(_t(context, 'بريد بديل', 'Alternate email'), _s(_u['emailAlternate'])),
            _InfoLine(_t(context, 'هاتف 1', 'Phone 1'), _s(_u['phone1'])),
            _InfoLine(_t(context, 'هاتف 2', 'Phone 2'), _s(_u['phone2'])),
            _InfoLine(_t(context, 'العنوان', 'Address'), _s(_u['address1'])),
            _InfoLine(_t(context, 'المنطقة', 'District'), _s(_u['address1District'])),
            _InfoLine(_t(context, 'الدولة', 'Country'), _s(_u['address1Country'])),
          ]),
          _SectionCard(_t(context, 'المدرسة', 'School'), Icons.school_outlined, [
            _InfoLine(_t(context, 'رقم الطالب', 'Student ID'), _s(_u['studentID'])),
            _InfoLine(_t(context, 'البيت', 'House'), _s(_u['houseName'])),
            _InfoLine(_t(context, 'تاريخ البدء', 'Start date'), _s(_u['dateStart'])),
            _InfoLine(_t(context, 'تاريخ الانتهاء', 'End date'), _s(_u['dateEnd'])),
          ]),
          _SectionCard(_t(context, 'سجل الحالة', 'Status history'), Icons.history_outlined, [
            if (_log == null)
              const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
            else if (_log!.isEmpty)
              Text(_t(context, 'لا يوجد تغييرات مسجلة', 'No recorded changes'), style: const TextStyle(color: AppColors.muted))
            else
              for (final l in _log!)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.swap_horiz, color: AppColors.pine),
                  title: Text('${_statusLabel(context, _s(l['statusOld']))} ← ${_statusLabel(context, _s(l['statusNew']))}'),
                  subtitle: Text('${_s(l['reason'])}\n${_s(l['timestamp'])}'),
                  isThreeLine: true,
                ),
          ]),
        ]),
      ),
    );
  }
}

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, required this.api, this.user});
  final TawasulApiClient api;
  final Map<String, dynamic>? user;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _form = GlobalKey<FormState>();
  final _text = <String, TextEditingController>{};
  late final Map<String, dynamic> _orig = widget.user ?? {};
  late String _title = _titles.contains(_s(_orig['title'])) ? _s(_orig['title']) : '';
  late String _gender = _genders.contains(_s(_orig['gender'])) ? _s(_orig['gender']) : 'Unspecified';
  late String _status = _statuses.contains(_s(_orig['status'])) ? _s(_orig['status']) : 'Full';
  late bool _canLogin = _s(_orig['canLogin']).isEmpty || _s(_orig['canLogin']) == 'Y';
  late String? _role = _s(_orig['tawasulRoleIDPrimary']).isEmpty ? null : _s(_orig['tawasulRoleIDPrimary']);
  late Set<String> _allRoles = _s(_orig['tawasulRoleIDAll']).split(',').where((e) => e.isNotEmpty).toSet();
  List<Map<String, dynamic>> _roles = [];
  bool _saving = false;

  bool get _isNew => widget.user == null;

  static const _textFields = [
    'firstName', 'surname', 'preferredName', 'officialName', 'username', 'email', 'emailAlternate', 'phone1',
    'phone2', 'address1', 'address1District', 'address1Country', 'languageFirst', 'countryOfBirth', 'studentID',
    'dob', 'dateStart', 'dateEnd',
  ];

  TextEditingController _c(String k) => _text.putIfAbsent(k, () => TextEditingController(text: _s(_orig[k])));

  @override
  void initState() {
    super.initState();
    for (final k in _textFields) {
      _c(k);
    }
    _Directory.roles(widget.api).then((r) {
      if (mounted) setState(() => _roles = r);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final roleIds = {..._allRoles, if (_role != null) _role!}.toList()..sort();
    final values = <String, dynamic>{
      for (final k in _textFields) k: _text[k]!.text.trim(),
      'title': _title,
      'gender': _gender,
      'status': _status,
      'canLogin': _canLogin ? 'Y' : 'N',
      'tawasulRoleIDPrimary': _role,
      'tawasulRoleIDAll': roleIds.join(','),
    };
    final body = <String, dynamic>{};
    values.forEach((k, v) {
      final old = _s(_orig[k]);
      final now = _s(v);
      if (_isNew ? now.isNotEmpty : now != old) body[k] = now.isEmpty ? null : now;
    });
    if (body.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isNew) {
        await widget.api.postMap('/users', body);
      } else {
        await widget.api.patchMap('/users/${Uri.encodeComponent(_s(_orig['tawasulPersonID']))}', body);
      }
      _Directory.invalidatePeople();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(context, _errorText(context, e));
      }
    }
  }

  Widget _field(String k, String ar, String en,
      {bool required = false, TextInputType? type, int lines = 1, bool date = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c(k),
        keyboardType: type,
        maxLines: lines,
        readOnly: date,
        onTap: date
            ? () async {
                final init = DateTime.tryParse(_c(k).text) ?? DateTime.now();
                final d = await showDatePicker(
                    context: context, initialDate: init, firstDate: DateTime(1900), lastDate: DateTime(2100));
                if (d != null) _c(k).text = d.toIso8601String().substring(0, 10);
              }
            : null,
        decoration: InputDecoration(
          labelText: '${_t(context, ar, en)}${required ? ' *' : ''}',
          suffixIcon: date ? const Icon(Icons.calendar_today_outlined, size: 18) : null,
        ),
        validator: (v) {
          final t = (v ?? '').trim();
          if (required && t.isEmpty) return _t(context, 'مطلوب', 'Required');
          if (type == TextInputType.emailAddress && t.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
            return _t(context, 'بريد غير صالح', 'Invalid email');
          }
          return null;
        },
      ),
    );
  }

  Widget _dropdown<T>(String label, T? value, List<T> items, String Function(T) text, ValueChanged<T?> onChanged,
          {bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<T>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: '$label${required ? ' *' : ''}'),
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(text(i)))],
          onChanged: onChanged,
          validator: required ? (v) => v == null ? _t(context, 'مطلوب', 'Required') : null : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final roleIds = [for (final r in _roles) _s(r['tawasulRoleID'])];
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? _t(context, 'مستخدم جديد', 'New user') : _t(context, 'تعديل المستخدم', 'Edit user'))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_t(context, 'حفظ', 'Save')),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _SectionCard(_t(context, 'الاسم', 'Name'), Icons.badge_outlined, [
            _dropdown<String>(_t(context, 'اللقب', 'Title'), _title, _titles, (v) => v.isEmpty ? '—' : v,
                (v) => setState(() => _title = v ?? '')),
            _field('firstName', 'الاسم الأول', 'First name', required: true),
            _field('surname', 'اسم العائلة', 'Surname', required: true),
            _field('preferredName', 'الاسم المفضل', 'Preferred name'),
            _field('officialName', 'الاسم الرسمي', 'Official name'),
            _dropdown<String>(_t(context, 'الجنس', 'Gender'), _gender, _genders, (v) => _genderLabel(context, v),
                (v) => setState(() => _gender = v ?? 'Unspecified')),
            _field('dob', 'تاريخ الميلاد', 'Date of birth', date: true),
          ]),
          _SectionCard(_t(context, 'الحساب والصلاحيات', 'Account & access'), Icons.admin_panel_settings_outlined, [
            _field('username', 'اسم المستخدم', 'Username'),
            _dropdown<String>(_t(context, 'الدور الأساسي', 'Primary role'), _role, roleIds, _Directory.roleName,
                (v) => setState(() => _role = v),
                required: true),
            if (_roles.isNotEmpty) ...[
              Text(_t(context, 'أدوار إضافية', 'Additional roles'), style: const TextStyle(color: AppColors.muted)),
              Wrap(spacing: 6, children: [
                for (final id in roleIds)
                  FilterChip(
                    label: Text(_Directory.roleName(id)),
                    selected: _allRoles.contains(id) || id == _role,
                    onSelected: id == _role
                        ? null
                        : (on) => setState(() => on ? _allRoles.add(id) : _allRoles.remove(id)),
                  ),
              ]),
              const SizedBox(height: 12),
            ],
            _dropdown<String>(_t(context, 'الحالة', 'Status'), _status, _statuses, (v) => _statusLabel(context, v),
                (v) => setState(() => _status = v ?? 'Full')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_t(context, 'يسمح له بتسجيل الدخول', 'Can log in')),
              value: _canLogin,
              onChanged: (v) => setState(() => _canLogin = v),
            ),
          ]),
          _SectionCard(_t(context, 'التواصل', 'Contact'), Icons.contact_phone_outlined, [
            _field('email', 'البريد', 'Email', type: TextInputType.emailAddress),
            _field('emailAlternate', 'بريد بديل', 'Alternate email', type: TextInputType.emailAddress),
            _field('phone1', 'هاتف 1', 'Phone 1', type: TextInputType.phone),
            _field('phone2', 'هاتف 2', 'Phone 2', type: TextInputType.phone),
            _field('address1', 'العنوان', 'Address', lines: 2),
            _field('address1District', 'المنطقة', 'District'),
            _field('address1Country', 'الدولة', 'Country'),
          ]),
          _SectionCard(_t(context, 'بيانات إضافية', 'More details'), Icons.info_outline, [
            _field('languageFirst', 'اللغة الأولى', 'First language'),
            _field('countryOfBirth', 'بلد الميلاد', 'Country of birth'),
            _field('studentID', 'رقم الطالب', 'Student ID'),
            _field('dateStart', 'تاريخ البدء', 'Start date', date: true),
            _field('dateEnd', 'تاريخ الانتهاء', 'End date', date: true),
          ]),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ Roles --

class RolesAdminScreen extends StatefulWidget {
  const RolesAdminScreen({super.key, required this.api});
  final TawasulApiClient api;

  @override
  State<RolesAdminScreen> createState() => _RolesAdminScreenState();
}

class _RolesAdminScreenState extends State<RolesAdminScreen> {
  late Future<List<dynamic>> _future = _load();

  Future<List<dynamic>> _load() => Future.wait([
        widget.api.getList('/roles', query: {'pageSize': '200'}),
        _Directory.people(widget.api, refresh: true),
      ]);

  Color _catColor(String c) => switch (c) {
        'Staff' => AppColors.pine,
        'Student' => AppColors.gold,
        'Parent' => AppColors.pineSoft,
        _ => AppColors.muted,
      };

  String _yn(BuildContext c, dynamic v) => _s(v) == 'Y' ? _t(c, 'نعم', 'Yes') : _t(c, 'لا', 'No');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'الأدوار', 'Roles'))),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return _ErrorBox(_errorText(context, snap.error!), () => setState(() => _future = _load()));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final roles = snap.data![0] as List<Map<String, dynamic>>;
          final people = (snap.data![1] as Map<String, Map<String, dynamic>>).values;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              for (final r in roles)
                Builder(builder: (context) {
                  final id = _s(r['tawasulRoleID']);
                  final count = people.where((p) => _s(p['tawasulRoleIDAll']).split(',').contains(id)).length;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _catColor(_s(r['category'])).withOpacity(0.15),
                        child: Text(_s(r['nameShort']),
                            style: TextStyle(color: _catColor(_s(r['category'])), fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      title: Text(_s(r['name']), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      subtitle: Text(_t(context, '$count مستخدم', '$count users'), style: const TextStyle(color: AppColors.muted)),
                      trailing: _Pill(_s(r['category']), _catColor(_s(r['category']))),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        _InfoLine(_t(context, 'الوصف', 'Description'), _s(r['description'])),
                        _InfoLine(_t(context, 'النوع', 'Type'), _s(r['type'])),
                        _InfoLine(_t(context, 'القيود', 'Restriction'), _s(r['restriction'])),
                        _InfoLine(_t(context, 'يسمح بالدخول', 'Can log in'), _yn(context, r['canLoginRole'])),
                        _InfoLine(_t(context, 'دخول السنوات القادمة', 'Future years login'), _yn(context, r['futureYearsLogin'])),
                        _InfoLine(_t(context, 'دخول السنوات السابقة', 'Past years login'), _yn(context, r['pastYearsLogin'])),
                      ],
                    ),
                  );
                }),
            ]),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------- Username formats --

class UsernameFormatsScreen extends StatefulWidget {
  const UsernameFormatsScreen({super.key, required this.api});
  final TawasulApiClient api;

  @override
  State<UsernameFormatsScreen> createState() => _UsernameFormatsScreenState();
}

class _UsernameFormatsScreenState extends State<UsernameFormatsScreen> {
  late Future<List<Map<String, dynamic>>> _future = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    await _Directory.roles(widget.api);
    return widget.api.getList('/username-formats', query: {'pageSize': '200'});
  }

  Future<void> _edit([Map<String, dynamic>? f]) async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => _UsernameFormatForm(api: widget.api, format: f)));
    if (saved == true) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'صيغ أسماء المستخدمين', 'Username formats'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(_t(context, 'صيغة جديدة', 'New format')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return _ErrorBox(_errorText(context, snap.error!), () => setState(() => _future = _load()));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return Center(child: Text(_t(context, 'لا توجد صيغ', 'No formats yet')));
          return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
            for (final f in rows)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => _edit(f),
                  leading: const Icon(Icons.text_fields, color: AppColors.pine),
                  title: Text(_s(f['format']), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    _s(f['tawasulRoleIDList']).split(',').where((e) => e.isNotEmpty).map(_Directory.roleName).join('، '),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  trailing: Wrap(spacing: 4, children: [
                    if (_s(f['isDefault']) == 'Y') _Pill(_t(context, 'افتراضي', 'Default'), AppColors.pine),
                    if (_s(f['isNumeric']) == 'Y') _Pill(_t(context, 'رقمي', 'Numeric'), AppColors.gold),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class _UsernameFormatForm extends StatefulWidget {
  const _UsernameFormatForm({required this.api, this.format});
  final TawasulApiClient api;
  final Map<String, dynamic>? format;

  @override
  State<_UsernameFormatForm> createState() => _UsernameFormatFormState();
}

class _UsernameFormatFormState extends State<_UsernameFormatForm> {
  late final Map<String, dynamic> _o = widget.format ?? {};
  late final _format = TextEditingController(text: _s(_o['format']));
  late final _value = TextEditingController(text: _s(_o['numericValue']).isEmpty ? '0' : _s(_o['numericValue']));
  late final _inc = TextEditingController(text: _s(_o['numericIncrement']).isEmpty ? '1' : _s(_o['numericIncrement']));
  late final _size = TextEditingController(text: _s(_o['numericSize']).isEmpty ? '4' : _s(_o['numericSize']));
  late final Set<String> _roles = _s(_o['tawasulRoleIDList']).split(',').where((e) => e.isNotEmpty).toSet();
  late bool _default = _s(_o['isDefault']) == 'Y';
  late bool _numeric = _s(_o['isNumeric']) == 'Y';
  List<Map<String, dynamic>> _allRoles = [];
  bool _saving = false;

  static const _tokens = ['[preferredName]', '[preferredName:1]', '[firstName]', '[firstName:1]', '[surname]', '[number]'];

  bool get _isNew => widget.format == null;
  String get _id => _s(_o['tawasulUsernameFormatID']);

  @override
  void initState() {
    super.initState();
    _Directory.roles(widget.api).then((r) {
      if (mounted) setState(() => _allRoles = r);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in [_format, _value, _inc, _size]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_format.text.trim().isEmpty || _roles.isEmpty) {
      _snack(context, _t(context, 'اكتب الصيغة واختر دوراً واحداً على الأقل', 'Enter a format and pick at least one role'));
      return;
    }
    final body = {
      'format': _format.text.trim(),
      'tawasulRoleIDList': (_roles.toList()..sort()).join(','),
      'isDefault': _default ? 'Y' : 'N',
      'isNumeric': _numeric ? 'Y' : 'N',
      'numericValue': int.tryParse(_value.text) ?? 0,
      'numericIncrement': int.tryParse(_inc.text) ?? 1,
      'numericSize': int.tryParse(_size.text) ?? 4,
    };
    setState(() => _saving = true);
    try {
      if (_isNew) {
        await widget.api.postMap('/username-formats', body);
      } else {
        await widget.api.patchMap('/username-formats/${Uri.encodeComponent(_id)}', body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(context, _errorText(context, e));
      }
    }
  }

  Future<void> _delete() async {
    if (!await _confirmDelete(context, _t(context, 'الصيغة', 'format'))) return;
    try {
      await widget.api.deleteMap('/username-formats/${Uri.encodeComponent(_id)}');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _snack(context, _errorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? _t(context, 'صيغة جديدة', 'New format') : _t(context, 'تعديل الصيغة', 'Edit format')),
        actions: [
          if (!_isNew)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline, color: AppColors.red)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_t(context, 'حفظ', 'Save')),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _SectionCard(_t(context, 'الصيغة', 'Format'), Icons.text_fields, [
          TextField(
            controller: _format,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: InputDecoration(labelText: _t(context, 'الصيغة *', 'Format *')),
          ),
          const SizedBox(height: 8),
          Text(_t(context, 'اضغط لإضافة جزء:', 'Tap to insert:'), style: const TextStyle(color: AppColors.muted)),
          Wrap(spacing: 6, children: [
            for (final t in _tokens)
              ActionChip(label: Text(t), onPressed: () => setState(() => _format.text += t)),
          ]),
        ]),
        _SectionCard(_t(context, 'تطبق على الأدوار', 'Applies to roles'), Icons.badge_outlined, [
          Wrap(spacing: 6, children: [
            for (final r in _allRoles)
              FilterChip(
                label: Text(_s(r['name'])),
                selected: _roles.contains(_s(r['tawasulRoleID'])),
                onSelected: (on) => setState(() => on ? _roles.add(_s(r['tawasulRoleID'])) : _roles.remove(_s(r['tawasulRoleID']))),
              ),
          ]),
        ]),
        _SectionCard(_t(context, 'خيارات', 'Options'), Icons.tune, [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t(context, 'الصيغة الافتراضية', 'Default format')),
            value: _default,
            onChanged: (v) => setState(() => _default = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t(context, 'ترقيم تلقائي', 'Numeric')),
            value: _numeric,
            onChanged: (v) => setState(() => _numeric = v),
          ),
          if (_numeric) ...[
            TextField(controller: _value, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _t(context, 'الرقم الحالي', 'Current value'))),
            const SizedBox(height: 12),
            TextField(controller: _inc, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _t(context, 'مقدار الزيادة', 'Increment'))),
            const SizedBox(height: 12),
            TextField(controller: _size, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _t(context, 'عدد الخانات', 'Digits'))),
          ],
        ]),
      ]),
    );
  }
}

// -------------------------------------------------------- Password resets --

class PasswordResetsScreen extends StatefulWidget {
  const PasswordResetsScreen({super.key, required this.api});
  final TawasulApiClient api;

  @override
  State<PasswordResetsScreen> createState() => _PasswordResetsScreenState();
}

class _PasswordResetsScreenState extends State<PasswordResetsScreen> {
  late Future<List<dynamic>> _future = _load();

  Future<List<dynamic>> _load() => Future.wait([
        widget.api.getList('/person-resets', query: {'pageSize': '200'}),
        _Directory.people(widget.api),
      ]);

  Future<void> _cancel(Map<String, dynamic> r) async {
    if (!await _confirmDelete(context, _t(context, 'طلب إعادة التعيين', 'reset request'))) return;
    try {
      await widget.api.deleteMap('/person-resets/${Uri.encodeComponent(_s(r.values.first))}');
      setState(() => _future = _load());
    } catch (e) {
      if (mounted) _snack(context, _errorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'إعادة تعيين كلمات المرور', 'Password resets'))),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return _ErrorBox(_errorText(context, snap.error!), () => setState(() => _future = _load()));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data![0] as List<Map<String, dynamic>>;
          final people = snap.data![1] as Map<String, Map<String, dynamic>>;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                color: AppColors.mint,
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.pine),
                  title: Text(_t(context, 'طلبات "نسيت كلمة المرور" المفتوحة. يمكنك إلغاء أي طلب مشبوه.',
                      'Open "forgot password" requests. You can cancel any suspicious request.')),
                ),
              ),
              const SizedBox(height: 8),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(children: [
                    const Icon(Icons.lock_open_outlined, size: 48, color: AppColors.muted),
                    const SizedBox(height: 8),
                    Text(_t(context, 'لا توجد طلبات مفتوحة', 'No open requests')),
                  ]),
                ),
              for (final r in rows)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.lock_reset, color: AppColors.gold),
                    title: Text(people[_s(r['tawasulPersonID'])] != null
                        ? _personName(people[_s(r['tawasulPersonID'])]!)
                        : _s(r['tawasulPersonID'])),
                    subtitle: Text(_s(r['timestamp'])),
                    trailing: IconButton(
                      tooltip: _t(context, 'إلغاء الطلب', 'Cancel request'),
                      onPressed: () => _cancel(r),
                      icon: const Icon(Icons.close, color: AppColors.red),
                    ),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------- User status log --

class StatusLogScreen extends StatefulWidget {
  const StatusLogScreen({super.key, required this.api});
  final TawasulApiClient api;

  @override
  State<StatusLogScreen> createState() => _StatusLogScreenState();
}

class _StatusLogScreenState extends State<StatusLogScreen> {
  late Future<List<dynamic>> _future = _load();
  final _search = TextEditingController();

  Future<List<dynamic>> _load() => Future.wait([
        widget.api.getList('/person-status-logs', query: {'pageSize': '500'}),
        _Directory.people(widget.api),
      ]);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'سجل حالات المستخدمين', 'User status log'))),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return _ErrorBox(_errorText(context, snap.error!), () => setState(() => _future = _load()));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final people = snap.data![1] as Map<String, Map<String, dynamic>>;
          String name(dynamic id) => people[_s(id)] != null ? _personName(people[_s(id)]!) : _s(id);
          final q = _search.text.trim().toLowerCase();
          final rows = (snap.data![0] as List<Map<String, dynamic>>)
              .where((r) => q.isEmpty || name(r['tawasulPersonID']).toLowerCase().contains(q) || _s(r['reason']).toLowerCase().contains(q))
              .toList()
            ..sort((a, b) => _s(b['timestamp']).compareTo(_s(a['timestamp'])));
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search), hintText: _t(context, 'ابحث بالاسم أو السبب', 'Search name or reason')),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() => _future = _load()),
                child: rows.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 80),
                        Center(child: Text(_t(context, 'لا توجد سجلات', 'No entries'))),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: rows.length,
                        itemBuilder: (_, i) {
                          final r = rows[i];
                          final newS = _s(r['statusNew']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(name(r['tawasulPersonID']),
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                                  ),
                                  Text(_s(r['timestamp']), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  _Pill(_statusLabel(context, _s(r['statusOld'])), _statusColor(_s(r['statusOld']))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 16)),
                                  _Pill(_statusLabel(context, newS), _statusColor(newS)),
                                ]),
                                if (_s(r['reason']).isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(_s(r['reason']), style: const TextStyle(color: AppColors.ink)),
                                ],
                                if (_s(r['tawasulPersonIDModified']).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(_t(context, 'بواسطة: ${name(r['tawasulPersonIDModified'])}', 'By: ${name(r['tawasulPersonIDModified'])}'),
                                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                ],
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
