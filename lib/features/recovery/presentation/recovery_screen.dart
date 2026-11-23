import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:credit_recovery_system/core/constants/app_colors.dart';
import 'package:credit_recovery_system/features/auth/presentation/auth_controller.dart';
import 'package:credit_recovery_system/features/customers/presentation/customer_controller.dart';
import 'package:credit_recovery_system/features/customers/domain/customer.dart';
import 'package:credit_recovery_system/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:credit_recovery_system/features/debts/presentation/debt_controller.dart';
import 'package:credit_recovery_system/features/debts/presentation/widgets/add_debt_dialog.dart';

import 'interaction_controller.dart';
import 'widgets/log_action_dialog.dart';

import 'package:credit_recovery_system/core/theming/glassmorphism_widgets.dart';

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkPrimary = AppColors.inkPrimaryColor(isDark);
    return Scaffold(
      backgroundColor: AppColors.surfaceBaseColor(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24.0,
            24.0,
            24.0,
            24.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassmorphismContainer(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recovery Activities & Follow-ups',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: inkPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassmorphismContainer(
                    isDark: isDark,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogActionDialog(context, ref),
                      icon: const Icon(Icons.add_call, size: 18),
                      label: const Text('Log Action'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.inkWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GlassmorphismContainer(
                    isDark: isDark,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddCustomerDialog(context, ref),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Create Customer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.inkWhite,
                      ),
                    ),
                  ),
                  GlassmorphismContainer(
                    isDark: isDark,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddDebtDialog(context, ref),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Create Debt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.inkWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCustomerSelector(ref),
              const SizedBox(height: 16),
              _buildDebtSelector(ref),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogActionDialog(BuildContext context, WidgetRef ref) async {
    final authProfile = ref.read(authControllerProvider).value;
    final officerId = authProfile?.id ?? '';
    final debtController = ref.read(debtControllerProvider);
    final selectedDebt = debtController.value?.firstOrNull;
    final customerId = selectedDebt?.customerId ?? '';
    // Look up customer name from the filtered customers provider
    final customers = ref.watch(filteredCustomersProvider);
    final selectedCustomer = customers.firstWhere(
      (c) => c.id == customerId,
      orElse: () => Customer(
        id: customerId,
        fullName: 'Unknown Customer',
        tenantId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        phoneNumber: '',
        secondaryPhone: null,
        email: null,
        nationalId: null,
        address: null,
      ),
    );
    final customerName = selectedCustomer.fullName;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LogActionDialog(
        debtId: selectedDebt?.id ?? '',
        debtCustomerId: customerId,
        customerName: customerName,
      ),
    );

    if (result != null && result.isNotEmpty) {
      final selectedChannel = result['channel'] ?? 'call';
      final outcome = result['outcome'] ?? 'No Response';
      final followUpDate = result['followUpDate'] as DateTime?;
      final promisedAmountCents = result['promisedAmountCents'] as int?;
      final notes = result['notes'] ?? '';

      await ref
          .read(interactionControllerProvider.notifier)
          .saveInteraction(
            debtId: selectedDebt?.id ?? '',
            debtCustomerId: customerId,
            officerId: officerId,
            actionType: selectedChannel,
            outcome: outcome,
            followUpDate: followUpDate,
            promisedAmountCents: promisedAmountCents,
            notes: notes,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery action logged successfully')),
      );
      ref.read(interactionControllerProvider.notifier).refresh();
    }
  }

  Future<void> _showAddCustomerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddCustomerDialog(),
    );
    if (!context.mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer registered successfully')),
      );
    }
  }

  Future<void> _showAddDebtDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddDebtDialog(),
    );
    if (!context.mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debt record created successfully')),
      );
    }
  }

  Widget _buildCustomerSelector(WidgetRef ref) {
    final customers = ref.watch(filteredCustomersProvider);
    return DropdownButtonFormField<String?>(
      initialValue: customers.isNotEmpty ? customers.first.id : null,
      decoration: InputDecoration(
        labelText: 'Customer',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: customers
          .map(
            (customer) => DropdownMenuItem(
              value: customer.id,
              child: Text(customer.fullName),
            ),
          )
          .toList(),
      onChanged: (value) {},
      hint: const Text('Select Customer'),
    );
  }

  Widget _buildDebtSelector(WidgetRef ref) {
    final debts = ref.watch(filteredDebtsProvider);
    return DropdownButtonFormField<Object?>(
      initialValue: debts.isNotEmpty ? debts.first : null,
      decoration: InputDecoration(
        labelText: 'Debt',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: debts
          .map(
            (debt) => DropdownMenuItem(
              value: debt,
              child: Text(
                '${debt.referenceNumber} - \$${debt.remainingBalance.toStringAsFixed(2)}',
              ),
            ),
          )
          .toList(),
      onChanged: (value) {},
      hint: const Text('Select Debt'),
    );
  }
}
