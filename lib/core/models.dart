enum ConsoleRole { teacher, parent, student, staff, admin }

enum TileTone { mint, sage, gold, green, red }

enum DraftType { teacherAttendance, teacherLessonUpdate }

class MetricTileData {
  const MetricTileData({required this.title, required this.value, this.hint = '', this.tone = TileTone.mint});
  final String title;
  final String value;
  final String hint;
  final TileTone tone;

  Map<String, dynamic> toJson() => {'title': title, 'value': value, 'hint': hint, 'tone': tone.name};
  factory MetricTileData.fromJson(Map<String, dynamic> json) => MetricTileData(
        title: json['title']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
        hint: json['hint']?.toString() ?? '',
        tone: TileTone.values.firstWhere((e) => e.name == json['tone'], orElse: () => TileTone.mint),
      );
}

class ClassItem {
  const ClassItem({required this.id, required this.name, this.courseName = '', this.studentCount = 0});
  final String id;
  final String name;
  final String courseName;
  final int studentCount;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'courseName': courseName, 'studentCount': studentCount};
  factory ClassItem.fromJson(Map<String, dynamic> json) => ClassItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        courseName: json['courseName']?.toString() ?? '',
        studentCount: int.tryParse(json['studentCount']?.toString() ?? '') ?? 0,
      );
}

class LessonItem {
  const LessonItem({required this.time, required this.subject, required this.group, this.room = '', this.id = '', this.classId = '', this.date = '', this.summary = ''});
  final String id;
  final String classId;
  final String time;
  final String subject;
  final String group;
  final String room;
  final String date;
  final String summary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'time': time,
        'subject': subject,
        'group': group,
        'room': room,
        'date': date,
        'summary': summary,
      };

  factory LessonItem.fromJson(Map<String, dynamic> json) => LessonItem(
        id: json['id']?.toString() ?? '',
        classId: json['classId']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        group: json['group']?.toString() ?? '',
        room: json['room']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        summary: json['summary']?.toString() ?? '',
      );
}

class StudentItem {
  const StudentItem({required this.name, required this.group, required this.initials, this.attendance = '', this.tone = TileTone.sage, this.id = ''});
  final String id;
  final String name;
  final String group;
  final String initials;
  final String attendance;
  final TileTone tone;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'group': group, 'initials': initials, 'attendance': attendance, 'tone': tone.name};
  factory StudentItem.fromJson(Map<String, dynamic> json) => StudentItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        group: json['group']?.toString() ?? '',
        initials: json['initials']?.toString() ?? '',
        attendance: json['attendance']?.toString() ?? '',
        tone: TileTone.values.firstWhere((e) => e.name == json['tone'], orElse: () => TileTone.sage),
      );
}

class NoticeItem {
  const NoticeItem({required this.title, required this.date, required this.kind, this.urgent = false});
  final String title;
  final String date;
  final String kind;
  final bool urgent;

  Map<String, dynamic> toJson() => {'title': title, 'date': date, 'kind': kind, 'urgent': urgent};
  factory NoticeItem.fromJson(Map<String, dynamic> json) => NoticeItem(
        title: json['title']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        kind: json['kind']?.toString() ?? '',
        urgent: json['urgent'] == true,
      );
}

class GradeItem {
  const GradeItem({required this.subject, required this.value, required this.grade});
  final String subject;
  final String value;
  final String grade;

  Map<String, dynamic> toJson() => {'subject': subject, 'value': value, 'grade': grade};
  factory GradeItem.fromJson(Map<String, dynamic> json) => GradeItem(
        subject: json['subject']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
        grade: json['grade']?.toString() ?? '',
      );
}

