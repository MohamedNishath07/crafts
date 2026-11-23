import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:credit_recovery_system/core/constants/app_colors.dart';
import 'package:credit_recovery_system/core/theming/glassmorphism_widgets.dart';
import 'package:credit_recovery_system/features/auth/presentation/auth_controller.dart';
import 'package:credit_recovery_system/features/customers/domain/customer.dart';
import 'package:credit_recovery_system/features/customers/presentation/customer_controller.dart';
import 'package:credit_recovery_system/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:credit_recovery_system/features/debts/domain/debt.dart';
import 'package:credit_recovery_system/features/debts/presentation/debt_controller.dart';
import 'package:credit_recovery_system/features/debts/presentation/widgets/add_debt_dialog.dart';

import '../domain/interaction.dart';
import 'interaction_controller.dart';
import 'widgets/log_action_dialog.dart';

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              RecoveryLogHeader(
                onLogAction: () => _showLogActionDialog(context, ref),
                onCreateCustomer: () => _showAddCustomerDialog(context, ref),
                onCreateDebt: () => _showAddDebtDialog(context, ref),
              ),
              const SizedBox(height: 20),
              const RecoveryLogStats(),
              const SizedBox(height: 20),
              const RecoveryLogFilterBar(),
              const SizedBox(height: 16),
              const RecoveryLogList(),
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

    final customers = ref.read(filteredCustomersProvider);
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LogActionDialog(
        debtId: selectedDebt?.id ?? '',
        debtCustomerId: customerId,
        customerName: selectedCustomer.fullName,
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
}

class RecoveryLogHeader extends StatelessWidget {
  const RecoveryLogHeader({
    super.key,
    required this.onLogAction,
    required this.onCreateCustomer,
    required this.onCreateDebt,
  });

