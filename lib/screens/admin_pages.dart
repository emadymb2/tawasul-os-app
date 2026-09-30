import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../theme/app_theme.dart';
import '../widgets/tawasul_widgets.dart';
import '../data/console_repository.dart';
import 'admin_manage_pages.dart';
import 'admin_sections_screens.dart';
import 'staff_pages.dart';

Widget adminContent({required int index, required ConsoleSnapshot snapshot, required ConsoleRepository repository}) {
  switch (index) {
    case 1:
      return AdminSectionsHome(repository: repository);
    case 6:
      return MonthTimetablePage(repository: repository);
    case 4:
      return StaffMessages(snapshot: snapshot);
    default:
      return AdminDashboard(snapshot: snapshot);
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final due = snapshot.invoices.where((invoice) => invoice.status.toLowerCase() != 'paid').toList();
    final collected = snapshot.invoices
        .where((invoice) => invoice.status.toLowerCase() == 'paid')
        .fold<double>(0, (sum, invoice) => sum + (double.tryParse(invoice.amount) ?? 0));
    return Column(
      children: [
        HeroPanel(greeting: strings.welcome, name: snapshot.personName, subtitle: strings.adminPortal),
        MetricGrid(metrics: [
          MetricTileData(title: strings.studentsCount, value: '${snapshot.students.length}', tone: TileTone.mint),
          MetricTileData(title: strings.classesCount, value: '${snapshot.classes.length}', tone: TileTone.sage),
          MetricTileData(
            title: strings.attendanceRate,
            value: snapshot.attendanceRate.isEmpty ? '—' : snapshot.attendanceRate,
            tone: TileTone.green,
          ),
          MetricTileData(title: strings.totalDue, value: '${due.length}', tone: TileTone.gold),
        ]),
        WhitePanel(
          title: strings.feesOverview,
          child: Column(
            children: [
              RowTile(
                leading: '√',
                title: strings.totalCollected,
                subtitle: '${strings.paidLabel}: ${snapshot.invoices.length - due.length}',
                trailing: collected == 0 ? '' : collected.toStringAsFixed(0),
              ),
              RowTile(
                leading: '!',
                title: strings.totalDue,
                subtitle: '${strings.dueLabel}: ${due.length}',
                trailing: '${due.length}',
                trailingColor: due.isEmpty ? AppColors.green : AppColors.red,
              ),
            ],
          ),
        ),
        WhitePanel(title: strings.notices, child: NoticeList(notices: snapshot.notices)),
      ],
    );
  }
}

