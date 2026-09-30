import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/l10n.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';

import './admin_sections_screens.dart';

part 'admin_specs.dart';
part 'admin_record_screens.dart';
part 'admin_specs_more.dart';
part 'admin_field_words.dart';
part 'admin_users_pages.dart';

/// One school-system record type the admin can list, add, edit and delete.
class AdminResource {
  const AdminResource(this.path, this.ar, this.en, this.icon);

  final String path;
  final String ar;
  final String en;
  final IconData icon;

  String title(L10n s) => s.isArabic ? ar : en;
}

/// إدارة المستخدم — every page of the User Admin module.
const userAdminResources = <AdminResource>[
  AdminResource('/users', 'المستخدمون', 'Users', Icons.person_outline),
  AdminResource('/roles', 'الأدوار', 'Roles', Icons.badge_outlined),
  AdminResource('/families', 'الأسر', 'Families', Icons.family_restroom_outlined),
  AdminResource('/family-adults', 'بالغو الأسرة', 'Family adults', Icons.escalator_warning_outlined),
  AdminResource('/family-children', 'أبناء الأسرة', 'Family children', Icons.child_care_outlined),
  AdminResource('/family-relationships', 'علاقات الأسرة', 'Family relationships', Icons.people_alt_outlined),
  AdminResource('/districts', 'المناطق', 'Districts', Icons.location_city_outlined),
  AdminResource('/personal-documents', 'الوثائق الشخصية', 'Personal documents', Icons.description_outlined),
  AdminResource('/personal-document-types', 'أنواع الوثائق الشخصية', 'Personal document types', Icons.folder_outlined),
  AdminResource('/username-formats', 'صيغ أسماء المستخدمين', 'Username formats', Icons.text_fields_outlined),
  AdminResource('/person-resets', 'إعادة تعيين كلمات المرور', 'Password resets', Icons.lock_reset_outlined),
  AdminResource('/person-status-logs', 'سجل حالات المستخدمين', 'User status log', Icons.history_outlined),
  AdminResource('/data-retentions', 'الاحتفاظ بالبيانات', 'Data retention', Icons.storage_outlined),
];

/// إدارة الماليات — every page of the Finance module.
const financeResources = <AdminResource>[
  AdminResource('/invoices', 'الفواتير', 'Invoices', Icons.receipt_long_outlined),
  AdminResource('/invoice-fees', 'بنود الفواتير', 'Invoice fees', Icons.list_alt_outlined),
  AdminResource('/finance-invoicees', 'مستلمو الفواتير', 'Invoicees', Icons.person_pin_outlined),
  AdminResource('/finance-billing-schedules', 'جداول الفوترة', 'Billing schedules', Icons.event_note_outlined),
  AdminResource('/fees', 'الرسوم', 'Fees', Icons.payments_outlined),
  AdminResource('/finance-fee-categories', 'فئات الرسوم', 'Fee categories', Icons.category_outlined),
  AdminResource('/budgets', 'الميزانيات', 'Budgets', Icons.account_balance_wallet_outlined),
  AdminResource('/finance-budget-cycles', 'دورات الميزانية', 'Budget cycles', Icons.autorenew_outlined),
  AdminResource('/finance-budget-cycle-allocations', 'مخصصات دورات الميزانية', 'Budget allocations', Icons.pie_chart_outline),
  AdminResource('/finance-budget-persons', 'أعضاء الميزانيات', 'Budget members', Icons.group_outlined),
  AdminResource('/expenses', 'النفقات', 'Expenses', Icons.shopping_cart_outlined),
  AdminResource('/finance-expense-approvers', 'الموافقون على النفقات', 'Expense approvers', Icons.verified_outlined),
  AdminResource('/finance-expense-logs', 'سجل النفقات', 'Expense log', Icons.receipt_outlined),
  AdminResource('/finance-petty-cashes', 'النثريات', 'Petty cash', Icons.savings_outlined),
];

/// إدارة المدرسة — the school records the admin portal already showed, now editable.
const schoolResources = <AdminResource>[
  AdminResource('/classes', 'الفصول', 'Classes', Icons.class_outlined),
  AdminResource('/courses', 'المقررات', 'Courses', Icons.menu_book_outlined),
  AdminResource('/class-enrolments', 'تسجيل الطلاب في الفصول', 'Class enrolments', Icons.how_to_reg_outlined),
  AdminResource('/attendance', 'الحضور', 'Attendance', Icons.fact_check_outlined),
  AdminResource('/behaviour', 'السلوك', 'Behaviour', Icons.emoji_people_outlined),
  AdminResource('/lessons', 'خطط الدروس', 'Lesson plans', Icons.edit_note_outlined),
  AdminResource('/markbook-entries', 'الدرجات', 'Grades', Icons.grade_outlined),
  AdminResource('/messages', 'الرسائل', 'Messages', Icons.mail_outline),
];

/// A section page: a grid of record types, each opening a full manager.
class AdminSectionPage extends StatelessWidget {
  const AdminSectionPage({super.key, required this.title, required this.resources, required this.repository});

  final String title;
  final List<AdminResource> resources;
  final ConsoleRepository repository;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return WhitePanel(
      title: title,
      child: Column(
        children: resources
            .map((r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(r.icon, color: AppColors.pine),
                  title: Text(r.title(s), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ResourceListScreen(resource: r, api: repository.api),
                  )),
                ))
            .toList(),
      ),
    );
  }
}

String _t(BuildContext c, String ar, String en) => L10n.of(c).isArabic ? ar : en;

