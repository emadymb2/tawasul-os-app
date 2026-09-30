import 'package:flutter/widgets.dart';

/// Arabic is the school's language and the app default; English is optional.
class L10n {
  const L10n(this.languageCode);

  final String languageCode;

  bool get isArabic => languageCode == 'ar';

  TextDirection get direction => isArabic ? TextDirection.rtl : TextDirection.ltr;

  String _t(String ar, String en) => isArabic ? ar : en;

  static L10n of(BuildContext context) => LocaleScope.of(context).strings;

  // Teacher extra pages (mirroring the teacher menu on the school website)
  String get more => _t('المزيد', 'More');
  String get morePages => _t('صفحات أخرى', 'More pages');
  String get messengerGroups => _t('مجموعات المرسال', 'Messenger groups');
  String get investigations => _t('تحقيقات الاحتياجات الفردية', 'Individual needs investigations');
  String get myExpenses => _t('نفقاتي', 'My expenses');
  String get activityAttendance => _t('حضور الأنشطة', 'Activity attendance');
  String get externalAssessments => _t('التقييم الخارجي', 'External assessments');
  String get library => _t('المكتبة', 'Library');
  String get crowdAssessment => _t('التقييم الجماعي', 'Crowd assessment');
  String get noPermission => _t('ليس لديك صلاحية لعرض هذه الصفحة', "You don't have permission to view this page");
  String get back => _t('رجوع', 'Back');

  // E-books
  String get ebooks => _t('المكتبة الإلكترونية', 'E-book library');
  String get searchBooks => _t('ابحث عن كتاب', 'Search books');
  String get noBooks => _t('لا توجد كتب إلكترونية بعد', 'No e-books yet');
  String get whyNoBooks => _t('لماذا لا تظهر الكتب؟', 'Why are there no books?');
  String get reasonCatalogueEmpty => _t(
      'لا توجد أي كتب مسجلة في مكتبة المدرسة ولا في مصادر المدرسة. أضف الكتاب من: المكتبة ← إدارة الفهرس ← نوع «منشور رقمي»، وضع رابط ملف PDF في حقل «URL Link».',
      'The school Library and Resources have no records. Add each book in Library › Manage Catalog as a “Digital Publication” and put the PDF address in its “URL Link” field.');
  String get reasonNoPdfLinks => _t(
      'توجد سجلات في المكتبة لكن لا يحتوي أي منها على رابط ملف PDF. افتح الكتاب في إدارة الفهرس وضع رابط الملف في حقل «URL Link».',
      'There are Library records, but none contains a PDF link. Open each book in Manage Catalog and put the file address in its “URL Link” field.');
  String get reasonNoPermission => _t(
      'دورك لا يملك صلاحية عرض مكتبة المدرسة. اطلب من إدارة المدرسة منح صلاحية «تصفح المكتبة».',
      "Your role isn't allowed to view the school Library. Ask the school to grant “Browse The Library”.");
  String get reasonFileTransferOff => _t(
      'الكتاب محفوظ كملف مرفق، ونقل الملفات عبر واجهة الربط مغلق في نظام المدرسة. فعّله من إعدادات واجهة الربط، أو ضع رابط الملف في حقل «URL Link».',
      'This book is an attached file, and file transfer through the school connection is switched off. Turn it on in the connection settings, or put the file address in “URL Link”.');
  String continueFrom(int page) => _t('متابعة من صفحة $page', 'Continue from page $page');
  String resumedAt(int page) => _t('تابعت من صفحة $page', 'Resumed at page $page');
  String get bookmarks => _t('الإشارات المرجعية', 'Bookmarks');
  String get addBookmark => _t('إضافة إشارة لهذه الصفحة', 'Bookmark this page');
  String get removeBookmark => _t('إزالة الإشارة', 'Remove bookmark');
  String get noBookmarks => _t('لا توجد إشارات بعد — اضغط على رمز الإشارة لحفظ الصفحة', 'No bookmarks yet — tap the bookmark icon to save a page');
  String pageNumber(int page) => _t('صفحة $page', 'Page $page');
  String get openingBook => _t('جاري فتح الكتاب...', 'Opening the book...');
  String get bookFailed => _t('تعذر فتح الكتاب', "Couldn't open this book");
  String pageOf(int page, int total) => _t('صفحة $page من $total', 'Page $page of $total');

