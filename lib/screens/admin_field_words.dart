// Word-by-word Arabic names for form fields that have no hand-written label.
part of 'admin_manage_pages.dart';

const _wordsAr = <String, String>{
  'absence': 'غياب', 'accept': 'قبول', 'access': 'وصول', 'accessed': 'تم الوصول', 'action': 'إجراء',
  'actioned': 'تم التنفيذ', 'active': 'نشط', 'activity': 'نشاط', 'address': 'عنوان', 'admin': 'إدارة',
  'agreement': 'موافقة', 'aid': 'إسعاف', 'aider': 'مسعف', 'alert': 'تنبيه', 'algorithm': 'خوارزمية',
  'all': 'الكل', 'allow': 'سماح', 'alternate': 'بديل', 'amount': 'مبلغ', 'application': 'طلب',
  'approval': 'موافقة', 'archive': 'أرشيف', 'array': 'مصفوفة', 'assessment': 'تقييم', 'assign': 'إسناد',
  'attachment': 'مرفق', 'attainment': 'تحصيل', 'attendance': 'حضور', 'author': 'مؤلف', 'automatic': 'تلقائي',
  'background': 'خلفية', 'backup': 'احتياطي', 'behaviour': 'سلوك', 'bg': 'خلفية', 'biographical': 'تعريفي',
  'biography': 'سيرة', 'birth': 'ميلاد', 'body': 'نص', 'bookable': 'قابل للحجز', 'borrowable': 'قابل للإعارة',
  'budget': 'ميزانية', 'builder': 'منشئ', 'by': 'بواسطة', 'calculate': 'حساب', 'calendar': 'تقويم',
  'call': 'اتصال', 'can': 'يمكن', 'category': 'فئة', 'cc': 'نسخة', 'channel': 'قناة', 'character': 'حرف',
  'characters': 'أحرف', 'child': 'ابن', 'choice': 'اختيار', 'choices': 'اختيارات', 'class': 'فصل',
  'close': 'إغلاق', 'code': 'رمز', 'color': 'لون', 'column': 'عمود', 'comment': 'تعليق', 'company': 'شركة',
  'complete': 'مكتمل', 'concern': 'ملاحظة', 'condition': 'حالة', 'conditional': 'مشروط', 'confidential': 'سري',
  'config': 'إعداد', 'contact': 'جهة اتصال', 'content': 'محتوى', 'contents': 'محتويات', 'context': 'سياق',
  'cost': 'تكلفة', 'count': 'عدد', 'country': 'دولة', 'course': 'مقرر', 'coverage': 'تغطية', 'create': 'إنشاء',
  'created': 'أنشئ', 'creator': 'منشئ', 'credentials': 'بيانات دخول', 'criteria': 'معيار', 'current': 'حالي',
  'cycle': 'دورة', 'data': 'بيانات', 'date': 'تاريخ', 'day': 'يوم', 'days': 'أيام', 'default': 'افتراضي',
  'definition': 'تعريف', 'department': 'قسم', 'desc': 'وصف', 'description': 'وصف', 'descriptor': 'واصف',
  'descriptors': 'واصفات', 'detail': 'تفصيل', 'details': 'تفاصيل', 'did': 'هل', 'direction': 'اتجاه',
  'district': 'منطقة', 'dob': 'تاريخ ميلاد', 'document': 'وثيقة', 'due': 'استحقاق', 'duty': 'مناوبة',
  'edit': 'تعديل', 'effort': 'جهد', 'email': 'بريد إلكتروني', 'emergency': 'طوارئ', 'employer': 'جهة عمل',
  'encrypt': 'تشفير', 'end': 'نهاية', 'enrolled': 'مسجل', 'enrolment': 'تسجيل', 'entry': 'إدخال',
  'ethnicity': 'عرق', 'event': 'حدث', 'ex': 'سابق', 'exclude': 'استثناء', 'expense': 'نفقة', 'experience': 'خبرة',
  'expire': 'انتهاء', 'expiry': 'انتهاء', 'extension': 'امتداد', 'external': 'خارجي', 'family': 'أسرة', 'fee': 'رسم',
  'field': 'حقل', 'fields': 'حقول', 'file': 'ملف', 'finance': 'مالية', 'firmness': 'التزام', 'first': 'أول',
  'flags': 'علامات', 'follow': 'متابعة', 'followup': 'متابعة', 'for': 'لـ', 'foreign': 'مرتبط', 'form': 'نموذج',
  'format': 'صيغة', 'full': 'كامل', 'gateway': 'بوابة', 'gender': 'الجنس', 'generated': 'منشأ', 'grade': 'درجة',
  'grades': 'درجات', 'group': 'مجموعة', 'grouping': 'تجميع', 'guide': 'دليل', 'hash': 'رمز', 'hear': 'سمعت',
  'help': 'مساعدة', 'hidden': 'مخفي', 'high': 'مرتفع', 'home': 'منزل', 'homework': 'واجب', 'house': 'بيت',
  'how': 'كيف', 'id': 'معرف', 'identifier': 'معرف', 'idhoy': 'رئيس المرحلة', 'hoy': 'رئيس المرحلة', 'image': 'صورة', 'in': 'في',
  'increment': 'زيادة', 'information': 'معلومات', 'informed': 'تم الإبلاغ', 'initials': 'الأحرف الأولى',
  'installed': 'مثبت', 'interest': 'اهتمام', 'internal': 'داخلي', 'introduction': 'مقدمة', 'invoice': 'فاتورة',
  'invoicee': 'مستلم الفاتورة', 'ip': 'عنوان الشبكة', 'is': 'هل', 'issue': 'بلاغ', 'item': 'عنصر', 'job': 'وظيفة',
  'joining': 'التحاق', 'key': 'مفتاح', 'label': 'تسمية', 'language': 'لغة', 'last': 'آخر', 'length': 'طول',
  'level': 'مستوى', 'levels': 'مستويات', 'library': 'مكتبة', 'license': 'ترخيص', 'limit': 'حد', 'link': 'رابط',
  'list': 'قائمة', 'listing': 'إعلان', 'location': 'موقع', 'locker': 'خزانة', 'login': 'دخول', 'logo': 'شعار',
  'long': 'طويل', 'low': 'منخفض', 'made': 'تم', 'mail': 'بريد', 'mailing': 'بريدية', 'map': 'خريطة',
  'margin': 'هامش', 'markbook': 'دفتر الدرجات', 'max': 'أقصى', 'med': 'متوسط', 'medical': 'طبي',
  'medication': 'دواء', 'message': 'رسالة', 'messenger': 'مراسلة', 'milestones': 'مراحل', 'min': 'أدنى',
  'modified': 'معدل', 'module': 'وحدة', 'more': 'المزيد', 'name': 'اسم', 'new': 'جديد', 'note': 'ملاحظة',
  'notes': 'ملاحظات', 'number': 'رقم', 'numeric': 'رقمي', 'of': 'من', 'official': 'رسمي', 'old': 'قديم',
  'online': 'إلكتروني', 'only': 'فقط', 'open': 'فتح', 'opening': 'شاغر', 'operator': 'مشغل', 'options': 'خيارات',
  'order': 'ترتيب', 'organisation': 'منظمة', 'organiser': 'منظم', 'orientation': 'اتجاه', 'origin': 'منشأ',
  'other': 'آخر', 'out': 'خروج', 'outcome': 'ناتج تعلم', 'owner': 'مالك', 'ownership': 'ملكية', 'page': 'صفحة',
  'parent': 'ولي أمر', 'parents': 'أولياء الأمور', 'participants': 'مشاركون', 'password': 'كلمة المرور',
  'path': 'مسار', 'patient': 'مريض', 'payer': 'دافع', 'payment': 'دفع', 'per': 'لكل', 'person': 'شخص',
  'phone': 'هاتف', 'php': 'نظام', 'physical': 'جسدية', 'planner': 'مخطط', 'postscript': 'حاشية',
  'preferred': 'مفضل', 'prefill': 'تعبئة مسبقة', 'primary': 'أساسي', 'priority': 'أولوية', 'privacy': 'خصوصية',
  'process': 'معالجة', 'producer': 'منتج', 'profession': 'مهنة', 'program': 'برنامج', 'proof': 'تدقيق',
  'proofed': 'مدقق', 'provider': 'مزود', 'public': 'عام', 'purchase': 'شراء', 'purpose': 'غرض',
  'qualification': 'مؤهل', 'qualifications': 'مؤهلات', 'qualified': 'مؤهل', 'query': 'استعلام',
  'questions': 'أسئلة', 'raw': 'خام', 'read': 'قراءة', 'readonly': 'للقراءة فقط', 'reason': 'سبب',
  'reasons': 'أسباب', 'receipt': 'إيصال', 'reference': 'مرجع', 'reg': 'تسجيل', 'register': 'سجل',
  'registration': 'تسجيل', 'relationship': 'صلة القرابة', 'religion': 'ديانة', 'report': 'تقرير',
  'reportable': 'يظهر في التقارير', 'reporting': 'تقارير', 'request': 'طلب', 'required': 'مطلوب',
  'requires': 'يتطلب', 'resolution': 'حل', 'resolve': 'حل', 'resource': 'مصدر', 'response': 'رد', 'result': 'نتيجة',
  'role': 'دور', 'roll': 'قيد', 'row': 'صف', 'rtl': 'من اليمين لليسار', 'rubric': 'سلم تقدير', 'scale': 'سلم',
  'scheduled': 'مجدول', 'scholarship': 'منحة', 'school': 'مدرسة', 'scope': 'نطاق', 'second': 'ثانية',
  'secondary': 'ثانوي', 'sen': 'احتياجات خاصة', 'sent': 'مرسل', 'sequence': 'تسلسل', 'serialised': 'مسلسل',
  'shelf': 'رف', 'short': 'مختصر', 'shuffle': 'خلط', 'sibling': 'أخ', 'sign': 'تسجيل', 'size': 'حجم',
  'sms': 'رسالة نصية', 'source': 'مصدر', 'space': 'قاعة', 'staff': 'موظف', 'start': 'بداية', 'status': 'حالة',
  'step': 'خطوة', 'steps': 'خطوات', 'strategies': 'استراتيجيات', 'student': 'طالب', 'students': 'طلاب',
  'stylesheet': 'تنسيق', 'subcategory': 'فئة فرعية', 'subject': 'موضوع', 'submit': 'تقديم', 'summary': 'ملخص',
  'surname': 'اسم العائلة', 'system': 'نظام', 'table': 'جدول', 'tables': 'جداول', 'tag': 'وسم', 'tags': 'وسوم',
  'taken': 'مأخوذ', 'taker': 'آخذ', 'target': 'هدف', 'targets': 'أهداف', 'teachers': 'معلمون',
  'technician': 'فني', 'template': 'قالب', 'term': 'فصل دراسي', 'text': 'نص', 'third': 'ثالث', 'threshold': 'حد',
  'time': 'وقت', 'timestamp': 'وقت', 'title': 'عنوان', 'to': 'إلى', 'token': 'رمز', 'total': 'إجمالي',
  'transaction': 'معاملة', 'transport': 'نقل', 'tried': 'مجربة', 'tt': 'جدول', 'tutor': 'مرشد', 'type': 'نوع',
  'unavailable': 'غير متاح', 'unenrolled': 'غير مسجل', 'unit': 'وحدة', 'up': 'أعلى', 'update': 'تحديث',
  'updater': 'محدث', 'upload': 'رفع', 'uploaded': 'مرفوع', 'url': 'رابط', 'use': 'استخدام',
  'username': 'اسم المستخدم', 'value': 'قيمة', 'variables': 'متغيرات', 'vehicle': 'مركبة', 'vendor': 'مورد',
  'version': 'إصدار', 'view': 'عرض', 'viewable': 'مرئي', 'visual': 'مرئي', 'visualise': 'عرض مرئي',
  'waiting': 'انتظار', 'wall': 'لوحة', 'website': 'موقع', 'week': 'أسبوع', 'weight': 'وزن', 'weighting': 'ترجيح',
  'workflow': 'سير عمل', 'write': 'كتابة', 'x': 'أفقي', 'y': 'رأسي', 'year': 'سنة', 'you': 'أنت',
  'yes': 'نعم', 'no': 'لا', 'mobile': 'جوال',
};

