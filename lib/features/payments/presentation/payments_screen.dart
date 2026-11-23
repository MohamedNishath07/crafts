import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'payment_controller.dart';
import 'widgets/record_payment_dialog.dart';
import 'package:credit_recovery_system/core/theming/glassmorphism_widgets.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  void _showRecordPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RecordPaymentDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentAsync = ref.watch(paymentControllerProvider);
    final paginatedPayments = ref.watch(paginatedPaymentsProvider);

    final pageSize = ref.watch(paymentPageSizeProvider);
    final pageIndex = ref.watch(paymentPageIndexProvider);

    final totalCount = paginatedPayments.length;
    final maxPage = totalCount == 0 ? 0 : ((totalCount - 1) ~/ pageSize);

    final surfaceBase = AppColors.surfaceBaseColor(isDark);
    final surfaceRaised = AppColors.surfaceRaisedColor(isDark);
    final inkPrimary = AppColors.inkPrimaryColor(isDark);
    final inkSecondary = AppColors.inkSecondaryColor(isDark);
    final borderSubtle = AppColors.borderSubtleColor(isDark);

    return Scaffold(
      backgroundColor: surfaceBase,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassmorphismContainer(
                  isDark: isDark,
                  child: Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payments & Transactions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record settlements, verify bank transfers, and generate receipts',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GlassmorphismContainer(
                  isDark: isDark,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRecordPaymentDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Record Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentSuccess,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            paymentAsync.when(
              data: (payments) => Expanded(
                child: GlassmorphismContainer(
                  isDark: isDark,
                  child: Card(
                    color: surfaceRaised,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: borderSubtle),
                    ),
                    child: Column(
                      children: [
                        DataTable(
                          columns: [
                            DataColumn(label: Text('Date', style: TextStyle(color: inkPrimary))),
                            DataColumn(label: Text('Debt Ref', style: TextStyle(color: inkPrimary))),
                            DataColumn(label: Text('Amount', style: TextStyle(color: inkPrimary))),
                            DataColumn(label: Text('Method', style: TextStyle(color: inkPrimary))),
                            DataColumn(label: Text('Txn Reference', style: TextStyle(color: inkPrimary))),
                            DataColumn(label: Text('Receipt', style: TextStyle(color: inkPrimary))),
                          ],
                          rows: paginatedPayments.map((payment) {
                            return DataRow(
                              cells: [
                                DataCell(Text(
                                  '${payment.createdAt.year}-${payment.createdAt.month.toString().padLeft(2, '0')}-${payment.createdAt.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(color: inkPrimary),
                                )),
                                DataCell(Text(payment.debtId, style: TextStyle(color: inkPrimary))),
                                DataCell(Text('\$${payment.amount.toStringAsFixed(2)}', style: TextStyle(color: inkPrimary))),
                                DataCell(Text(_methodLabel(payment.paymentMethod), style: TextStyle(color: inkPrimary))),
                                DataCell(Text(payment.transactionReference, style: TextStyle(color: inkPrimary))),
                                DataCell(Text(payment.receiptNumber, style: TextStyle(color: inkPrimary))),
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
                                style: TextStyle(fontSize: 13, color: inkSecondary),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left, size: 20),
                                    tooltip: 'Previous Page',
                                    onPressed: pageIndex > 0
                                        ? () => ref.read(paymentPageIndexProvider.notifier).previousPage()
                                        : null,
                                  ),
                                  Text(
                                    'Page ${pageIndex + 1} of ${maxPage + 1}',
                                    style: TextStyle(fontSize: 13, color: inkPrimary),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right, size: 20),
                                    tooltip: 'Next Page',
                                    onPressed: pageIndex < maxPage
                                        ? () => ref.read(paymentPageIndexProvider.notifier).nextPage()
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
              ),
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Expanded(
                child: Center(
                  child: Text(
                    'Error loading payments: $e',
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

  String _methodLabel(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'check':
        return 'Check';
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Cash';
      default:
        return method;
    }
  }
}