  // Menu, profile and account settings
  String get menu => _t('القائمة', 'Menu');
  String get profile => _t('الملف الشخصي', 'Profile');
  String get accountSettings => _t('إعدادات الحساب', 'Account settings');
  String get personalInfo => _t('البيانات الشخصية', 'Personal details');
  String get fullName => _t('الاسم', 'Name');
  String get officialName => _t('الاسم الرسمي', 'Official name');
  String get roleLabel => _t('الدور', 'Role');
  String get email => _t('البريد الإلكتروني', 'Email');
  String get phone => _t('الهاتف', 'Phone');
  String get gender => _t('الجنس', 'Gender');
  String get dob => _t('تاريخ الميلاد', 'Date of birth');
  String get accountStatus => _t('حالة الحساب', 'Account status');
  String get lastLogin => _t('آخر دخول', 'Last sign-in');
  String get schoolInfo => _t('البيانات المدرسية', 'School details');
  String get yearGroup => _t('الصف', 'Year group');
  String get formGroup => _t('الشعبة', 'Form group');
  String get studentIdLabel => _t('رقم الطالب', 'Student ID');
  String get staffInfo => _t('بيانات الموظف', 'Staff details');
  String get staffType => _t('نوع الوظيفة', 'Staff type');
  String get jobTitle => _t('المسمى الوظيفي', 'Job title');
  String get familyInfo => _t('الأسرة', 'Family');
  String get familyName => _t('اسم الأسرة', 'Family name');
  String get contactDetails => _t('بيانات التواصل', 'Contact details');
  String get contactPreferences => _t('تفضيلات التواصل من المدرسة', 'How the school contacts you');
  String get contactByCall => _t('اتصال هاتفي', 'Phone call');
  String get contactBySms => _t('رسائل SMS', 'SMS');
  String get contactByEmail => _t('بريد إلكتروني', 'Email');
  String get appLanguage => _t('لغة التطبيق', 'App language');
  String get arabic => _t('العربية', 'Arabic');
  String get english => _t('English', 'English');
  String get saveFailed => _t('تعذر الحفظ — قد لا يسمح دورك بتعديل هذه البيانات', "Couldn't save — your role may not be allowed to change this");
  String get clearOfflineData => _t('مسح البيانات المحفوظة على الجهاز', 'Clear data saved on this device');
  String get cleared => _t('تم المسح', 'Cleared');
  String get username2 => _t('اسم المستخدم', 'Username');

  // Shell
  String get appName => _t('تواصل', 'Tawasul');
  String get appTagline => _t('نظام المدرسة', 'SCHOOL OS');
  String get language => _t('English', 'العربية');
  String get signIn => _t('تسجيل الدخول', 'Sign in');
  String get signOut => _t('تسجيل الخروج', 'Sign out');
  String get username => _t('اسم المستخدم أو البريد', 'Username or email');
  String get password => _t('كلمة المرور', 'Password');
  String get signInSubtitle => _t('ادخل ببيانات حسابك في المدرسة', 'Use your school Tawasul username and password.');
  String get loginHeadline => _t('مساحة هادئة واحدة للمدرسة كلها.', 'One calm workspace for the whole school.');
  String get loginSubhead => _t('الجداول والحضور والدرجات والإشعارات — بحساب تواصل الذي منحتك إياه المدرسة.', 'Timetables, attendance, grades and notices — signed in with the Tawasul account the school already gave you.');
  String get signInHint => _t('استخدم اسم المستخدم وكلمة المرور الحاليين في تواصل.', 'Use your existing Tawasul username and password.');
  String get signingIn => _t('جاري الدخول...', 'Signing in...');
  String get wrongCredentials => _t('اسم المستخدم أو كلمة المرور غير صحيحة', 'Wrong username or password');
  String get loginDisabled => _t('الدخول بكلمة المرور غير مفعل أو الحساب موقوف', 'Password sign-in is disabled or the account is locked');
  String get tooManyAttempts => _t('محاولات كثيرة، حاول لاحقاً', 'Too many attempts, try again later');
  String get networkError => _t('تعذر الاتصال بالمدرسة', 'Could not reach the school system');
  String get fillBothFields => _t('أدخل اسم المستخدم وكلمة المرور', 'Enter your username and password');

  // States
  String get loading => _t('جاري التحميل...', 'Loading...');
  String get offlineBanner => _t('وضع عدم الاتصال · بيانات محفوظة', 'Offline · showing saved data');
  String pendingDrafts(int count) => _t('$count بانتظار الإرسال', '$count waiting to sync');
  String get noData => _t('لا توجد بيانات بعد', 'No data yet');
  String get retry => _t('إعادة المحاولة', 'Retry');
  String get refresh => _t('تحديث', 'Refresh');
  String get saved => _t('تم الحفظ', 'Saved');
  String get savedOffline => _t('حُفظ محلياً وسيُرسل عند عودة الاتصال', 'Saved on the device and will sync when back online');
  String get save => _t('حفظ', 'Save');
  String get publish => _t('نشر', 'Publish');

  // Roles / portals
  String get teacherPortal => _t('بوابة المعلم', 'Teacher portal');
  String get parentPortal => _t('بوابة ولي الأمر', 'Parent portal');
  String get staffPortal => _t('بوابة الموظف', 'Staff portal');
  String get adminPortal => _t('بوابة الإدارة', 'Admin portal');
  String get studentPortal => _t('بوابة الطالب', 'Student portal');
  String get welcome => _t('أهلاً', 'Welcome');

