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

class AdminFees extends StatelessWidget {
  const AdminFees({super.key, required this.snapshot});

  final ConsoleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final invoices = snapshot.invoices;
    final due = invoices.where((invoice) => invoice.status.toLowerCase() != 'paid').toList();
    final paid = invoices.where((invoice) => invoice.status.toLowerCase() == 'paid').toList();
    return Column(
      children: [
        MetricGrid(metrics: [
          MetricTileData(title: strings.invoicesCount, value: '${invoices.length}', tone: TileTone.mint),
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
                            leading: invoice.title.isEmpty ? '—' : invoice.title.substring(0, 1),
                            title: invoice.title,
                            subtitle: invoice.amount,
                            trailing: invoice.status,
                            trailingColor: invoice.status.toLowerCase() == 'paid' ? AppColors.green : AppColors.red,
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}