  final VoidCallback onLogAction;
  final VoidCallback onCreateCustomer;
  final VoidCallback onCreateDebt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recovery Activities & Follow-ups',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimaryColor(isDark),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Log contact attempts, track promises-to-pay, and manage follow-ups',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.inkSecondaryColor(isDark),
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _HeaderAction(
          icon: Icons.add_call,
          label: 'Log Action',
          onPressed: onLogAction,
        ),
        _HeaderAction(
          icon: Icons.person_add,
          label: 'Create Customer',
          onPressed: onCreateCustomer,
        ),
        _HeaderAction(
          icon: Icons.add_circle_outline,
          label: 'Create Debt',
          onPressed: onCreateDebt,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 720;
        if (!useRow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 16),
              actions,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassmorphismContainer(
      isDark: isDark,
      borderRadius: 10,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.inkWhite,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class RecoveryLogStats extends ConsumerWidget {
  const RecoveryLogStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactions = ref.watch(interactionControllerProvider).value ?? [];
    final today = DateTime.now();
    final todayFollowUps = interactions
        .where((i) => i.isFollowUpDueOn(today))
        .length;
    final promises = interactions
        .where((i) => (i.promisedAmountCents ?? 0) > 0)
        .length;
    final overdue = interactions.where((i) {
      final due = i.followUpDate;
      if (due == null) return false;
      return due.isBefore(DateTime(today.year, today.month, today.day));
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final spacing = 12.0;

        final cards = <Widget>[
          _RecoveryStatCard(
            label: 'Total Actions',
            value: '${interactions.length}',
            icon: Icons.history,
            color: AppColors.brandPrimary,
          ),
          _RecoveryStatCard(
            label: 'Follow-ups Due Today',
            value: '$todayFollowUps',
            icon: Icons.event_available,
            color: AppColors.warning,
          ),
          _RecoveryStatCard(
            label: 'Promises to Pay',
            value: '$promises',
            icon: Icons.handshake_outlined,
            color: AppColors.accentInfo,
          ),
          _RecoveryStatCard(
            label: 'Overdue Follow-ups',
            value: '$overdue',
            icon: Icons.error_outline,
            color: AppColors.accentDanger,
          ),
        ];

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          mainAxisExtent: 92,
          children: cards,
        );
      },
    );
  }
}

class _RecoveryStatCard extends StatelessWidget {
  const _RecoveryStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassmorphismContainer(
      isDark: isDark,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkPrimaryColor(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSecondaryColor(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecoveryLogFilterBar extends ConsumerWidget {
  const RecoveryLogFilterBar({super.key});

  static const _filters = <({String value, String label})>[
    (value: 'all', label: 'All'),
    (value: 'follow_ups', label: 'Follow-ups'),
    (value: 'promises', label: 'Promises to Pay'),
    (value: 'escalated', label: 'Escalated'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(interactionFilterProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _filters.map((filter) {
        final isSelected = filter.value == selected;
        return ChoiceChip(
          label: Text(filter.label),
          selected: isSelected,
          onSelected: (_) => ref
              .read(interactionFilterProvider.notifier)
              .setFilter(filter.value),
          selectedColor: AppColors.brandPrimary,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AppColors.inkWhite
                : AppColors.inkSecondaryColor(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class RecoveryLogList extends ConsumerWidget {
  const RecoveryLogList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final interactionsAsync = ref.watch(interactionControllerProvider);
    final interactions = ref.watch(filteredInteractionsProvider);

    return GlassmorphismContainer(
      isDark: isDark,
      borderRadius: 16,
      padding: const EdgeInsets.all(8),
      child: interactionsAsync.isLoading
          ? const _RecoveryLogLoading()
          : interactionsAsync.hasError
          ? _RecoveryLogError(error: interactionsAsync.error)
          : interactions.isEmpty
          ? const _RecoveryLogEmpty()
          : LayoutBuilder(
              builder: (context, constraints) {
                final useCards = constraints.maxWidth < 720;
                return useCards
                    ? _RecoveryCardList(interactions: interactions)
                    : _RecoveryDataTable(interactions: interactions);
              },
            ),
    );
  }
}

class _RecoveryLogLoading extends StatelessWidget {
  const _RecoveryLogLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: ValueKey('recovery-log-loading'),
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RecoveryLogError extends ConsumerWidget {
  const _RecoveryLogError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      key: const ValueKey('recovery-log-error'),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.accentDanger,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load recovery log: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSecondaryColor(isDark)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(interactionControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryLogEmpty extends StatelessWidget {
  const _RecoveryLogEmpty();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = AppColors.inkSecondaryColor(isDark);

    return Padding(
      key: const ValueKey('recovery-log-empty'),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: textSecondary),
            const SizedBox(height: 12),
            Text(
              'No recovery activities logged yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryDataTable extends ConsumerWidget {
  const _RecoveryDataTable({required this.interactions});

  final List<Interaction> interactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customers = ref.watch(filteredCustomersProvider);
    final debts = ref.watch(filteredDebtsProvider);
    final headingColor = isDark
        ? const Color(0xFF16213E)
        : AppColors.lightBorderSubtle;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 120,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(headingColor),
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          columns: const [
            DataColumn(
              label: Text(
                'Customer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Channel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Outcome',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Contact Date',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Follow-up',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Promised',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          rows: interactions
              .map((i) => _buildRow(i, customers, debts, isDark))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(
    Interaction interaction,
    List<Customer> customers,
    List<Debt> debts,
    bool isDark,
  ) {
    final customer = _resolveCustomer(interaction.customerId, customers);
    final debt = _resolveDebt(interaction.debtId, debts);
    final contactDate = interaction.effectiveContactDate;
    final dateStr =
        '${contactDate.year}-${contactDate.month.toString().padLeft(2, '0')}-${contactDate.day.toString().padLeft(2, '0')}';

    return DataRow(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer?.fullName ?? 'Unknown Customer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimaryColor(isDark),
                ),
              ),
              if (debt != null)
                Text(
                  debt.referenceNumber,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSecondaryColor(isDark),
                  ),
                ),
            ],
          ),
        ),
        DataCell(_ChannelChip(channel: interaction.actionType)),
        DataCell(_OutcomeChip(outcome: interaction.outcome)),
        DataCell(
          Text(
            dateStr,
            style: TextStyle(color: AppColors.inkPrimaryColor(isDark)),
          ),
        ),
        DataCell(
          Text(
            interaction.followUpDate != null
                ? _formatDate(interaction.followUpDate!)
                : '—',
            style: TextStyle(
              color: interaction.isFollowUpScheduled
                  ? AppColors.inkPrimaryColor(isDark)
                  : AppColors.inkSecondaryColor(isDark),
            ),
          ),
        ),
        DataCell(
          Text(
            interaction.promisedAmountCents != null
                ? '\$${interaction.promisedAmount.toStringAsFixed(2)}'
                : '—',
            style: TextStyle(color: AppColors.inkPrimaryColor(isDark)),
          ),
        ),
      ],
    );
  }
}

class _RecoveryCardList extends ConsumerWidget {
  const _RecoveryCardList({required this.interactions});

  final List<Interaction> interactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(filteredCustomersProvider);
    final debts = ref.watch(filteredDebtsProvider);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: interactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final interaction = interactions[index];
        final customer = _resolveCustomer(interaction.customerId, customers);
        final debt = _resolveDebt(interaction.debtId, debts);
        return _RecoveryLogCard(
          interaction: interaction,
          customer: customer,
          debt: debt,
        );
      },
    );
  }
}

class _RecoveryLogCard extends StatelessWidget {
  const _RecoveryLogCard({
    required this.interaction,
    required this.customer,
    required this.debt,
  });

  final Interaction interaction;
  final Customer? customer;
  final Debt? debt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactDate = interaction.effectiveContactDate;
    final dateStr =
        '${contactDate.year}-${contactDate.month.toString().padLeft(2, '0')}-${contactDate.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkCardColor(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtleColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  customer?.fullName ?? 'Unknown Customer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.inkPrimaryColor(isDark),
                  ),
                ),
              ),
              _OutcomeChip(outcome: interaction.outcome),
            ],
          ),
          if (debt != null) ...[
            const SizedBox(height: 2),
            Text(
              debt!.referenceNumber,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.inkSecondaryColor(isDark),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _ChannelChip(channel: interaction.actionType),
              const SizedBox(width: 8),
              Icon(
                Icons.schedule,
                size: 14,
                color: AppColors.inkSecondaryColor(isDark),
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkSecondaryColor(isDark),
                ),
              ),
            ],
          ),
          if (interaction.followUpDate != null ||
              interaction.promisedAmountCents != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (interaction.followUpDate != null)
                  _DetailPill(
                    icon: Icons.event,
                    label: 'Follow-up ${_formatDate(interaction.followUpDate!)}',
                  ),
                if (interaction.promisedAmountCents != null)
                  _DetailPill(
                    icon: Icons.payments_outlined,
                    label:
                        'Promised \$${interaction.promisedAmount.toStringAsFixed(2)}',
                  ),
              ],
            ),
          ],
          if ((interaction.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              interaction.notes!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.inkSecondaryColor(isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.brandAccent : AppColors.brandPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.brandAccent : AppColors.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({required this.channel});

  final String channel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.inkSecondaryColor(isDark).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _channelIcon(channel),
            size: 14,
            color: AppColors.inkSecondaryColor(isDark),
          ),
          const SizedBox(width: 5),
          Text(
            InteractionChannel.label(channel),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSecondaryColor(isDark),
            ),
          ),
        ],
      ),
    );
  }

  IconData _channelIcon(String channel) {
    switch (channel) {
      case InteractionChannel.call:
        return Icons.call;
      case InteractionChannel.fieldVisit:
        return Icons.location_on;
      case InteractionChannel.email:
        return Icons.email;
      case InteractionChannel.sms:
        return Icons.sms;
      case InteractionChannel.officeVisit:
        return Icons.business;
      default:
        return Icons.contact_phone;
    }
  }
}

class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.outcome});

  final String outcome;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _outcomeColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        outcome,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _outcomeColor() {
    switch (outcome) {
      case InteractionOutcome.paymentReceived:
        return AppColors.success;
      case InteractionOutcome.promisedToPay:
        return AppColors.warning;
      case InteractionOutcome.escalated:
      case InteractionOutcome.disputed:
        return AppColors.accentDanger;
      case InteractionOutcome.leftMessage:
      case InteractionOutcome.callbackRequested:
        return AppColors.accentInfo;
      case InteractionOutcome.noResponse:
      default:
        return AppColors.inkMuted;
    }
  }
}

Customer? _resolveCustomer(String customerId, List<Customer> customers) {
  for (final customer in customers) {
    if (customer.id == customerId) return customer;
  }
  return null;
}

Debt? _resolveDebt(String debtId, List<Debt> debts) {
  for (final debt in debts) {
    if (debt.id == debtId) return debt;
  }
  return null;
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}