class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.title,
    required this.studentName,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.paidDate,
    required this.studentId,
  });

  final String id;
  final String title;
  final String studentName;
  final String amount;
  final String status;
  final String dueDate;
  final String paidDate;
  final String studentId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'studentName': studentName,
        'amount': amount,
        'status': status,
        'dueDate': dueDate,
        'paidDate': paidDate,
        'studentId': studentId,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        studentName: json['studentName']?.toString() ?? '',
        amount: json['amount']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        dueDate: json['dueDate']?.toString() ?? '',
        paidDate: json['paidDate']?.toString() ?? '',
        studentId: json['studentId']?.toString() ?? '',
      );
}

class FinanceSummary {
  const FinanceSummary({
    required this.totalOutstanding,
    required this.totalCollected,
    required this.totalPending,
    required this.invoicesCount,
    required this.expensesTotal,
    required this.budgetTotal,
    required this.budgetSpent,
  });

  final String totalOutstanding;
  final String totalCollected;
  final String totalPending;
  final String invoicesCount;
  final String expensesTotal;
  final String budgetTotal;
  final String budgetSpent;

  Map<String, dynamic> toJson() => {
        'totalOutstanding': totalOutstanding,
        'totalCollected': totalCollected,
        'totalPending': totalPending,
        'invoicesCount': invoicesCount,
        'expensesTotal': expensesTotal,
        'budgetTotal': budgetTotal,
        'budgetSpent': budgetSpent,
      };

  factory FinanceSummary.fromJson(Map<String, dynamic> json) => FinanceSummary(
        totalOutstanding: json['totalOutstanding']?.toString() ?? '',
        totalCollected: json['totalCollected']?.toString() ?? '',
        totalPending: json['totalPending']?.toString() ?? '',
        invoicesCount: json['invoicesCount']?.toString() ?? '',
        expensesTotal: json['expensesTotal']?.toString() ?? '',
        budgetTotal: json['budgetTotal']?.toString() ?? '',
        budgetSpent: json['budgetSpent']?.toString() ?? '',
      );
}

class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.title,
    required this.status,
    required this.cost,
    required this.paymentDate,
    required this.paymentAmount,
    required this.budgetName,
  });

  final String id;
  final String title;
  final String status;
  final String cost;
  final String paymentDate;
  final String paymentAmount;
  final String budgetName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'cost': cost,
        'paymentDate': paymentDate,
        'paymentAmount': paymentAmount,
        'budgetName': budgetName,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        cost: json['cost']?.toString() ?? '',
        paymentDate: json['paymentDate']?.toString() ?? '',
        paymentAmount: json['paymentAmount']?.toString() ?? '',
        budgetName: json['budgetName']?.toString() ?? '',
      );
}

class BudgetItem {
  const BudgetItem({
    required this.id,
    required this.name,
    required this.category,
    required this.active,
  });

  final String id;
  final String name;
  final String category;
  final bool active;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'active': active,
      };

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        active: json['active']?.toString().toLowerCase() == 'y',
      );
}

class BehaviourItem {
  const BehaviourItem({required this.title, required this.date, required this.note, this.positive = true});
  final String title;
  final String date;
  final String note;
  final bool positive;

  Map<String, dynamic> toJson() => {'title': title, 'date': date, 'note': note, 'positive': positive};
  factory BehaviourItem.fromJson(Map<String, dynamic> json) => BehaviourItem(
        title: json['title']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
        positive: json['positive'] != false,
      );
}

class MessageItem {
  const MessageItem({required this.title, required this.body, required this.date, this.sender = ''});
  final String title;
  final String body;
  final String date;
  final String sender;

  Map<String, dynamic> toJson() => {'title': title, 'body': body, 'date': date, 'sender': sender};
  factory MessageItem.fromJson(Map<String, dynamic> json) => MessageItem(
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        sender: json['sender']?.toString() ?? '',
      );
}

class ChatItem {
  const ChatItem({required this.id, required this.title, required this.type, this.avatar = '', this.lastMessage = '', this.lastMessageDate = '', this.unreadCount = 0, this.participantCount = 0});

