import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/l10n.dart';
import '../data/console_repository.dart';
import '../theme/app_theme.dart';
import 'admin_manage_pages.dart';

// ================================================================ shared ===

// A slim wrapper that turns [AdminResource] into a [ResourceListScreen].
// Each section screen uses this for its resource list pages.
class ResourceListScreenBody extends StatelessWidget {
  const ResourceListScreenBody({super.key, required this.resource, required this.api});

  final AdminResource resource;
  final TawasulApiClient api;

  @override
  Widget build(BuildContext context) {
    return ResourceListScreen(resource: resource, api: api);
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, required this.onTap, this.iconColor = AppColors.pine});

  final AdminResource resource;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(resource.icon, color: iconColor),
        title: Text(resource.title(s), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}

// ================================================================ People —===

class PeopleSectionScreen extends StatefulWidget {
  const PeopleSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  @override
  State<PeopleSectionScreen> createState() => _PeopleSectionScreenState();
}

class _PeopleSectionScreenState extends State<PeopleSectionScreen> {
  String _tab = 'users';

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final api = widget.repository.api;
    return Directionality(
      textDirection: s.direction,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          title: Text(s.isArabic ? 'الأشخاص' : 'People'),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(spacing: 8, children: [
              _pillTab(s.isArabic ? 'المستخدمون' : 'Users', 'users'),
              _pillTab(s.isArabic ? 'الأدوار' : 'Roles', 'roles'),
              _pillTab(s.isArabic ? 'الأسر' : 'Families', 'families'),
              _pillTab(s.isArabic ? 'الطلاب' : 'Students', 'students'),
              _pillTab(s.isArabic ? 'الموظفون' : 'Staff', 'staff'),
              _pillTab(s.isArabic ? 'المناطق' : 'Districts', 'districts'),
            ]),
          ),
          Expanded(
            child: _peopleContent(_tab, api),
          ),
        ]),
      ),
    );
  }

  Widget _peopleContent(String tab, TawasulApiClient api) {
    switch (tab) {
      case 'users':
        return ResourceListScreenBody(
          resource: const AdminResource('/users', 'المستخدمون', 'Users', Icons.person_outline),
          api: api,
        );
      case 'roles':
        return ResourceListScreenBody(
          resource: const AdminResource('/roles', 'الأدوار', 'Roles', Icons.badge_outlined),
          api: api,
        );
      case 'families':
        return ResourceListScreenBody(
          resource: const AdminResource('/families', 'الأسر', 'Families', Icons.family_restroom_outlined),
          api: api,
        );
      case 'students':
        return ResourceListScreenBody(
          resource: const AdminResource('/students', 'الطلاب', 'Students', Icons.school_outlined),
          api: api,
        );
      case 'staff':
        return ResourceListScreenBody(
          resource: const AdminResource('/staff', 'الموظفون', 'Staff', Icons.badge_outlined),
          api: api,
        );
      case 'districts':
        return ResourceListScreenBody(
          resource: const AdminResource('/districts', 'المناطق', 'Districts', Icons.location_city_outlined),
          api: api,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _pillTab(String label, String value) => Material(
        borderRadius: BorderRadius.circular(16),
        color: value == _tab ? AppColors.pine : AppColors.cream,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _tab = value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: value == _tab ? FontWeight.w800 : FontWeight.w600,
              color: value == _tab ? Colors.white : AppColors.ink,
            )),
          ),
        ),
      );
}

// ================================================================ Admissions ===

class AdmissionsSectionScreen extends StatelessWidget {
  const AdmissionsSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.pine,
        title: Text(s.isArabic ? 'القبول' : 'Admissions'),
      ),
      body: ResourceListScreenBody(
        resource: const AdminResource('/admissions-applications', 'طلبات القبول', 'Applications', Icons.how_to_reg_outlined),
        api: repository.api,
      ),
    );
  }
}

// ================================================================ Students —===

