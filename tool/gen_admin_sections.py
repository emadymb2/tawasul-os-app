"""Generates the admin portal's section menu (admin_sections.dart) and the
field specs for every record type it uses (admin_specs_more.dart) from the
school API description. Run: python3 tool/gen_admin_sections.py openapi.json"""
import json, re, sys, os

# Section -> pages, mirroring the school website's admin menu. Only pages the
# school API serves as records are listed (website-only reports are left out).
S = [
 ('People', 'الأشخاص', 'people_outline', [
   ('Users', 'المستخدمون', ['/users']),
   ('Roles', 'الأدوار', ['/roles']),
   ('Families', 'الأسر', ['/families', '/family-adults', '/family-children', '/family-relationships']),
   ('Students', 'الطلاب', ['/students']),
   ('Staff', 'الموظفون', ['/staff']),
   ('Districts', 'المناطق', ['/districts']),
   ('Personal documents', 'الوثائق الشخصية', ['/personal-documents', '/personal-document-types']),
   ('Username formats', 'صيغ أسماء المستخدمين', ['/username-formats']),
   ('Password resets', 'إعادة تعيين كلمات المرور', ['/person-resets']),
   ('User status log', 'سجل حالات المستخدمين', ['/person-status-logs']),
   ('Data retention', 'الاحتفاظ بالبيانات', ['/data-retentions'])]),
 ('Admissions', 'القبول', 'how_to_reg_outlined', [
   ('Applications', 'طلبات القبول', ['/admissions-applications', '/admissions-accounts'])]),
 ('Students', 'شؤون الطلاب', 'school_outlined', [
   ('First aid', 'الإسعافات الأولية', ['/first-aid', '/first-aid-follow-ups']),
   ('Student notes', 'ملاحظات الطلاب', ['/student-notes', '/student-note-categories']),
   ('Student alerts', 'تنبيهات الطلاب', ['/alerts', '/alert-types', '/alert-levels']),
   ('Individual needs', 'الاحتياجات الفردية', ['/individual-needs', '/individual-needs-descriptors', '/in-investigations', '/in-archives']),
   ('Behaviour', 'السلوك', ['/behaviour', '/behaviour-follow-ups', '/behaviour-letters'])]),
 ('Staff', 'شؤون الموظفين', 'badge_outlined', [
   ('Staff absences', 'غياب الموظفين', ['/staff-absences', '/staff-absence-dates', '/staff-absence-types']),
   ('Coverage', 'التغطية', ['/staff-coverage', '/staff-coverage-dates']),
   ('Substitutes', 'البدلاء', ['/substitutes']),
   ('Staff duty', 'مناوبات الموظفين', ['/staff-duty-persons']),
   ('Job openings', 'الوظائف الشاغرة', ['/staff-job-openings']),
   ('Contracts', 'العقود', ['/staff-contracts'])]),
 ('School admin', 'إدارة المدرسة', 'account_balance_outlined', [
   ('School years', 'السنوات الدراسية', ['/school-years']),
   ('Terms', 'الفصول الدراسية', ['/school-terms']),
   ('Special days', 'الأيام الخاصة', ['/special-days']),
   ('Days of the week', 'أيام الأسبوع', ['/days-of-weeks']),
   ('Year groups', 'المراحل', ['/year-groups']),
   ('Form groups', 'الشعب', ['/form-groups']),
   ('Departments', 'الأقسام', ['/department-resources']),
   ('Houses', 'البيوت', ['/houses']),
   ('Grade scales', 'سلالم الدرجات', ['/grade-scales', '/grade-scale-grades']),
   ('Medical conditions', 'الحالات الطبية', ['/medical-conditions-2']),
   ('File extensions', 'امتدادات الملفات', ['/file-extensions']),
   ('External assessments', 'الاختبارات الخارجية', ['/external-assessments', '/external-assessment-fields'])]),
 ('Timetable', 'الجداول', 'calendar_view_week_outlined', [
   ('Courses & classes', 'المقررات والفصول', ['/courses', '/classes']),
   ('Class enrolment', 'تسجيل الفصول', ['/class-enrolments']),
   ('Timetables', 'الجداول الدراسية', ['/timetables', '/timetable-days', '/timetable-periods', '/tt-columns']),
   ('Timetable dates', 'تواريخ الجدول', ['/timetable-dates']),
   ('Space bookings', 'حجز القاعات', ['/tt-space-bookings']),
   ('Space changes', 'تغيير القاعات', ['/tt-space-changes'])]),
 ('Attendance', 'الحضور', 'fact_check_outlined', [
   ('Attendance records', 'سجلات الحضور', ['/attendance']),
   ('Class attendance log', 'سجل حضور الفصول', ['/attendance-class-logs']),
   ('Form group attendance log', 'سجل حضور الشعب', ['/attendance-form-group-logs'])]),
 ('Learning', 'التعلم', 'menu_book_outlined', [
   ('Lesson plans', 'خطط الدروس', ['/lessons']),
   ('Homework', 'الواجبات', ['/planner-entry-homeworks', '/planner-entry-student-homeworks']),
   ('Units', 'الوحدات', ['/units', '/unit-blocks']),
   ('Outcomes', 'نواتج التعلم', ['/outcomes']),
   ('Resources', 'مصادر التعلم', ['/resources']),
   ('Markbook', 'دفتر الدرجات', ['/markbook-columns', '/markbook-entries', '/markbook-weights', '/markbook-targets']),
   ('Internal assessment', 'التقييم الداخلي', ['/internal-assessment-columns', '/internal-assessment-entries']),
   ('External assessment results', 'نتائج الاختبارات الخارجية', ['/external-assessment-students', '/external-assessment-student-entries']),
   ('Rubrics', 'سلالم التقدير', ['/rubrics', '/rubric-rows', '/rubric-columns', '/rubric-cells'])]),
 ('Activities', 'الأنشطة', 'sports_soccer_outlined', [
   ('Activities', 'الأنشطة', ['/activities', '/activity-slots', '/activity-staff']),
   ('Categories', 'فئات الأنشطة', ['/activity-categories', '/activity-types']),
   ('Enrolment', 'التسجيل في الأنشطة', ['/activity-students', '/activity-choices']),
   ('Attendance', 'حضور الأنشطة', ['/activity-attendances'])]),
 ('Reports', 'التقارير', 'summarize_outlined', [
   ('Reporting cycles', 'دورات التقارير', ['/reporting-cycles', '/reporting-scopes']),
   ('Criteria', 'المعايير', ['/reporting-criterias', '/reporting-criteria-types']),
   ('Access', 'صلاحيات الكتابة', ['/reporting-accesses']),
   ('Written values', 'التقارير المكتوبة', ['/reporting-values', '/reporting-progresses', '/reporting-proofs']),
   ('Report templates', 'قوالب التقارير', ['/reports', '/report-templates']),
   ('Archive', 'الأرشيف', ['/report-archives', '/report-archive-entries'])]),
 ('Finance', 'الماليات', 'payments_outlined', [
   ('Invoices', 'الفواتير', ['/invoices', '/invoice-fees']),
   ('Invoicees', 'مستلمو الفواتير', ['/finance-invoicees']),
   ('Billing schedules', 'جداول الفوترة', ['/finance-billing-schedules']),
   ('Fees', 'الرسوم', ['/fees', '/finance-fee-categories']),
   ('Budgets', 'الميزانيات', ['/budgets', '/finance-budget-cycles', '/finance-budget-cycle-allocations', '/finance-budget-persons']),
   ('Expenses', 'النفقات', ['/expenses', '/finance-expense-approvers', '/finance-expense-logs']),
   ('Petty cash', 'النثريات', ['/finance-petty-cashes'])]),
 ('Library', 'المكتبة', 'local_library_outlined', [
   ('Catalog', 'الفهرس', ['/library-items', '/library-types']),
   ('Lending', 'الإعارة', ['/library-events']),
   ('Shelves', 'الرفوف', ['/library-shelfs', '/library-shelf-items'])]),
 ('Communication', 'التواصل', 'forum_outlined', [
   ('Messages', 'الرسائل', ['/messages', '/message-receipts']),
   ('Scheduled messages', 'الرسائل المجدولة', ['/scheduled-messages']),
   ('Message templates', 'قوالب الرسائل', ['/message-templates']),
   ('Canned responses', 'الردود الجاهزة', ['/messenger-canned-responses']),
   ('Groups', 'المجموعات', ['/groups', '/group-persons']),
   ('Mailing lists', 'القوائم البريدية', ['/messenger-mailing-lists', '/messenger-mailing-list-recipients']),
   ('Notifications', 'الإشعارات', ['/notifications', '/notification-events']),
   ('Calendars', 'التقويمات', ['/calendar-event-types'])]),
 ('Help desk', 'الدعم الفني', 'support_agent_outlined', [
   ('Issues', 'البلاغات', ['/helpdesk-issues', '/helpdesk-issue-discusses']),
   ('Departments', 'أقسام الدعم', ['/helpdesk-departmentses', '/helpdesk-subcategorieses']),
   ('Technicians', 'الفنيون', ['/helpdesk-technicianses', '/helpdesk-tech-groupses']),
   ('Reply templates', 'قوالب الردود', ['/helpdesk-reply-templates'])]),
 ('Other modules', 'وحدات أخرى', 'widgets_outlined', [
   ('Policies', 'السياسات', ['/policies-policies']),
   ('Credentials', 'بيانات الدخول', ['/credentials-credentials', '/credentials-websites']),
   ('Info grid', 'شبكة المعلومات', ['/info-grid-entries']),
   ('Workflows', 'سير العمل', ['/workflow-definitions', '/workflow-instances']),
   ('Visual assessment', 'التقييم المرئي', ['/visual-assessment-guides', '/visual-assessment-terms', '/visual-assessment-attainments']),
   ('Bulk jobs', 'المهام الجماعية', ['/bulk-jobs']),
   ('Data updates', 'تحديثات البيانات', ['/person-updates', '/family-updates', '/person-medical-updates', '/staff-updates', '/finance-invoicee-updates'])]),
 ('System admin', 'إدارة النظام', 'settings_outlined', [
   ('Settings', 'الإعدادات', ['/settings']),
   ('Modules', 'الوحدات', ['/modules']),
   ('Permissions', 'الصلاحيات', ['/permissions']),
   ('Email templates', 'قوالب البريد', ['/email-templates']),
   ('Languages', 'اللغات', ['/i18ns']),
   ('Themes', 'السمات', ['/themes']),
   ('Alarms', 'الإنذار', ['/alarms']),
   ('Form builder', 'منشئ النماذج', ['/forms', '/form-pages']),
   ('Logs', 'السجلات', ['/logs'])]),
]