final _tokenRe = RegExp(r'[A-Z]+(?=[A-Z][a-z])|[A-Z]?[a-z]+|[A-Z]+|\d+');

/// Field name without the school system's internal prefix/suffix, split into words.
List<String> _fieldWords(String f) {
  var base = f.replaceAll(RegExp('tawasul', caseSensitive: false), '');
  base = base.replaceFirst(RegExp(r'ID$'), '').replaceAll('ID', ' ').replaceAll('_', ' ');
  final words = _tokenRe.allMatches(base).map((m) => m[0]!).where((w) => w.toLowerCase() != 'id').toList();
  return words.isEmpty ? [f.replaceAll(RegExp('tawasul', caseSensitive: false), '')] : words;
}

String _englishLabel(String f) {
  final t = _fieldWords(f).map((w) => w.toLowerCase()).join(' ');
  return t.isEmpty ? '—' : t[0].toUpperCase() + t.substring(1);
}

/// Arabic compound names read in reverse order ("schoolYear" → "سنة مدرسة").
String _arabicLabel(String f) {
  final words = _fieldWords(f);
  final ar = <String>[];
  String? number;
  for (final w in words) {
    final l = w.toLowerCase();
    if (RegExp(r'^\d+$').hasMatch(l)) {
      number = l;
      continue;
    }
    ar.add(_wordsAr[l] ?? l);
  }
  final text = ar.reversed.join(' ');
  return number == null ? text : '$text $number';
}