String _errorText(BuildContext c, Object e) {
  if (e is TawasulApiException) {
    if (e.statusCode == 403) return _t(c, 'لا تملك صلاحية هذا الإجراء.', 'You do not have permission for this.');
    return e.message;
  }
  return _t(c, 'تعذر الاتصال بالنظام المدرسي.', 'Could not reach the school system.');
}

String _recordLabel(Map<String, dynamic> r) {
  final first = r['firstName'] ?? r['preferredName'];
  final last = r['surname'];
  if (first != null || last != null) return '${first ?? ''} ${last ?? ''}'.trim();
  for (final k in ['name', 'title', 'subject', 'invoiceNumber', 'username', 'nameShort', 'description', 'type']) {
    final v = r[k];
    if (v != null && '$v'.trim().isNotEmpty) return '$v';
  }
  return r.values.isEmpty ? '—' : '${r.values.first}';
}

/// الاختبارات — exam and assessment records.
const examResources = <AdminResource>[
  AdminResource('/external-assessments', 'الاختبارات', 'Exams', Icons.quiz_outlined),
  AdminResource('/external-assessment-fields', 'مواد وحقول الاختبارات', 'Exam fields', Icons.view_list_outlined),
  AdminResource('/external-assessment-students', 'اختبارات الطلاب', 'Student exams', Icons.assignment_ind_outlined),
  AdminResource('/external-assessment-student-entries', 'نتائج الاختبارات', 'Exam results', Icons.fact_check_outlined),
  AdminResource('/internal-assessment-columns', 'التقييمات الداخلية', 'Internal assessments', Icons.assignment_outlined),
  AdminResource('/internal-assessment-entries', 'نتائج التقييمات الداخلية', 'Internal assessment results', Icons.grading_outlined),
];

/// الجداول — the school timetable for the next month only.
class MonthTimetablePage extends StatefulWidget {
  const MonthTimetablePage({super.key, required this.repository});

  final ConsoleRepository repository;

  @override
  State<MonthTimetablePage> createState() => _MonthTimetablePageState();
}

class _MonthTimetablePageState extends State<MonthTimetablePage> {
  late Future<List<_TimetableDay>> _future = _load();

  static String _d(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  Future<List<Map<String, dynamic>>> _all(String path, Map<String, String> query) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 1; page <= 20; page++) {
      final body = await widget.repository.api.getMap(path, query: {'pageSize': '200', 'page': '$page', ...query});
      rows.addAll(TawasulApiClient.extractList(body));
      final meta = body['meta'];
      final pages = meta is Map ? int.tryParse('${meta['totalPages']}') ?? 1 : 1;
      if (page >= pages) break;
    }
    return rows;
  }

  Future<List<_TimetableDay>> _load() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 30));
    final dates = await _all('/timetable-dates', {'dateFrom': _d(from), 'dateTo': _d(to), 'sort': 'date'});
    final slots = await _all('/timetable-slots', {});
    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final s in slots) {
      byDay.putIfAbsent('${s['tawasulTTDayID']}', () => []).add(s);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => '${a['timeStart']}'.compareTo('${b['timeStart']}'));
    }
    return dates
        .map((d) => _TimetableDay('${d['date']}', '${d['dayName'] ?? ''}', byDay['${d['tawasulTTDayID']}'] ?? const []))
        .toList();
  }

  String _hm(Object? t) {
    final s = '${t ?? ''}';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_TimetableDay>>(
      future: _future,
      builder: (context, snap) {
        final s = L10n.of(context);
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text(s.loading, style: const TextStyle(color: AppColors.muted))),
          );
        }
        if (snap.hasError) {
          return WhitePanel(
            title: _t(context, 'الجداول', 'Timetable'),
            child: Column(children: [
              EmptyState(message: _errorText(context, snap.error!)),
              TextButton(
                onPressed: () => setState(() => _future = _load()),
                child: Text(s.retry),
              ),
            ]),
          );
        }
        final days = snap.data!;
        return Column(
          children: [
            WhitePanel(
              title: _t(context, 'الجداول — الشهر القادم', 'Timetable — next month'),
              child: days.isEmpty
                  ? EmptyState(message: _t(context, 'لا توجد أيام دراسية خلال الشهر القادم.', 'No school days in the next month.'))
                  : Text(
                      _t(context, '${days.length} يوم دراسي حتى ${days.last.date}', '${days.length} school days until ${days.last.date}'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
            ),
            ...days.map((day) => WhitePanel(
                  title: '${day.dayName}  ${day.date}',
                  child: day.slots.isEmpty
                      ? EmptyState(message: _t(context, 'لا توجد حصص.', 'No lessons.'))
                      : Column(
                          children: day.slots
                              .map((slot) => RowTile(
                                    leading: '${slot['periodName'] ?? ''}'.isEmpty
                                        ? '•'
                                        : '${slot['periodName']}'.substring(0, 1),
                                    title: '${slot['courseName'] ?? slot['className'] ?? ''}',
                                    subtitle: [
                                      '${slot['classNameShort'] ?? ''}',
                                      if (slot['spaceName'] != null) '${slot['spaceName']}',
                                    ].where((e) => e.isNotEmpty).join(' · '),
                                    trailing: '${_hm(slot['timeStart'])}–${_hm(slot['timeEnd'])}',
                                  ))
                              .toList(),
                        ),
                )),
          ],
        );
      },
    );
  }
}

class _TimetableDay {
  const _TimetableDay(this.date, this.dayName, this.slots);

  final String date;
  final String dayName;
  final List<Map<String, dynamic>> slots;
}