  final String id;
  final String title;
  final String type;
  final String avatar;
  final String lastMessage;
  final String lastMessageDate;
  final int unreadCount;
  final int participantCount;

  factory ChatItem.fromJson(Map<String, dynamic> json) => ChatItem(
        id: json['chat_id']?.toString() ?? '',
        title: json['name']?.toString() ?? (json['title']?.toString() ?? ''),
        type: json['type']?.toString() ?? 'individual',
        avatar: json['participantAvatar']?.toString() ?? '',
        lastMessage: json['lastMessageContent']?.toString() ?? '',
        lastMessageDate: json['lastMessageTimestamp']?.toString() ?? '',
        unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
        participantCount: int.tryParse(json['participantCount']?.toString() ?? '0') ?? 0,
      );
}

class ChatMessageItem {
  const ChatMessageItem({required this.id, required this.chatId, required this.senderId, required this.senderName, required this.content, required this.timestamp, this.isMine = false, this.type = 'text'});

  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final String timestamp;
  final bool isMine;
  final String type;

  factory ChatMessageItem.fromJson(Map<String, dynamic> json, {required String currentPersonId}) => ChatMessageItem(
        id: json['chat_message_id']?.toString() ?? '',
        chatId: json['chat_id']?.toString() ?? '',
        senderId: json['tawasulPersonID']?.toString() ?? '',
        senderName: '${json['preferredName']?.toString() ?? ''} ${json['surname']?.toString() ?? ''}'.trim(),
        content: json['content']?.toString() ?? '',
        timestamp: json['timestampCreated']?.toString() ?? '',
        isMine: json['tawasulPersonID']?.toString() == currentPersonId,
        type: json['type']?.toString() ?? 'text',
      );
}

class ChatParticipant {
  const ChatParticipant({required this.id, required this.name, required this.role, this.avatar = ''});

  final String id;
  final String name;
  final String role;
  final String avatar;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) => ChatParticipant(
        id: json['tawasulPersonID']?.toString() ?? '',
        name: '${json['preferredName']?.toString() ?? ''} ${json['surname']?.toString() ?? ''}'.trim(),
        role: json['roleName']?.toString() ?? '',
        avatar: json['image_240']?.toString() ?? '',
      );
}

class HomeworkItem {
  const HomeworkItem({
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.score = '',
  });

  final String subject;
  final String title;
  final String description;
  final String dueDate;
  final String status;
  final String score;

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'status': status,
        'score': score,
      };

  factory HomeworkItem.fromJson(Map<String, dynamic> json) => HomeworkItem(
        subject: json['subject']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        dueDate: json['dueDate']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        score: json['score']?.toString() ?? '',
      );
}

class AttendanceRecord {
  const AttendanceRecord({required this.date, required this.status, this.note = '', this.context = ''});

  final String date;
  final String status;
  final String note;
  final String context;

  Map<String, dynamic> toJson() => {'date': date, 'status': status, 'note': note, 'context': context};
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        date: json['date']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
        context: json['context']?.toString() ?? '',
      );
}

class OfflineDraft {
  const OfflineDraft({required this.id, required this.type, required this.endpoint, required this.method, required this.payload, required this.createdAt});