spec = json.load(open(sys.argv[1]))
paths = spec['paths']
here = os.path.dirname(os.path.abspath(__file__))
screens = os.path.join(here, '..', 'lib', 'screens')
existing_src = open(os.path.join(screens, 'admin_specs.dart')).read()
existing = set(re.findall(r"^  '(/[a-z0-9-]+)': \[", existing_src, re.M))
refmap = dict(re.findall(r"FieldSpec\('(tawasul\w+ID)\w*', 'ref:(/[a-z0-9-]+)'", existing_src))

def singular(p): return re.sub(r'(ies)$', 'y', re.sub(r'(?<!s)s$', '', p))
def ref_for(name):
    m = re.match(r'(tawasul\w+?ID)', name)
    if not m: return None
    base = m.group(1)
    if base.startswith('tawasulPersonID'): return '/users'
    if base in refmap: return refmap[base]
    key = base[6:-2].lower()
    for p in paths:
        seg = p.strip('/').split('/')[0]
        if '{' in p or not seg: continue
        if singular(seg.replace('-', '')) == key or seg.replace('-', '') == key: return '/' + seg
    return None
LONG = re.compile(r'(description|comment|notes?|details|content|body|text|reason|summary|html|reflection)$', re.I)
def kind(name, sch):
    enum = sch.get('enum')
    if enum:
        return ('yn', []) if sorted(enum) == ['N', 'Y'] else ('choice', [str(e) for e in enum])
    r = ref_for(name)
    if r and name.endswith(('ID',)) or (r and re.match(r'tawasul\w+ID', name)): return ('ref:' + r, [])
    t = sch.get('type'); f = sch.get('format', '')
    if f == 'date-time' or re.search(r'(timestamp|DateTime)$', name, re.I): return ('datetime', [])
    if f == 'date' or re.search(r'(^date|Date)(Start|End)?$', name) or name.lower().endswith('date'): return ('date', [])
    if re.search(r'^time|Time(Start|End)?$', name): return ('time', [])
    if 'email' in name.lower(): return ('email', [])
    if 'phone' in name.lower(): return ('phone', [])
    if t in ('integer', 'number'): return ('number', [])
    if LONG.search(name): return ('long', [])
    return ('text', [])

