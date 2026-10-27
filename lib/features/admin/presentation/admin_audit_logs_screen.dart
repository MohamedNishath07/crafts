import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../audit/audit_log_notifier.dart';
import '../../audit/audit_log_model.dart';

/// Admin screen for viewing and filtering audit logs (Story 7.2)
class AdminAuditLogsScreen extends ConsumerWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(auditLogNotifierProvider);
    final repository = ref.watch(auditLogRepositoryProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, ref, notifier, repository),
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

  Widget _buildBody(
      BuildContext context,
      WidgetRef ref,
      AuditLogNotifier notifier,
      AuditLogRepository repository) {
    return Column(
      children: [
        _buildFilterToolbar(context, notifier),
        Expanded(
          child: _buildLogsList(context, ref, notifier, repository),
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
      BuildContext context, WidgetRef ref, AuditLogNotifier notifier, AuditLogRepository repository) {
    return const Center(
      child: Text('Logs will be loaded'),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.accentDanger,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading audit logs: $error',
            style: const TextStyle(color: AppColors.inkPrimary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.refresh(auditLogNotifierProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.remove_circle_outline,
            color: AppColors.inkSecondary,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No audit logs found',
            style: TextStyle(color: AppColors.inkSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'No audit logs match the current filter criteria.',
            style: const TextStyle(color: AppColors.inkSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogTable(BuildContext context, List<AuditLogEntry> logs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _AuditLogCard(entry: log);
      },
    );
  }
}

/// Card widget for displaying a single audit log entry
class _AuditLogCard extends StatelessWidget {
  final AuditLogEntry entry;

  const _AuditLogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: isDark ? AppColors.surfaceRaised : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with timestamp and action
            Row(
              children: [
                const Icon(
                  Icons.remove_circle_outlined,
                  size: 16,
                  color: AppColors.inkSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _truncateText(log.action, 30),
                    style: TextStyle(
                      color: AppColors.inkPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  _formatTimestamp(entry.createdAt),
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