class StudentsSectionScreen extends StatelessWidget {
  const StudentsSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/student-notes', 'ملاحظات الطلاب', 'Student notes', Icons.note_outlined),
    AdminResource('/student-note-categories', 'فئات الملاحظات', 'Note categories', Icons.category_outlined),
    AdminResource('/alerts', 'تنبيهات الطلاب', 'Student alerts', Icons.warning_outlined),
    AdminResource('/alert-types', 'أنواع التنبيهات', 'Alert types', Icons.category_outlined),
    AdminResource('/alert-levels', 'مستويات التنبيهات', 'Alert levels', Icons.scale_outlined),
    AdminResource('/individual-needs', 'الاحتياجات الفردية', 'Individual needs', Icons.favorite_outline),
    AdminResource('/individual-needs-descriptors', 'وصف الاحتياجات', 'Need descriptors', Icons.description_outlined),
    AdminResource('/in-investigations', 'التحقيقات', 'Investigations', Icons.search_outlined),
    AdminResource('/in-archives', 'أرشيفات', 'Archives', Icons.archive_outlined),
    AdminResource('/behaviour', 'السلوك', 'Behaviour', Icons.emoji_people_outlined),
    AdminResource('/behaviour-follow-ups', 'متابعات السلوك', 'Behaviour follow-ups', Icons.follow_the_signs_outlined),
    AdminResource('/behaviour-letters', 'رسائل السلوك', 'Behaviour letters', Icons.message_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.pine,
        title: Text(s.isArabic ? 'شؤون الطلاب' : 'Students'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Staff —===

class StaffSectionScreen extends StatelessWidget {
  const StaffSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/staff-absences', 'غياب الموظفين', 'Staff absences', Icons.badge_outlined),
    AdminResource('/staff-absence-dates', 'تواريخ الغياب', 'Absence dates', Icons.calendar_today_outlined),
    AdminResource('/staff-absence-types', 'أنواع الغياب', 'Absence types', Icons.category_outlined),
    AdminResource('/staff-coverage', 'التغطية', 'Coverage', Icons.groups_2_outlined),
    AdminResource('/staff-coverage-dates', 'تواريخ التغطية', 'Coverage dates', Icons.calendar_today_outlined),
    AdminResource('/substitutes', 'البدلاء', 'Substitutes', Icons.person_outline),
    AdminResource('/staff-duty-persons', 'مناشط الموظفين', 'Staff duty', Icons.access_time_outlined),
    AdminResource('/staff-job-openings', 'الوظائق الشاغرة', 'Job openings', Icons.work_history),
    AdminResource('/staff-contracts', 'العقود', 'Contracts', Icons.description_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'شؤون الموظفين' : 'Staff'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ School admin ===

class SchoolAdminSectionScreen extends StatelessWidget {
  const SchoolAdminSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/school-years', 'السنوات الدراسية', 'School years', Icons.calendar_today_outlined),
    AdminResource('/school-terms', 'الفصول الدراسية', 'Terms', Icons.book_outlined),
    AdminResource('/special-days', 'الأيام الخاصة', 'Special days', Icons.celebration_outlined),
    AdminResource('/days-of-weeks', 'أيام الأسبوع', 'Days of the week', Icons.calendar_view_week_outlined),
    AdminResource('/year-groups', 'المراحل', 'Year groups', Icons.groups_2_outlined),
    AdminResource('/form-groups', 'الشعب', 'Form groups', Icons.view_list_outlined),
    AdminResource('/department-resources', 'الأقسام', 'Departments', Icons.business_outlined),
    AdminResource('/houses', 'البيوت', 'Houses', Icons.home_outlined),
    AdminResource('/grade-scales', 'سلالم الدرجات', 'Grade scales', Icons.grade_outlined),
    AdminResource('/medical-conditions-2', 'الحالات الطبية', 'Medical conditions', Icons.medical_information),
    AdminResource('/file-extensions', 'امتدادات الملفات', 'File extensions', Icons.file_present_outlined),
    AdminResource('/external-assessments', 'الاختبارات الخارجية', 'External assessments', Icons.quiz_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'إدارة المدرسة' : 'School admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Timetable ===

class TimetableSectionScreen extends StatelessWidget {
  const TimetableSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/courses', 'المقررات', 'Courses', Icons.menu_book_outlined),
    AdminResource('/classes', 'الفصول', 'Classes', Icons.class_outlined),
    AdminResource('/class-enrolments', 'تسجيل الطلاب', 'Class enrolments', Icons.how_to_reg_outlined),
    AdminResource('/timetables', 'الجداول الدراسية', 'Timetables', Icons.calendar_view_week_outlined),
    AdminResource('/timetable-days', 'أيام الجدول', 'Timetable days', Icons.calendar_today_outlined),
    AdminResource('/timetable-periods', 'فترات الجدول', 'Periods', Icons.access_time_outlined),
    AdminResource('/tt-columns', 'أعمدة الجدول', 'Columns', Icons.view_column_outlined),
    AdminResource('/timetable-dates', 'تواريخ الجدول', 'Timetable dates', Icons.event_outlined),
    AdminResource('/tt-space-bookings', 'حجز القاعات', 'Space bookings', Icons.event_seat_outlined),
    AdminResource('/tt-space-changes', 'تغيير القاعات', 'Space changes', Icons.room_preferences_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final api = repository.api;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.pine,
        title: Text(s.isArabic ? 'الجداول' : 'Timetable'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Attendance ===

class AttendanceSectionScreen extends StatelessWidget {
  const AttendanceSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/attendance', 'سجلات الحضور', 'Attendance records', Icons.fact_check_outlined),
    AdminResource('/attendance-class-logs', 'سجل حضور الفصول', 'Class attendance log', Icons.list_alt_outlined),
    AdminResource('/attendance-form-group-logs', 'سجل حضور الشعب', 'Form group attendance log', Icons.list_alt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'الحضور' : 'Attendance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Learning —===

class LearningSectionScreen extends StatelessWidget {
  const LearningSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/lessons', 'خطط الدروس', 'Lesson plans', Icons.edit_note_outlined),
    AdminResource('/planner-entry-homeworks', 'الواجدات', 'Homework', Icons.menu_book_outlined),
    AdminResource('/planner-entry-student-homeworks', 'واجدات الطلاب', 'Student homework', Icons.assignment_outlined),
    AdminResource('/units', 'الوحدات', 'Units', Icons.view_quilt_outlined),
    AdminResource('/unit-blocks', 'كتل الوحدات', 'Unit blocks', Icons.view_stream_outlined),
    AdminResource('/outcomes', 'نواتج التعلم', 'Learning outcomes', Icons.track_changes_outlined),
    AdminResource('/resources', 'مصادر التعلم', 'Learning resources', Icons.folder_open_outlined),
    AdminResource('/markbook-columns', 'دفاتر الدرجات', 'Markbook', Icons.book_outlined),
    AdminResource('/markbook-entries', 'درجات الطلاب', 'Grade entries', Icons.grade_outlined),
    AdminResource('/markbook-weights', 'أوزان الدرجات', 'Grade weights', Icons.scale_outlined),
    AdminResource('/markbook-targets', 'أهداف الدرجات', 'Grade targets', Icons.track_changes_outlined),
    AdminResource('/internal-assessment-columns', 'التقييمات الداخلية', 'Internal assessments', Icons.assignment_outlined),
    AdminResource('/internal-assessment-entries', 'نتائج التقييمات', 'Assessment results', Icons.fact_check_outlined),
    AdminResource('/external-assessment-students', 'اختبارات الطلاب', 'Student exams', Icons.assignment_ind_outlined),
    AdminResource('/external-assessment-student-entries', 'نتائج الاختبارات', 'Exam results', Icons.fact_check_outlined),
    AdminResource('/rubrics', 'سلالم التقدير', 'Rubrics', Icons.view_day_outlined),
    AdminResource('/rubric-rows', 'صفوف التقدير', 'Rubric rows', Icons.view_module_outlined),
    AdminResource('/rubric-columns', 'أعمدة التقدير', 'Rubric columns', Icons.view_module_outlined),
    AdminResource('/rubric-cells', 'خلايا التقدير', 'Rubric cells', Icons.grid_view_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'التعلم' : 'Learning'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  iconColor: AppColors.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Activities ===

class ActivitiesSectionScreen extends StatelessWidget {
  const ActivitiesSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/activities', 'الأنشطة', 'Activities', Icons.sports_soccer_outlined),
    AdminResource('/activity-slots', 'فتحات الأنشطة', 'Activity slots', Icons.access_time_outlined),
    AdminResource('/activity-staff', 'مشرفو الأنشطة', 'Activity staff', Icons.badge_outlined),
    AdminResource('/activity-categories', 'فئات الأنشطة', 'Categories', Icons.category_outlined),
    AdminResource('/activity-types', 'أنواع الأنشطة', 'Types', Icons.category_outlined),
    AdminResource('/activity-students', 'تسجيل في الأنشطة', 'Enrolment', Icons.how_to_reg_outlined),
    AdminResource('/activity-choices', 'اختيارات الأنشطة', 'Choices', Icons.check_circle_outlined),
    AdminResource('/activity-attendances', 'حضور الأنشطة', 'Attendance', Icons.fact_check_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'الأنشطة' : 'Activities'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  iconColor: AppColors.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Reports —===

class ReportsSectionScreen extends StatelessWidget {
  const ReportsSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/reporting-cycles', 'دورات التقارير', 'Reporting cycles', Icons.calendar_month_outlined),
    AdminResource('/reporting-scopes', 'نطاقات التقارير', 'Reporting scopes', Icons.view_day_outlined),
    AdminResource('/reporting-criterias', 'المعايير', 'Criteria', Icons.rule_outlined),
    AdminResource('/reporting-criteria-types', 'أنواع المعايير', 'Criteria types', Icons.rule_outlined),
    AdminResource('/reporting-accesses', 'صلاحيات الكتابة', 'Access', Icons.lock_outlined),
    AdminResource('/reporting-values', 'التقارير المكتوبة', 'Written values', Icons.edit_note_outlined),
    AdminResource('/reporting-progresses', 'تقدم التقارير', 'Progress', Icons.trending_up_outlined),
    AdminResource('/reporting-proofs', 'دلائل التقارير', 'Report proofs', Icons.attach_file_outlined),
    AdminResource('/reports', 'قوالب التقارير', 'Report templates', Icons.description_outlined),
    AdminResource('/report-templates', 'قوالب تقرير', 'Report templates', Icons.description_outlined),
    AdminResource('/report-archives', 'الأرشيف', 'Archive', Icons.archive_outlined),
    AdminResource('/report-archive-entries', 'مدخلات الأرشيف', 'Archive entries', Icons.archive_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'التقارير' : 'Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  iconColor: AppColors.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Finance —===

class FinanceSectionScreen extends StatelessWidget {
  const FinanceSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/invoices', 'الفواتير', 'Invoices', Icons.receipt_long_outlined),
    AdminResource('/invoice-fees', 'بنود الفواتير', 'Invoice fees', Icons.list_alt_outlined),
    AdminResource('/finance-invoicees', 'مستلمو الفواتير', 'Invoicees', Icons.person_pin_outlined),
    AdminResource('/finance-billing-schedules', 'جداول الفوترة', 'Billing schedules', Icons.event_note_outlined),
    AdminResource('/fees', 'الرسوم', 'Fees', Icons.payments_outlined),
    AdminResource('/finance-fee-categories', 'فئات الرسوم', 'Fee categories', Icons.category_outlined),
    AdminResource('/budgets', 'الميزانيات', 'Budgets', Icons.account_balance_wallet_outlined),
    AdminResource('/finance-budget-cycles', 'دورات الميزانية', 'Budget cycles', Icons.autorenew_outlined),
    AdminResource('/finance-budget-cycle-allocations', 'مخصصات الميزانية', 'Budget allocations', Icons.pie_chart),
    AdminResource('/finance-budget-persons', 'أعضاء الميزانيات', 'Budget members', Icons.group_outlined),
    AdminResource('/expenses', 'النفقات', 'Expenses', Icons.shopping_cart_outlined),
    AdminResource('/finance-expense-approvers', 'موافقون على النفقات', 'Expense approvers', Icons.verified_outlined),
    AdminResource('/finance-expense-logs', 'سجل النفقات', 'Expense log', Icons.receipt_outlined),
    AdminResource('/finance-petty-cashes', 'النثريات', 'Petty cash', Icons.savings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.pine,
        title: Text(s.isArabic ? 'الماليات' : 'Finance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  iconColor: AppColors.pine,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Library —===

class LibrarySectionScreen extends StatelessWidget {
  const LibrarySectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/library-items', 'الفهرس', 'Catalog', Icons.menu_book_outlined),
    AdminResource('/library-types', 'أنواع المكتبة', 'Library types', Icons.category_outlined),
    AdminResource('/library-events', 'الإعارة', 'Lending', Icons.library_books_outlined),
    AdminResource('/library-shelfs', 'الرفوف', 'Shelves', Icons.view_stream_outlined),
    AdminResource('/library-shelf-items', 'كتب الرفوف', 'Shelf items', Icons.book_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'المكتبة' : 'Library'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  iconColor: AppColors.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Communication ===

class CommunicationSectionScreen extends StatelessWidget {
  const CommunicationSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/messages', 'الرسائل', 'Messages', Icons.mail_outline),
    AdminResource('/message-receipts', 'استعلامات الرسائل', 'Message receipts', Icons.email_outlined),
    AdminResource('/scheduled-messages', 'الرسائل المجدولة', 'Scheduled messages', Icons.schedule_outlined),
    AdminResource('/message-templates', 'قوالب الرسائل', 'Message templates', Icons.article_outlined),
    AdminResource('/messenger-canned-responses', 'الردود الجاهزة', 'Canned responses', Icons.chat_outlined),
    AdminResource('/groups', 'المجموعات', 'Groups', Icons.groups_outlined),
    AdminResource('/group-persons', 'أعضاء المجموعات', 'Group members', Icons.person_outline),
    AdminResource('/messenger-mailing-lists', 'القوائم البريدية', 'Mailing lists', Icons.email_outlined),
    AdminResource('/messenger-mailing-list-recipients', 'مستلمو القوائم', 'List recipients', Icons.person_outline),
    AdminResource('/notifications', 'الإشعارات', 'Notifications', Icons.notifications_outlined),
    AdminResource('/notification-events', 'أحداث الإشعارات', 'Notification events', Icons.event_outlined),
    AdminResource('/calendar-event-types', 'التقايمات', 'Calendars', Icons.calendar_today_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'التواصل' : 'Communication'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  iconColor: AppColors.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Help desk ===

class HelpDeskSectionScreen extends StatelessWidget {
  const HelpDeskSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/helpdesk-issues', 'البلاغات', 'Issues', Icons.report_problem_outlined),
    AdminResource('/helpdesk-issue-discusses', 'مناقشات البلاغات', 'Issue discussions', Icons.forum_outlined),
    AdminResource('/helpdesk-departmentses', 'أقسام الدعم', 'Departments', Icons.business_outlined),
    AdminResource('/helpdesk-subcategorieses', 'الفئات الفرعية', 'Sub-categories', Icons.category_outlined),
    AdminResource('/helpdesk-technicianses', 'الفنيون', 'Technicians', Icons.engineering_outlined),
    AdminResource('/helpdesk-tech-groupses', 'مجموعات الفنيين', 'Tech groups', Icons.groups_outlined),
    AdminResource('/helpdesk-reply-templates', 'قوالب الردود', 'Reply templates', Icons.message_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.pine,
        title: Text(s.isArabic ? 'الدعم الفني' : 'Help desk'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  iconColor: AppColors.pine,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Other modules ===

class OtherModulesSectionScreen extends StatelessWidget {
  const OtherModulesSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/policies-policies', 'السياسات', 'Policies', Icons.description_outlined),
    AdminResource('/credentials-credentials', 'بيانات الدخول', 'Credentials', Icons.lock_outline),
    AdminResource('/credentials-websites', 'مواقع البيانات', 'Credential websites', Icons.public),
    AdminResource('/info-grid-entries', 'شبكة المعلومات', 'Info grid', Icons.grid_view_outlined),
    AdminResource('/workflow-definitions', 'تعريفات سير الأعمال', 'Workflow definitions', Icons.account_tree_outlined),
    AdminResource('/workflow-instances', 'مثيلات سير الأعمال', 'Workflow instances', Icons.account_tree_outlined),
    AdminResource('/visual-assessment-guides', 'دلائل التقييم المرئي', 'Visual assessment guides', Icons.visibility),
    AdminResource('/visual-assessment-terms', 'مصطلحات التقييم المرئي', 'Visual assessment terms', Icons.assessment_outlined),
    AdminResource('/visual-assessment-attainments', 'منجزات التقييم المرئي', 'Visual assessment attainments', Icons.check_circle_outlined),
    AdminResource('/bulk-jobs', 'المهام الجماعية', 'Bulk jobs', Icons.work_history),
    AdminResource('/person-updates', 'تحديثات البيانات', 'Data updates', Icons.update_outlined),
    AdminResource('/family-updates', 'تحديثات الأسر', 'Family updates', Icons.update_outlined),
    AdminResource('/person-medical-updates', 'تحديثات طبية', 'Medical updates', Icons.info_outline),
    AdminResource('/staff-updates', 'تحديثات الموظفين', 'Staff updates', Icons.update_outlined),
    AdminResource('/finance-invoicee-updates', 'تحديثات فواتيد', 'Invoice updates', Icons.update_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'وحدات أخرى' : 'Other modules'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  iconColor: AppColors.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ System admin ===

class SystemAdminSectionScreen extends StatelessWidget {
  const SystemAdminSectionScreen({super.key, required this.repository});

  final ConsoleRepository repository;

  static const resources = <AdminResource>[
    AdminResource('/settings', 'الإعدادات', 'Settings', Icons.settings_outlined),
    AdminResource('/modules', 'الوحدات', 'Modules', Icons.widgets_outlined),
    AdminResource('/permissions', 'الصلاحيات', 'Permissions', Icons.lock_outlined),
    AdminResource('/email-templates', 'قوالب البريد', 'Email templates', Icons.email_outlined),
    AdminResource('/i18ns', 'اللغات', 'Languages', Icons.language),
    AdminResource('/themes', 'السمات', 'Themes', Icons.palette_outlined),
    AdminResource('/alarms', 'الإنذار', 'Alarms', Icons.notifications_outlined),
    AdminResource('/forms', 'منشئ النماذج', 'Form builder', Icons.description_outlined),
    AdminResource('/form-pages', 'صفحات النماذج', 'Form pages', Icons.article_outlined),
    AdminResource('/logs', 'السجلات', 'Logs', Icons.list_alt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        title: Text(s.isArabic ? 'إدارة النظام' : 'System admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: resources
            .map((r) => _ResourceCard(
                  resource: r,
                  iconColor: AppColors.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(
                        backgroundColor: AppColors.pine,
                        foregroundColor: Colors.white,
                        title: Text(r.title(s)),
                      ),
                      body: ResourceListScreenBody(resource: r, api: repository.api),
                    )),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ================================================================ Timetable page ===

class AdminTimetablePage extends StatelessWidget {
  const AdminTimetablePage({super.key, required this.repository});

  final ConsoleRepository repository;

  @override
  Widget build(BuildContext context) {
    return MonthTimetablePage(repository: repository);
  }
}

// ================================================================ Page-level lookup ===

// Dedicated screens for individual pages that warrant custom UI.
final Map<String, Widget Function(ConsoleRepository repository, IconData icon)> adminPageScreens = {
  '/users': (repo, icon) => UsersAdminScreen(api: repo.api),
  '/roles': (repo, icon) => RolesAdminScreen(api: repo.api),
  '/username-formats': (repo, icon) => UsernameFormatsScreen(api: repo.api),
  '/person-resets': (repo, icon) => PasswordResetsScreen(api: repo.api),
  '/person-status-logs': (repo, icon) => StatusLogScreen(api: repo.api),
  '/timetable-dates': (repo, icon) => MonthTimetablePage(repository: repo),
};

// Section-level screens: one per section in admin_sections.dart
final List<Widget Function(ConsoleRepository repository)> adminSectionScreens = [
  (repo) => PeopleSectionScreen(repository: repo),
  (repo) => AdmissionsSectionScreen(repository: repo),
  (repo) => StudentsSectionScreen(repository: repo),
  (repo) => StaffSectionScreen(repository: repo),
  (repo) => SchoolAdminSectionScreen(repository: repo),
  (repo) => TimetableSectionScreen(repository: repo),
  (repo) => AttendanceSectionScreen(repository: repo),
  (repo) => LearningSectionScreen(repository: repo),
  (repo) => ActivitiesSectionScreen(repository: repo),
  (repo) => ReportsSectionScreen(repository: repo),
  (repo) => FinanceSectionScreen(repository: repo),
  (repo) => LibrarySectionScreen(repository: repo),
  (repo) => CommunicationSectionScreen(repository: repo),
  (repo) => HelpDeskSectionScreen(repository: repo),
  (repo) => OtherModulesSectionScreen(repository: repo),
  (repo) => SystemAdminSectionScreen(repository: repo),
];