class AdminFinance extends StatefulWidget {
  const AdminFinance({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  State<AdminFinance> createState() => _AdminFinanceState();
}

class _AdminFinanceState extends State<AdminFinance> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final invoices = widget.snapshot.invoices;
    final expenses = widget.snapshot.expenses;
    final due = invoices.where((i) => i.status.toLowerCase() != 'paid').toList();
    final paid = invoices.where((i) => i.status.toLowerCase() == 'paid').toList();
    final collected = paid.fold<double>(0, (sum, i) => sum + (double.tryParse(i.amount) ?? 0));
    final outstanding = due.fold<double>(0, (sum, i) => sum + (double.tryParse(i.amount) ?? 0));
    final expenseTotal = expenses.fold<double>(0, (sum, e) => sum + (double.tryParse(e.cost) ?? 0));
    final expensePending = expenses.where((e) => e.status.toLowerCase() == 'submitted' || e.status.isEmpty).length;
    final expensePaid = expenses.where((e) => e.status.toLowerCase() == 'paid').length;

    final tabs = [
      _FinanceOverview(
        invoices: invoices,
        due: due,
        paid: paid,
        collected: collected,
        outstanding: outstanding,
        expenses: expenses,
        expenseTotal: expenseTotal,
        expensePending: expensePending,
        expensePaid: expensePaid,
      ),
      _FinanceInvoices(invoices: invoices, due: due, paid: paid),
      _FinanceExpenses(expenses: expenses),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(strings.finance,
                    style: const TextStyle(color: AppColors.pine, fontSize: 34, fontWeight: FontWeight.w900, height: 1.05)),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line, width: 1.5),
          ),
          child: Row(
            children: [
              _financeTab(strings.feesOverview, 0, invoices, expenses),
              _financeTab(strings.invoices, 1, invoices, expenses),
              _financeTab(strings.expenses, 2, invoices, expenses),
            ],
          ),
        ),
        Expanded(child: tabs[_tab]),
      ],
    );
  }

  Widget _financeTab(String label, int tabIndex, List<InvoiceItem> invoices, List<ExpenseItem> expenses) {
    final selected = _tab == tabIndex;
    final color = selected ? AppColors.pine : AppColors.muted;
    final bg = selected ? AppColors.pine.withOpacity(0.08) : Colors.transparent;
    IconData? iconData;
    switch (tabIndex) {
      case 0:
        iconData = Icons.pie_chart_outline;
        break;
      case 1:
        iconData = Icons.receipt_long_outlined;
        break;
      case 2:
        iconData = Icons.account_balance_outlined;
        break;
    }
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = tabIndex),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 18, color: color),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceOverview extends StatelessWidget {
  const _FinanceOverview({
    required this.invoices,
    required this.due,
    required this.paid,
    required this.collected,
    required this.outstanding,
    required this.expenses,
    required this.expenseTotal,
    required this.expensePending,
    required this.expensePaid,
  });

  final List<InvoiceItem> invoices;
  final List<InvoiceItem> due;
  final List<InvoiceItem> paid;
  final double collected;
  final double outstanding;
  final List<ExpenseItem> expenses;
  final double expenseTotal;
  final int expensePending;
  final int expensePaid;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          MetricGrid(metrics: [
            MetricTileData(title: strings.invoicesCount, value: '${invoices.length}', tone: TileTone.sage),
            MetricTileData(title: strings.totalDue, value: '${due.length}', tone: TileTone.gold),
            MetricTileData(title: strings.paidLabel, value: '${paid.length}', tone: TileTone.green),
          ]),
          WhitePanel(
            title: strings.feesOverview,
            child: Column(
              children: [
                RowTile(
                  leading: '✓',
                  title: strings.totalCollected,
                  subtitle: '${strings.paidLabel}: ${paid.length}',
                  trailing: collected == 0 ? '' : collected.toStringAsFixed(0),
                  trailingColor: AppColors.green,
                ),
                RowTile(
                  leading: '!',
                  title: strings.totalOutstanding,
                  subtitle: '${strings.dueLabel}: ${due.length}',
                  trailing: outstanding == 0 ? '' : outstanding.toStringAsFixed(0),
                  trailingColor: AppColors.red,
                ),
              ],
            ),
          ),
          WhitePanel(
            title: strings.expenses,
            child: Column(
              children: [
                RowTile(
                  leading: '₨',
                  title: strings.expensesTotal,
                  subtitle: '$expensePending ${strings.pendingDrafts(expensePending).toLowerCase()}',
                  trailing: expenseTotal == 0 ? '' : expenseTotal.toStringAsFixed(0),
                  trailingColor: AppColors.gold,
                ),
                RowTile(
                  leading: '✓',
                  title: strings.paidLabel,
                  subtitle: '$expensePaid ${strings.paidLabel.toLowerCase()}',
                  trailing: '',
                  trailingColor: AppColors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceInvoices extends StatelessWidget {
  const _FinanceInvoices({required this.invoices, required this.due, required this.paid});

  final List<InvoiceItem> invoices;
  final List<InvoiceItem> due;
  final List<InvoiceItem> paid;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          MetricGrid(metrics: [
            MetricTileData(title: strings.invoicesCount, value: '${invoices.length}', tone: TileTone.sage),
            MetricTileData(title: strings.dueLabel, value: '${due.length}', tone: TileTone.gold),
            MetricTileData(title: strings.paidLabel, value: '${paid.length}', tone: TileTone.green),
          ]),
          WhitePanel(
            title: strings.invoices,
            child: invoices.isEmpty
                ? EmptyState(message: strings.noInvoices)
                : Column(
                    children: invoices
                        .map((invoice) => RowTile(
                              leading: invoice.studentName.isEmpty ? '—' : invoice.studentName.substring(0, 1),
                              title: invoice.title,
                              subtitle: [invoice.studentName, invoice.dueDate, invoice.amount].where((p) => p.isNotEmpty).join(' · '),
                              trailing: invoice.status,
                              trailingColor: invoice.status.toLowerCase() == 'paid' ? AppColors.green : AppColors.red,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FinanceExpenses extends StatelessWidget {
  const _FinanceExpenses({required this.expenses});

  final List<ExpenseItem> expenses;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final pending = expenses.where((e) => e.status.toLowerCase() == 'submitted' || e.status.isEmpty).toList();
    final approved = expenses.where((e) => e.status.toLowerCase() == 'approved').toList();
    final paid = expenses.where((e) => e.status.toLowerCase() == 'paid').toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          MetricGrid(metrics: [
            MetricTileData(title: strings.expenses, value: '${expenses.length}', tone: TileTone.sage),
            MetricTileData(title: strings.expenseStatusPending, value: '${pending.length}', tone: TileTone.gold),
            MetricTileData(title: strings.expenseStatusApproved, value: '${approved.length}', tone: TileTone.mint),
            MetricTileData(title: strings.paidLabel, value: '${paid.length}', tone: TileTone.green),
          ]),
          WhitePanel(
            title: strings.expenses,
            child: expenses.isEmpty
                ? EmptyState(message: strings.noExpenses)
                : Column(
                    children: expenses
                        .map((expense) => RowTile(
                              leading: expense.budgetName.isEmpty ? '—' : expense.budgetName.substring(0, 1),
                              title: expense.title,
                              subtitle: [expense.budgetName, expense.cost].where((p) => p.isNotEmpty).join(' · '),
                              trailing: expense.status,
                              trailingColor: expense.status.toLowerCase() == 'paid'
                                  ? AppColors.green
                                  : expense.status.toLowerCase() == 'rejected'
                                      ? AppColors.red
                                      : AppColors.gold,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