  // Tabs / sections
  String get dashboard => _t('الرئيسية', 'Dashboard');
  String get timetable => _t('الجدول', 'Timetable');
  String get todaysLessons => _t('حصص اليوم', "Today's lessons");
  String get lessons => _t('الحصص', 'Lessons');
  String get lessonSummary => _t('ملخص الدرس', 'Lesson summary');
  String get attendance => _t('الحضور', 'Attendance');
  String get attendanceRate => _t('نسبة الحضور', 'Attendance rate');
  String get homework => _t('الواجبات', 'Homework');
  String get students => _t('الطلاب', 'Students');
  String get classRoster => _t('كشف الصف', 'Class roster');
  String get markbook => _t('الدرجات', 'Markbook');
  String get grades => _t('الدرجات', 'Grades');
  String get notices => _t('إشعارات المدرسة', 'School notices');
  String get myChildren => _t('أبنائي', 'My children');
  String get invoices => _t('الفواتير', 'Invoices');
  String get behaviour => _t('السلوك', 'Behaviour');
  String get classes => _t('الصفوف', 'Classes');
  String get myClasses => _t('صفوفي', 'My classes');
  String get mySchool => _t('مدرستي', 'My school');

  // Fields
  String get theClass => _t('الصف', 'Class');
  String get subject => _t('المادة', 'Subject');
  String get date => _t('التاريخ', 'Date');
  String get title => _t('العنوان', 'Title');
  String get summary => _t('الملخص', 'Summary');
  String get dueDate => _t('تاريخ التسليم', 'Due date');
  String get present => _t('حاضر', 'Present');
  String get lateLabel => _t('متأخر', 'Late');
  String get absent => _t('غائب', 'Absent');
  String get saveAttendance => _t('حفظ كشف الحضور', 'Save attendance');
  String get publishSummary => _t('نشر الملخص', 'Publish summary');
  String get lessonsToday => _t('حصص اليوم', 'Lessons today');
  String get studentsCount => _t('عدد الطلاب', 'Students');
  String get homeworkDue => _t('واجبات مستحقة', 'Homework due');
  String get noClasses => _t('لا توجد صفوف مسندة إليك', 'No classes assigned to you');
  String get noChildren => _t('لا يوجد أبناء مرتبطون بحسابك', 'No children linked to your account');
  String get selectChild => _t('اختر الابن', 'Select child');
  String get childrenOverview => _t('نظرة على الأبناء', 'Children overview');
  String get upcomingHomework => _t('واجبات قادمة', 'Upcoming homework');
  String get noUpcomingHomework => _t('لا واجبات قادمة', 'No upcoming homework');
  String get childClasses => _t('صفوف الابن', "Child's classes");
  String get attendanceBreakdown => _t('تفصيل الحضور', 'Attendance breakdown');
  String get titleRequired => _t('أدخل العنوان', 'Enter a title');

  // Parent portal: finance, behaviour, grades, messages
  String get fees => _t('الرسوم', 'Fees');
  String get receipts => _t('الإيصالات', 'Receipts');
  String get feeAlerts => _t('تنبيهات الرسوم', 'Fee alerts');
  String get messages => _t('الرسائل', 'Messages');
  String get noInvoices => _t('لا توجد فواتير مسجلة', 'No invoices on record');
  String get noReceipts => _t('لا توجد إيصالات دفع بعد', 'No payment receipts yet');
  String get noFeeAlerts => _t('لا توجد رسوم مستحقة أو قريبة الاستحقاق', 'No fees due or coming due');
  String get noMessages => _t('لا توجد رسائل', 'No messages');
  String get noBehaviour => _t('لا توجد سجلات سلوك', 'No behaviour records');
  String get noGrades => _t('لا توجد درجات مسجلة بعد', 'No grades recorded yet');
  String get paidLabel => _t('مدفوعة', 'Paid');
  String get dueLabel => _t('مستحقة', 'Due');
  String get overdueLabel => _t('متأخرة', 'Overdue');
  String get totalDue => _t('إجمالي المستحق', 'Total due');

  // Staff portal
  String get allStudents => _t('كل الطلاب', 'All students');
  String get allClasses => _t('كل الصفوف', 'All classes');
  String get classesCount => _t('عدد الصفوف', 'Classes');
  String get noStudents => _t('لا يوجد طلاب', 'No students');
  String get staffNotices => _t('إشعارات الموظفين', 'Staff notices');

  // Admin portal
  String get feesOverview => _t('نظرة على الرسوم', 'Fees overview');
  String get invoicesCount => _t('عدد الفواتير', 'Invoices');
  String get totalCollected => _t('إجمالي المحصّل', 'Total collected');
}

class LocaleScope extends InheritedWidget {
  const LocaleScope({
    super.key,
    required this.languageCode,
    required this.onChanged,
    required super.child,
  });

  final String languageCode;
  final ValueChanged<String> onChanged;

  L10n get strings => L10n(languageCode);

  void toggle() => onChanged(languageCode == 'ar' ? 'en' : 'ar');

  static LocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope is missing above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(LocaleScope oldWidget) => oldWidget.languageCode != languageCode;
}
