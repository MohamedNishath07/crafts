import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'debt_controller.dart';
import 'widgets/add_debt_dialog.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  void _showAddDebtDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddDebtDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAsync = ref.watch(debtControllerProvider);
    final paginatedDebts = ref.watch(paginatedDebtsProvider);

    final pageSize = ref.watch(debtPageSizeProvider);
    final pageIndex = ref.watch(debtPageIndexProvider);

    final totalCount = paginatedDebts.length;
    final maxPage = totalCount == 0 ? 0 : ((totalCount - 1) ~/ pageSize);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debt Ledger',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track principal balances, DPD aging, and overdue obligations',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddDebtDialog(context),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Create Debt Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.inkWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Aging / Status Filter Bar
            _buildFilterBar(ref),

            const SizedBox(height: 12),

            debtAsync.when(
              data: (debts) => Expanded(
                child: Card(
                  color: AppColors.surfaceRaised,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Reference')),
                          DataColumn(label: Text('Principal')),
                          DataColumn(label: Text('Remaining')),
                          DataColumn(label: Text('Due Date')),
                          DataColumn(label: Text('DPD')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: paginatedDebts.map((debt) {
                          final statusColor = _statusColor(debt.status);
                          return DataRow(
                            cells: [
                              DataCell(Text(debt.referenceNumber)),
                              DataCell(Text('\$${debt.principalAmount.toStringAsFixed(2)}')),
                              DataCell(Text('\$${debt.remainingBalance.toStringAsFixed(2)}')),
                              DataCell(Text(
                                '${debt.dueDate.year}-${debt.dueDate.month.toString().padLeft(2, '0')}-${debt.dueDate.day.toString().padLeft(2, '0')}',
                              )),
                              DataCell(Text('${debt.daysPastDue}')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    debt.status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing $totalCount records',
                              style: const TextStyle(fontSize: 13, color: AppColors.inkSecondary),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, size: 20),
                                  tooltip: 'Previous Page',
                                  onPressed: pageIndex > 0
                                      ? () => ref.read(debtPageIndexProvider.notifier).previousPage()
                                      : null,
                                ),
                                Text(
                                  'Page ${pageIndex + 1} of ${maxPage + 1}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.inkPrimary),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, size: 20),
                                  tooltip: 'Next Page',
                                  onPressed: pageIndex < maxPage
                                      ? () => ref.read(debtPageIndexProvider.notifier).nextPage()
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Expanded(
                child: Center(
                  child: Text(
                    'Error loading debts: $e',
                    style: TextStyle(color: AppColors.accentDanger),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(WidgetRef ref) {
    final currentFilter = ref.watch(debtAgingFilterProvider);

    final filters = const [
      _AgingFilterItem(key: 'all', label: 'All'),
      _AgingFilterItem(key: 'overdue', label: 'Overdue', color: AppColors.accentDanger),
      _AgingFilterItem(key: 'current', label: 'Current', color: AppColors.accentSuccess),
      _AgingFilterItem(key: '1-30', label: '1-30 DPD', color: AppColors.accentWarning),
      _AgingFilterItem(key: '31-60', label: '31-60 DPD', color: AppColors.accentWarning),
      _AgingFilterItem(key: '61-90', label: '61-90 DPD', color: AppColors.accentUrgent),
      _AgingFilterItem(key: '90+', label: '90+ DPD', color: AppColors.accentUrgent),
      _AgingFilterItem(key: 'settled', label: 'Settled', color: AppColors.inkMuted),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((item) {
          final isSelected = currentFilter == item.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? AppColors.inkWhite : AppColors.inkSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => ref.read(debtAgingFilterProvider.notifier).setFilter(item.key),
              backgroundColor: AppColors.surfaceRaised,
              selectedColor: item.color ?? AppColors.brandPrimary,
              checkmarkColor: AppColors.inkWhite,
              side: BorderSide(
                color: isSelected
                    ? (item.color ?? AppColors.brandPrimary)
                    : AppColors.borderSubtle,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'settled':
        return AppColors.accentSuccess;
      case 'ptp_scheduled':
        return AppColors.accentWarning;
      case 'written_off':
        return AppColors.accentUrgent;
      case 'active':
      default:
        return AppColors.accentDanger;
    }
  }
}

class _AgingFilterItem {
  final String key;
  final String label;
  final Color? color;

  const _AgingFilterItem({
    required this.key,
    required this.label,
    this.color,
  });
}
