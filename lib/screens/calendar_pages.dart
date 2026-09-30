import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';

// School days and holidays, built from the school terms, the weekly school
// days and the special days (closures) the school system serves.

class _CalendarData {
  _CalendarData(this.terms, this.schoolWeekdays, this.closures);
  final List<(DateTime, DateTime)> terms;
  final Set<int> schoolWeekdays; // DateTime.weekday values
  final Map<String, String> closures; // yyyy-mm-dd -> name

  String iso(DateTime d) => d.toIso8601String().split('T').first;

  /// null = school day, otherwise the reason it is off.
  String? offReason(DateTime d, bool ar) {
    final key = iso(d);
    if (closures.containsKey(key)) return closures[key]!.isEmpty ? (ar ? 'عطلة' : 'Holiday') : closures[key];
    final inTerm = terms.isEmpty || terms.any((t) => !d.isBefore(t.$1) && !d.isAfter(t.$2));
    if (!inTerm) return ar ? 'خارج الفصل الدراسي' : 'Outside term';
    if (!schoolWeekdays.contains(d.weekday)) return ar ? 'عطلة أسبوعية' : 'Weekend';
    return null;
  }
}

const _dayNames = {
  'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7,
};

Future<_CalendarData> _loadCalendar(ConsoleRepository repo) async {
  final terms = <(DateTime, DateTime)>[];
  for (final t in await repo.fetchRecords('/school-terms')) {
    final a = DateTime.tryParse('${t['firstDay']}');
    final b = DateTime.tryParse('${t['lastDay']}');
    if (a != null && b != null) terms.add((a, b));
  }
  final weekdays = <int>{};
  for (final d in await repo.fetchRecords('/days-of-weeks')) {
    final n = _dayNames['${d['name']}'.toLowerCase()];
    if (n != null && '${d['schoolDay']}' == 'Y') weekdays.add(n);
  }
  final closures = <String, String>{};
  for (final s in await repo.fetchRecords('/special-days')) {
    final type = '${s['type'] ?? ''}';
    if (type.isNotEmpty && type != 'School Closure') continue;
    closures['${s['date']}'.split(' ').first] = '${s['name'] ?? ''}';
  }
  return _CalendarData(terms, weekdays.isEmpty ? {1, 2, 3, 4, 5} : weekdays, closures);
}

String _weekday(int d, bool ar) => ar
    ? const ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'][d - 1]
    : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];

/// Teacher: the next 30 days from today, each marked school day or holiday.
class SchoolDaysList extends StatefulWidget {
  const SchoolDaysList({super.key, required this.repository, this.days = 30});
  final ConsoleRepository repository;
  final int days;
  @override
  State<SchoolDaysList> createState() => _SchoolDaysListState();
}

class _SchoolDaysListState extends State<SchoolDaysList> {
  late final Future<_CalendarData> _future = _loadCalendar(widget.repository);

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final ar = strings.isArabic;
    return WhitePanel(
      title: ar ? 'أيام الدوام والإجازات (30 يومًا)' : 'School days and holidays (30 days)',
      child: FutureBuilder<_CalendarData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return Text(strings.loading);
          if (snap.hasError) return const EmptyState();
          final cal = snap.data!;
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day);
          final days = List.generate(widget.days, (i) => start.add(Duration(days: i)));
          final open = days.where((d) => cal.offReason(d, ar) == null).length;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${ar ? 'أيام الدوام' : 'School days'}: $open · ${ar ? 'الإجازات' : 'Days off'}: ${days.length - open}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.pine)),
            const SizedBox(height: 8),
            for (final d in days)
              RowTile(
                leading: '${d.day}',
                title: '${_weekday(d.weekday, ar)} · ${cal.iso(d)}',
                subtitle: cal.offReason(d, ar) ?? '',
                trailing: cal.offReason(d, ar) == null ? (ar ? 'دوام' : 'School') : (ar ? 'إجازة' : 'Off'),
                trailingColor: cal.offReason(d, ar) == null ? AppColors.green : AppColors.red,
              ),
          ]);
        },
      ),
    );
  }
}

/// Student: a monthly grid of school days and holidays.
class SchoolMonthCalendar extends StatefulWidget {
  const SchoolMonthCalendar({super.key, required this.repository});
  final ConsoleRepository repository;
  @override
  State<SchoolMonthCalendar> createState() => _SchoolMonthCalendarState();
}

class _SchoolMonthCalendarState extends State<SchoolMonthCalendar> {
  late final Future<_CalendarData> _future = _loadCalendar(widget.repository);
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final ar = strings.isArabic;
    return WhitePanel(
      title: ar ? 'تقويم الدوام الشهري' : 'Monthly school calendar',
      child: FutureBuilder<_CalendarData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return Text(strings.loading);
          if (snap.hasError) return const EmptyState();
          final cal = snap.data!;
          final first = _month;
          final count = DateTime(first.year, first.month + 1, 0).day;
          // Week starts on Saturday.
          final lead = (first.weekday - DateTime.saturday + 7) % 7;
          final today = cal.iso(DateTime.now());
          final cells = <Widget>[
            for (final w in [6, 7, 1, 2, 3, 4, 5])
              Center(child: Text(_weekday(w, ar).substring(0, ar ? 3 : 2), style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700))),
            for (var i = 0; i < lead; i++) const SizedBox(),
            for (var day = 1; day <= count; day++)
              Builder(builder: (_) {
                final d = DateTime(first.year, first.month, day);
                final off = cal.offReason(d, ar) != null;
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: off ? AppColors.red.withOpacity(0.12) : AppColors.mint,
                    borderRadius: BorderRadius.circular(8),
                    border: cal.iso(d) == today ? Border.all(color: AppColors.pine, width: 2) : null,
                  ),
                  child: Center(child: Text('$day', style: TextStyle(fontWeight: FontWeight.w800, color: off ? AppColors.red : AppColors.pine))),
                );
              }),
          ];
          final offDays = [
            for (var day = 1; day <= count; day++)
              if (cal.closures.containsKey(cal.iso(DateTime(first.year, first.month, day))))
                DateTime(first.year, first.month, day),
          ];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
              Expanded(child: Text('${first.year}-${first.month.toString().padLeft(2, '0')}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.pine))),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
            ]),
            GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cells),
            const SizedBox(height: 8),
            Wrap(spacing: 12, children: [
              _legend(AppColors.mint, ar ? 'دوام' : 'School day'),
              _legend(AppColors.red.withOpacity(0.12), ar ? 'إجازة' : 'Day off'),
            ]),
            for (final d in offDays)
              RowTile(leading: '${d.day}', title: cal.closures[cal.iso(d)]!.isEmpty ? (ar ? 'عطلة' : 'Holiday') : cal.closures[cal.iso(d)]!, subtitle: cal.iso(d)),
          ]);
        },
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]);
}