  final String id;
  final DraftType type;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'createdAt': createdAt,
      };

  factory OfflineDraft.fromJson(Map<String, dynamic> json) => OfflineDraft(
        id: json['id']?.toString() ?? '',
        type: DraftType.values.firstWhere((entry) => entry.name == json['type'], orElse: () => DraftType.teacherAttendance),
        endpoint: json['endpoint']?.toString() ?? '',
        method: json['method']?.toString() ?? 'POST',
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class ConsoleSnapshot {
  const ConsoleSnapshot({
    required this.role,
    required this.personName,
    this.classes = const [],
    this.lessons = const [],
    this.students = const [],
    this.children = const [],
    this.selectedChildId = '',
    this.notices = const [],
    this.grades = const [],
    this.invoices = const [],
    this.expenses = const [],
    this.behaviour = const [],
    this.messages = const [],
    this.homework = const [],
    this.attendance = const [],
    this.attendanceRate = '',
    this.pendingDraftCount = 0,
    this.isOffline = false,
  });

  final ConsoleRole role;
  final String personName;
  final List<ClassItem> classes;
  final List<LessonItem> lessons;
  final List<StudentItem> students;
  final List<StudentItem> children;
  final String selectedChildId;
  final List<NoticeItem> notices;
  final List<GradeItem> grades;
  final List<InvoiceItem> invoices;
  final List<ExpenseItem> expenses;
  final List<BehaviourItem> behaviour;
  final List<MessageItem> messages;
  final List<HomeworkItem> homework;
  final List<AttendanceRecord> attendance;
  final String attendanceRate;
  final int pendingDraftCount;
  final bool isOffline;

  ConsoleSnapshot copyWith({bool? isOffline, int? pendingDraftCount, String? selectedChildId}) => ConsoleSnapshot(
        role: role,
        personName: personName,
        classes: classes,
        lessons: lessons,
        students: students,
        children: children,
        selectedChildId: selectedChildId ?? this.selectedChildId,
        notices: notices,
        grades: grades,
        invoices: invoices,
        expenses: expenses,
        behaviour: behaviour,
        messages: messages,
        homework: homework,
        attendance: attendance,
        attendanceRate: attendanceRate,
        pendingDraftCount: pendingDraftCount ?? this.pendingDraftCount,
        isOffline: isOffline ?? this.isOffline,
      );

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'personName': personName,
        'classes': classes.map((e) => e.toJson()).toList(),
        'lessons': lessons.map((e) => e.toJson()).toList(),
        'students': students.map((e) => e.toJson()).toList(),
        'children': children.map((e) => e.toJson()).toList(),
        'selectedChildId': selectedChildId,
        'notices': notices.map((e) => e.toJson()).toList(),
        'grades': grades.map((e) => e.toJson()).toList(),
        'invoices': invoices.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'behaviour': behaviour.map((e) => e.toJson()).toList(),
        'messages': messages.map((e) => e.toJson()).toList(),
        'homework': homework.map((e) => e.toJson()).toList(),
        'attendance': attendance.map((e) => e.toJson()).toList(),
        'attendanceRate': attendanceRate,
        'pendingDraftCount': pendingDraftCount,
      };

  static List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) mapper) =>
      (value as List? ?? const []).whereType<Map>().map((e) => mapper(Map<String, dynamic>.from(e))).toList();

  factory ConsoleSnapshot.fromJson(Map<String, dynamic> json) => ConsoleSnapshot(
        role: ConsoleRole.values.firstWhere((e) => e.name == json['role'], orElse: () => ConsoleRole.student),
        personName: json['personName']?.toString() ?? '',
        classes: _list(json['classes'], ClassItem.fromJson),
        lessons: _list(json['lessons'], LessonItem.fromJson),
        students: _list(json['students'], StudentItem.fromJson),
        children: _list(json['children'], StudentItem.fromJson),
        selectedChildId: json['selectedChildId']?.toString() ?? '',
        notices: _list(json['notices'], NoticeItem.fromJson),
        grades: _list(json['grades'], GradeItem.fromJson),
        invoices: _list(json['invoices'], InvoiceItem.fromJson),
        expenses: _list(json['expenses'], ExpenseItem.fromJson),
        behaviour: _list(json['behaviour'], BehaviourItem.fromJson),
        messages: _list(json['messages'], MessageItem.fromJson),
        homework: _list(json['homework'], HomeworkItem.fromJson),
        attendance: _list(json['attendance'], AttendanceRecord.fromJson),
        attendanceRate: json['attendanceRate']?.toString() ?? '',
        pendingDraftCount: int.tryParse(json['pendingDraftCount']?.toString() ?? '') ?? 0,
      );
}
