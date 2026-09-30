part of 'admin_manage_pages.dart';

/// One field of a school-system record, with the kind of input it needs.
/// Kinds: text, long, number, email, phone, date, datetime, time, yn,
/// choice, ref:/path (pick a record from another list).
class FieldSpec {
  const FieldSpec(this.name, this.kind, {this.required = false, this.options = const [], this.maxLength = 0});

  final String name;
  final String kind;
  final bool required;
  final List<String> options;
  final int maxLength;

  String? get refPath => kind.startsWith('ref:') ? kind.substring(4) : null;
}

const _autoFields = {
  'tawasulPersonIDCreator', 'tawasulPersonIDCreated', 'tawasulPersonIDLastEdit', 'tawasulPersonIDModified',
  'tawasulPersonIDUpdate', 'tawasulPersonIDOperator', 'tawasulPersonIDStatus',
};

bool _isAuto(String f) => f.startsWith('timestamp') || _autoFields.contains(f);

String fieldLabel(BuildContext c, String f) {
  if (L10n.of(c).isArabic) return fieldLabelsAr[f] ?? _arabicLabel(f);
  return _englishLabel(f);
}

/// Fields for a resource: its published form, or (when the system does not
/// publish one) the fields seen on its records.
List<FieldSpec> _specsFor(String path, Iterable<String> seenKeys) {
  final specs = resourceFields[path] ?? moreResourceFields[path];
  if (specs != null && specs.isNotEmpty) return specs;
  return seenKeys.skip(1).map((k) {
    if (k.startsWith('tawasulPersonID')) return FieldSpec(k, 'ref:/users');
    if (RegExp(r'(^date|Date$)').hasMatch(k)) return FieldSpec(k, 'date');
    if (RegExp(r'^(amount|cost|value)$').hasMatch(k)) return FieldSpec(k, 'number');
    if (['description', 'notes', 'comment', 'body'].contains(k)) return FieldSpec(k, 'long');
    return FieldSpec(k, 'text');
  }).toList();
}

String _choiceLabel(BuildContext c, String v) {
  if (!L10n.of(c).isArabic) return v == 'Y' ? 'Yes' : v == 'N' ? 'No' : v;
  const ar = {
    'Y': 'نعم', 'N': 'لا', 'Full': 'كامل', 'Expected': 'متوقع', 'Left': 'غادر', 'Pending Approval': 'بانتظار الموافقة',
    'Success': 'نجاح', 'Partial Failure': 'فشل جزئي', 'Past': 'سابق', 'Current': 'حالي', 'Upcoming': 'قادم',
    'Write': 'كتابة', 'Read': 'قراءة', 'Family': 'الأسرة', 'Company': 'شركة', 'Core': 'أساسي', 'Additional': 'إضافي',
    'Passport': 'جواز سفر', 'ID Card': 'بطاقة هوية', 'Visa': 'تأشيرة', 'Document': 'وثيقة', 'Request': 'طلب',
    'Approval - Final': 'موافقة نهائية', 'Approval - Exempt': 'معفى من الموافقة', 'Rejection': 'رفض',
    'Cancellation': 'إلغاء', 'Ordered': 'تم الطلب', 'Paid': 'مدفوع', 'Pending': 'معلق', 'Issued': 'صادر',
    'Cancelled': 'ملغى', 'Refunded': 'مسترد', 'Male': 'ذكر', 'Female': 'أنثى',
  };
  return ar[v] ?? v;
}

/// Names for records in other lists, so ID fields show and pick by name.
class _RefCache {
  static final Map<String, Future<List<MapEntry<String, String>>>> _cache = {};

  static Future<List<MapEntry<String, String>>> options(TawasulApiClient api, String path) =>
      _cache.putIfAbsent(path, () async {
        try {
          final rows = await api.getList(path, query: {'pageSize': '200'});
          return rows
              .where((r) => r.isNotEmpty)
              .map((r) => MapEntry('${r.values.first}', _recordLabel(r)))
              .toList();
        } catch (_) {
          _cache.remove(path);
          return <MapEntry<String, String>>[];
        }
      });
}

// ================================================================== list ===

class ResourceListScreen extends StatefulWidget {
  const ResourceListScreen({super.key, required this.resource, required this.api});