used = []
for _, _, _, pages in S:
    for _, _, rs in pages:
        for r in rs:
            if r not in paths: sys.exit('missing API resource ' + r)
            if r not in used: used.append(r)

def esc(s): return s.replace("\\", "\\\\").replace("'", "\\'").replace('$', '\\$')
out = ["// Generated by tool/gen_admin_sections.py from the school API description. Do not hand-edit.",
       "part of 'admin_manage_pages.dart';", "", "const moreResourceFields = <String, List<FieldSpec>>{"]
for r in used:
    if r in existing: continue
    post = paths[r].get('post')
    if not post: continue
    sch = post.get('requestBody', {}).get('content', {}).get('application/json', {}).get('schema', {})
    req = set(sch.get('required', []))
    out.append(f"  '{r}': [")
    props = sch.get('properties') or {}
    if not isinstance(props, dict): props = {}
    for n, p in props.items():
        k, opts = kind(n, p)
        o = ', '.join("'" + esc(x) + "'" for x in opts)
        out.append(f"    FieldSpec('{esc(n)}', '{k}', required: {'true' if n in req else 'false'}, options: [{o}], maxLength: {int(p.get('maxLength', 0) or 0)}),")
    out.append("  ],")
out.append("};")
open(os.path.join(screens, 'admin_specs_more.dart'), 'w').write('\n'.join(out) + '\n')

icons = {'/users': 'person_outline'}
o = ["// Generated by tool/gen_admin_sections.py. Admin menu sections mirroring the school website.",
     "part of 'admin_manage_pages.dart';", "", "const adminSections = <AdminSection>["]
for en, ar, ic, pages in S:
    o.append(f"  AdminSection('{esc(ar)}', '{esc(en)}', Icons.{ic}, [")
    for pen, par, rs in pages:
        o.append(f"    AdminPageSpec('{esc(par)}', '{esc(pen)}', {rs!r}),".replace('[', "<String>[", 1).replace('"', "'"))
    o.append("  ]),")
o.append("];")
open(os.path.join(screens, 'admin_sections.dart'), 'w').write('\n'.join(o) + '\n')
print(len(S), 'sections', sum(len(p) for *_, p in S), 'pages', len(used), 'resources')
