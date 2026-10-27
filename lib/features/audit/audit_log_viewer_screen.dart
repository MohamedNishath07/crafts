import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/core/constants/app_colors.dart';
import 'package:crafts/features/audit/audit_log_notifier.dart';
import 'package:crafts/features/audit/audit_log_model.dart';

/// Screen for viewing and filtering audit logs (Admin only)
class AuditLogViewerScreen extends ConsumerWidget {
  const AuditLogViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(auditLogNotifierProvider);
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, ref, notifier),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.brandPrimary,
      elevation: 0,
      title: const Text(
        'Audit Log Viewer',
        style: TextStyle(color: AppColors.surfaceBase, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: AppColors.surfaceBase),
          onPressed: () => _showFilterDialog(context, ref),
          tooltip: 'Filter logs',
        ),
      ],
    );
  }

  Widget _buildFilterToolbar(
      BuildContext context, AuditLogNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action filter
          _buildFilterRow(
            context,
            label: 'Action',
            value: notifier.action ?? 'All',
            onChanged: (value) => notifier.setActionFilter(value),
            hint: 'Select action type',
          ),
          const SizedBox(height: 12),

          // Entity type filter
          _buildFilterRow(
            context,
            label: 'Entity Type',
            value: notifier.entityType ?? 'All',
            onChanged: (value) => notifier.setEntityTypeFilter(value),
            hint: 'Select entity type',
          ),
          const SizedBox(height: 12),

          // Date range filter
          _buildDateRangeFilter(context, notifier),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
      BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      value: value.isNotEmpty ? value : null,
      onChanged: onChanged,
      items: _buildFilterItems(value),
    );
  }

  List<DropdownMenuItem<String>> _buildFilterItems(String currentValue) {
    return [
      const DropdownMenuItem(
        value: '',
        child: Text('All'),
      ),
      const DropdownMenuItem(
        value: 'user_login',
        child: Text('User Login'),
      ),
      const DropdownMenuItem(
        value: 'user_logout',
        child: Text('User Logout'),
      ),
      const DropdownMenuItem(
        value: 'payment_recorded',
        child: Text('Payment Recorded'),
      ),
      const DropdownMenuItem(
        value: 'payment_adjustment',
        child: Text('Payment Adjustment'),
      ),
      const DropdownMenuItem(
        value: 'debt_modification',
        child: Text('Debt Modification'),
      ),
      const DropdownMenuItem(
        value: 'staff_role_change',
        child: Text('Staff Role Change'),
      ),
    ];
  }

  Widget _buildDateRangeFilter(
      BuildContext context, AuditLogNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<DateTime?>(
            decoration: const InputDecoration(
              labelText: 'Start Date',
              border: OutlineInputBorder(),
            ),
            value: notifier.startDate,
            onChanged: (DateTime? newDate) {
              if (newDate != null) {
                notifier.setDateRange(newDate, notifier.endDate);
              }
            },
            items: _buildDateItems(notifier.startDate),
            hintText: 'Select start date',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<DateTime?>(
            decoration: const InputDecoration(
              labelText: 'End Date',
              border: OutlineInputBorder(),
            ),
            value: notifier.endDate,
            onChanged: (DateTime? newDate) {
              if (newDate != null) {
                notifier.setDateRange(notifier.startDate, newDate);
              }
            },
            items: _buildDateItems(notifier.endDate),
            hintText: 'Select end date',
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<DateTime?>> _buildDateItems(DateTime? selected) {
    final now = DateTime.now();
    final items = <DateTime?>[
      null,
      now.subtract(const Duration(days: 7)),
      now.subtract(const Duration(days: 30)),
      now.subtract(const Duration(days: 90)),
      now.subtract(const Duration(days: 365)),
    ];

    return items.map((date) => DropdownMenuItem<DateTime?>(
      value: date,
      child: Text(
        date == null ? 'All' : '${date.month}/${date.day} (${_daysAgo(date)})',
      ),
    )).toList();
  }

  String _daysAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays >= 365) {
      return '${diff.inDays ~/ 365}y';
    } else if (diff.inDays >= 30) {
      return '${diff.inDays ~/ 30}m';
    } else if (diff.inDays >= 7) {
      return '${diff.inDays ~/ 7}w';
    }
    return '${diff.inDays}d';
  }

  Widget _buildLogsList(
      BuildContext context, WidgetRef ref, AuditLogNotifier notifier) {
    return const Center(
      child: Text('Logs list will be implemented'),
    );
  }
}