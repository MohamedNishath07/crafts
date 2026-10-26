import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../debts/data/debt_repository.dart';
import '../../../debts/domain/debt.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../payment_controller.dart';

class RecordPaymentDialog extends ConsumerStatefulWidget {
  const RecordPaymentDialog({super.key});

  @override
  ConsumerState<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _transactionRefController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedDebtId;
  Debt? _selectedDebt;
  List<Debt> _debts = [];
  bool _isLoadingDebts = true;
  bool _isSubmitting = false;

  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final repo = ref.read(debtRepositoryProvider);
    try {
      final authProfile = ref.read(authControllerProvider).value;
      final tenantId = authProfile?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';
      final debts = await repo.fetchDebts(tenantId);
      if (mounted) {
        setState(() {
          _debts = debts.where((d) => d.status != 'settled').toList();
          _isLoadingDebts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDebts = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDebtId == null || _selectedDebt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an outstanding debt'),
          backgroundColor: AppColors.accentDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid payment amount'),
          backgroundColor: AppColors.accentDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (amount > _selectedDebt!.remainingBalanceCents) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment exceeds outstanding balance of \$${(_selectedDebt!.remainingBalanceCents / 100).toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.accentDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(paymentControllerProvider.notifier).recordPayment(
            debtId: _selectedDebtId!,
            amountCents: amount,
            paymentMethod: _paymentMethod,
            transactionReference: _transactionRefController.text,
            notes: _notesController.text,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of \$${(amount / 100).toStringAsFixed(2)} recorded successfully',
            ),
            backgroundColor: AppColors.accentSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
            backgroundColor: AppColors.accentDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      title: const Row(
        children: [
          Icon(Icons.payment_outlined, color: AppColors.accentSuccess),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Record Payment',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingDebts)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDebtId,
                    isExpanded: true,
                    items: _debts.map((d) {
                      return DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(
                          '${d.referenceNumber} — \$${(d.remainingBalanceCents / 100).toStringAsFixed(2)} outstanding',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedDebtId = value;
                        _selectedDebt = _debts.firstWhere((d) => d.id == value);
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Outstanding Debt *',
                      hintText: 'Select a debt to apply payment',
                      prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please select an outstanding debt';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_selectedDebt != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentInfo.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentInfo.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppColors.accentInfo),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Outstanding balance: \$${(_selectedDebt!.remainingBalanceCents / 100).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, color: AppColors.inkPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Payment Amount *',
                      hintText: 'e.g. 500.00',
                      prefixIcon: const Icon(Icons.attach_money, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter payment amount';
                      }
                      final cleaned = val.replaceAll(RegExp(r'[^\d.]'), '');
                      final amount = double.tryParse(cleaned);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid positive amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'check', child: Text('Check')),
                      DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Payment Method *',
                      prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _transactionRefController,
                    decoration: InputDecoration(
                      labelText: 'Transaction Reference *',
                      hintText: 'e.g. WIRE-99210',
                      prefixIcon: const Icon(Icons.tag_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a transaction reference';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'e.g. Partial payment received via bank transfer',
                      prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.inkSecondary)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentSuccess,
            foregroundColor: AppColors.inkWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkWhite),
                )
              : const Text('Record Payment'),
        ),
      ],
    );
  }
}