  final AdminResource resource;
  final TawasulApiClient api;

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  List<String> _seenKeys = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
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
      final body = await widget.api.getMap(widget.resource.path, query: {
        'pageSize': '30',
        'page': '$_page',
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
      });
      final rows = TawasulApiClient.extractList(body);
      final meta = body['meta'];
      if (!mounted) return;
      setState(() {
        _rows = rows;
        if (rows.isNotEmpty) _seenKeys = rows.first.keys.toList();
        _totalPages = meta is Map ? (int.tryParse('${meta['totalPages']}') ?? 1) : 1;
        _total = meta is Map ? (int.tryParse('${meta['total']}') ?? rows.length) : rows.length;
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

  List<FieldSpec> get _specs => _specsFor(widget.resource.path, _seenKeys);

  Future<void> _openDetail(Map<String, dynamic> r) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => RecordDetailScreen(resource: widget.resource, api: widget.api, record: r, specs: _specs),
    ));
    if (changed == true) _load();
  }

  Future<void> _openNew() async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => RecordFormScreen(resource: widget.resource, api: widget.api, specs: _specs),
    ));
    if (changed == true) _load();
  }

  /// Two or three short facts shown under each record's name.
  List<String> _facts(BuildContext c, Map<String, dynamic> r) {
    const preferred = ['status', 'type', 'role', 'date', 'dateStart', 'invoiceDueDate', 'amount', 'email', 'username', 'nameShort', 'category', 'value'];
    final label = _recordLabel(r);
    final out = <String>[];
    for (final k in preferred) {
      final v = r[k];
      if (v == null || '$v'.trim().isEmpty || '$v' == label) continue;
      out.add('${fieldLabel(c, k)}: ${_choiceLabel(c, '$v')}');
      if (out.length == 3) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Directionality(
      textDirection: s.direction,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(widget.resource.title(s)),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.pine,
          onPressed: _openNew,
          icon: const Icon(Icons.add),
          label: Text(_t(context, 'إضافة', 'Add')),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  _page = 1;
                  _load();
                },
                decoration: InputDecoration(
                  hintText: _t(context, 'بحث في ${widget.resource.ar}', 'Search ${widget.resource.en}'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(s.loading, style: const TextStyle(color: AppColors.muted))),
                )
              else if (_error != null)
                EmptyState(message: _error!)
              else if (_rows.isEmpty)
                EmptyState(message: _t(context, 'لا توجد سجلات بعد. اضغط «إضافة» لإنشاء أول سجل.', 'No records yet. Tap Add to create one.'))
              else ...[
                Text(_t(context, 'العدد: $_total', 'Total: $_total'), style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 8),
                ..._rows.map((r) {
                  final label = _recordLabel(r);
                  final facts = _facts(context, r);
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.cream,
                        foregroundColor: AppColors.pine,
                        child: Icon(widget.resource.icon, size: 20),
                      ),
                      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: facts.isEmpty
                          ? null
                          : Text(facts.join(' · '), style: const TextStyle(color: AppColors.muted)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                      onTap: () => _openDetail(r),
                    ),
                  );
                }),
                if (_totalPages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _page > 1 ? () { _page--; _load(); } : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('$_page / $_totalPages'),
                      IconButton(
                        onPressed: _page < _totalPages ? () { _page++; _load(); } : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ detail ===

class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.resource, required this.api, required this.record, required this.specs});

  final AdminResource resource;
  final TawasulApiClient api;
  final Map<String, dynamic> record;
  final List<FieldSpec> specs;

  String get _idField => record.keys.first;
  String get _id => '${record[_idField]}';

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(_t(c, 'حذف السجل؟', 'Delete record?')),
        content: Text(_t(c, 'سيُحذف هذا السجل نهائياً من النظام المدرسي.',
            'This record will be permanently deleted from the school system.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t(c, 'إلغاء', 'Cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(_t(c, 'حذف', 'Delete'), style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await api.deleteMap('${resource.path}/${Uri.encodeComponent(_id)}');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(context, 'تم الحذف.', 'Deleted.'))));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorText(context, e))));
      }
    }
  }

  Future<void> _edit(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => RecordFormScreen(resource: resource, api: api, specs: specs, record: record),
    ));
    if (changed == true && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final specByName = {for (final f in specs) f.name: f};
    final keys = record.keys
        .where((k) => k != _idField && record[k] is! Map && record[k] is! List)
        .where((k) => record[k] != null && '${record[k]}'.trim().isNotEmpty)
        .toList();
    return Directionality(
      textDirection: s.direction,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(resource.title(s)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            WhitePanel(
              title: _recordLabel(record),
              child: keys.isEmpty
                  ? EmptyState(message: _t(context, 'لا توجد تفاصيل.', 'No details.'))
                  : Column(
                      children: keys.map((k) {
                        final spec = specByName[k];
                        return _DetailRow(
                          label: fieldLabel(context, k),
                          value: '${record[k]}',
                          refPath: spec?.refPath,
                          api: api,
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: PrimaryButton(label: _t(context, 'تعديل', 'Edit'), onPressed: () => _edit(context))),
              const SizedBox(width: 12),
              Expanded(child: SecondaryButton(label: _t(context, 'حذف', 'Delete'), onPressed: () => _delete(context))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, required this.api, this.refPath});

  final String label;
  final String value;
  final String? refPath;
  final TawasulApiClient api;

  @override
  Widget build(BuildContext context) {
    Widget valueText(String v) => Text(v, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.pine));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Expanded(
            child: refPath == null
                ? valueText(_choiceLabel(context, value))
                : FutureBuilder<List<MapEntry<String, String>>>(
                    future: _RefCache.options(api, refPath!),
                    builder: (context, snap) {
                      final match = (snap.data ?? const []).where((e) => e.key == value || int.tryParse(e.key) == int.tryParse(value));
                      return valueText(match.isEmpty ? value : match.first.value);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ================================================================== form ===

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key, required this.resource, required this.api, required this.specs, this.record});

  final AdminResource resource;
  final TawasulApiClient api;
  final List<FieldSpec> specs;
  final Map<String, dynamic>? record;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final Map<String, TextEditingController> _text = {};
  final Map<String, String?> _picked = {};
  bool _busy = false;

  bool get _isNew => widget.record == null;
  List<FieldSpec> get _fields => widget.specs.where((f) => !_isAuto(f.name)).toList();

  String _original(String f) {
    final v = widget.record?[f];
    return v == null || v is Map || v is List ? '' : '$v';
  }

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      if (f.kind == 'yn' || f.kind == 'choice' || f.refPath != null) {
        final v = _original(f.name);
        _picked[f.name] = v.isEmpty ? (f.kind == 'yn' ? 'N' : null) : v;
      } else {
        _text[f.name] = TextEditingController(text: _original(f.name));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _value(FieldSpec f) => _picked.containsKey(f.name) ? (_picked[f.name] ?? '') : _text[f.name]!.text.trim();

  Future<void> _save() async {
    final missing = _fields.where((f) => f.required && _value(f).isEmpty).map((f) => fieldLabel(context, f.name)).toList();
    if (missing.isNotEmpty) {
      _toast(_t(context, 'حقول مطلوبة: ${missing.join('، ')}', 'Required: ${missing.join(', ')}'));
      return;
    }
    final body = <String, dynamic>{};
    for (final f in _fields) {
      final v = _value(f);
      if (_isNew) {
        if (v.isEmpty) continue;
      } else if (v == _original(f.name)) {
        continue;
      }
      if (f.kind == 'number' && v.isNotEmpty) {
        body[f.name] = num.tryParse(v) ?? v;
      } else {
        body[f.name] = v.isEmpty ? null : v;
      }
    }
    if (body.isEmpty) {
      _toast(_t(context, 'لا توجد تغييرات.', 'Nothing changed.'));
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isNew) {
        await widget.api.postMap(widget.resource.path, body);
      } else {
        final id = '${widget.record!.values.first}';
        await widget.api.patchMap('${widget.resource.path}/${Uri.encodeComponent(id)}', body);
      }
      if (!mounted) return;
      _toast(_t(context, 'تم الحفظ في النظام المدرسي.', 'Saved to the school system.'));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(_errorText(context, e));
    }
  }

  InputDecoration _decoration(FieldSpec f, {Widget? suffix}) => InputDecoration(
        labelText: '${fieldLabel(context, f.name)}${f.required ? ' *' : ''}',
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Future<void> _pickDate(FieldSpec f, {bool withTime = false}) async {
    final c = _text[f.name]!;
    final initial = DateTime.tryParse(c.text) ?? DateTime.now();
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(1900), lastDate: DateTime(2100));
    if (date == null || !mounted) return;
    var out = date.toIso8601String().split('T').first;
    if (withTime) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
      if (!mounted) return;
      final t = time ?? const TimeOfDay(hour: 8, minute: 0);
      out = '$out ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
    }
    setState(() => c.text = out);
  }

  Future<void> _pickTime(FieldSpec f) async {
    final c = _text[f.name]!;
    final parts = c.text.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(parts.first) ?? 8, minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0),
    );
    if (time == null) return;
    setState(() => c.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00');
  }

  Widget _input(FieldSpec f) {
    switch (f.kind) {
      case 'yn':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(fieldLabel(context, f.name)),
          value: _picked[f.name] == 'Y',
          activeColor: AppColors.pine,
          onChanged: (v) => setState(() => _picked[f.name] = v ? 'Y' : 'N'),
        );
      case 'choice':
        return DropdownButtonFormField<String>(
          value: f.options.contains(_picked[f.name]) ? _picked[f.name] : null,
          isExpanded: true,
          decoration: _decoration(f),
          items: f.options.map((o) => DropdownMenuItem(value: o, child: Text(_choiceLabel(context, o)))).toList(),
          onChanged: (v) => setState(() => _picked[f.name] = v),
        );
      case 'date':
      case 'datetime':
        return TextField(
          controller: _text[f.name],
          readOnly: true,
          onTap: () => _pickDate(f, withTime: f.kind == 'datetime'),
          decoration: _decoration(f, suffix: const Icon(Icons.calendar_today_outlined)),
        );
      case 'time':
        return TextField(
          controller: _text[f.name],
          readOnly: true,
          onTap: () => _pickTime(f),
          decoration: _decoration(f, suffix: const Icon(Icons.schedule_outlined)),
        );
    }
    final ref = f.refPath;
    if (ref != null) {
      return FutureBuilder<List<MapEntry<String, String>>>(
        future: _RefCache.options(widget.api, ref),
        builder: (context, snap) {
          final opts = snap.data ?? const <MapEntry<String, String>>[];
          if (snap.connectionState == ConnectionState.done && opts.isEmpty) {
            // The list could not be read: fall back to typing the number.
            final c = _text.putIfAbsent(f.name, () => TextEditingController(text: _picked[f.name] ?? ''));
            return TextField(
              controller: c,
              keyboardType: TextInputType.number,
              decoration: _decoration(f),
              onChanged: (v) => _picked[f.name] = v.trim(),
            );
          }
          final current = _picked[f.name];
          final match = opts.where((e) => e.key == current || (current != null && int.tryParse(e.key) == int.tryParse(current)));
          return DropdownButtonFormField<String>(
            value: match.isEmpty ? null : match.first.key,
            isExpanded: true,
            decoration: _decoration(f),
            hint: Text(snap.connectionState == ConnectionState.done ? _t(context, 'اختر', 'Choose') : L10n.of(context).loading),
            items: opts.map((o) => DropdownMenuItem(value: o.key, child: Text(o.value, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _picked[f.name] = v),
          );
        },
      );
    }
    return TextField(
      controller: _text[f.name],
      maxLines: f.kind == 'long' ? 4 : 1,
      maxLength: f.maxLength > 0 && f.maxLength < 1000 ? f.maxLength : null,
      keyboardType: switch (f.kind) {
        'number' => const TextInputType.numberWithOptions(decimal: true),
        'email' => TextInputType.emailAddress,
        'phone' => TextInputType.phone,
        'long' => TextInputType.multiline,
        _ => TextInputType.text,
      },
      decoration: _decoration(f),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final fields = _fields;
    final required = fields.where((f) => f.required).toList();
    final optional = fields.where((f) => !f.required).toList();
    Widget group(String title, List<FieldSpec> list) => WhitePanel(
          title: title,
          child: Column(
            children: list.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _input(f))).toList(),
          ),
        );
    return Directionality(
      textDirection: s.direction,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(_isNew
              ? '${_t(context, 'إضافة', 'Add')} — ${widget.resource.title(s)}'
              : '${_t(context, 'تعديل', 'Edit')} — ${_recordLabel(widget.record!)}'),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (fields.isEmpty)
              EmptyState(message: _t(context, 'لا توجد حقول معروفة لهذه الصفحة بعد.', 'No known fields for this page yet.')),
            if (required.isNotEmpty) group(_t(context, 'البيانات الأساسية', 'Required details'), required),
            if (optional.isNotEmpty) group(_t(context, 'بيانات إضافية', 'More details'), optional),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(label: _t(context, 'حفظ', 'Save'), busy: _busy, onPressed: _busy ? null : _save),
            ),
          ],
        ),
      ),
    );
  }
}
