import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/audit/audit_model.dart';
import 'package:crafts/features/audit/audit_provider.dart';
import 'package:crafts/core/auth/current_user_provider.dart';
import 'package:intl/intl.dart';

/// Widget that displays the audit log viewer screen
class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final auditLogs = ref.watch(auditProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Logs',
            onPressed: () {
              // TODO: Show filter bottom sheet
            },
          ),
        ],
      ),
      body: auditLogs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        empty: () => const Center(
          child: Text('No audit logs found'),
        ),
        data: (logs) => _buildAuditContent(context, logs, ref),
      ),
    );
  }

  Widget _buildAuditContent(
      BuildContext context, List<AuditLogEntry> logs, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats
          _buildSummaryStats(context, logs),
          const SizedBox(height: 24),
          // Audit logs list
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text('No audit logs found'))
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildAuditLogEntry(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, List<AuditLogEntry> logs) {
    final totalActions = logs.length;
    final pdfExports = logs.where((l) => l.actionType == AuditActionTypes.reportExportedPdf).length;
    final excelExports = logs.where((l) => l.actionType == AuditActionTypes.reportExportedExcel).length;
    final lastAction = logs.isNotEmpty ? logs.first.timestamp : DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Summary',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(
                  title: 'Total Actions',
                  value: totalActions.toString(),
                  icon: Icons.history,
                  color: AppColors.brandPrimary,
                ),
                _StatCard(
                  title: 'PDF Exports',
                  value: pdfExports.toString(),
                  icon: Icons.picture_as_pdf,
                  color: PdfColor(0xFF1A73E8),
                ),
                _StatCard(
                  title: 'Excel Exports',
                  value: excelExports.toString(),
                  icon: Icons.grid_on,
                  color: PdfColor(0xFF27AE60),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last action: ${DateFormat('MMM dd, yyyy - HH:mm').format(lastAction)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }