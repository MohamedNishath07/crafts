import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/audit/audit_model.dart';
import 'package:crafts/features/audit/audit_provider.dart';

import 'package:crafts/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

/// Widget that displays the audit log viewer screen
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  String? _selectedActionType;
  DateTime? _startDate;
  DateTime? _endDate;

  List<AuditLogEntry> _applyFilters(List<AuditLogEntry> logs) {
    return logs.where((log) {
      if (_selectedActionType != null && log.actionType != _selectedActionType) {
        return false;
      }
      if (_startDate != null && log.timestamp.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && log.timestamp.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _showFilterBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        String? tempActionType = _selectedActionType;
        DateTime? tempStart = _startDate;
        DateTime? tempEnd = _endDate;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Audit Logs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: tempActionType,
                    decoration: const InputDecoration(labelText: 'Action Type'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...[
                        AuditActionTypes.reportGenerated,
                        AuditActionTypes.reportExportedPdf,
                        AuditActionTypes.reportExportedExcel,
                        AuditActionTypes.filterApplied,
                        AuditActionTypes.filterCleared,
                        AuditActionTypes.userLoggedIn,
                        AuditActionTypes.userLoggedOut,
                        AuditActionTypes.settingChanged,
                        AuditActionTypes.errorOccurred,
                      ].map((type) => DropdownMenuItem<String?>(
                            value: type,
                            child: Text(type),
                          )),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => tempActionType = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempStart ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() => tempStart = picked);
                            }
                          },
                          child: Text(
                            tempStart == null
                                ? 'Start Date'
                                : DateFormat('MMM dd, yyyy').format(tempStart!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempEnd ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() => tempEnd = picked);
                            }
                          },
                          child: Text(
                            tempEnd == null
                                ? 'End Date'
                                : DateFormat('MMM dd, yyyy').format(tempEnd!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedActionType = null;
                            _startDate = null;
                            _endDate = null;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedActionType = tempActionType;
                            _startDate = tempStart;
                            _endDate = tempEnd;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auditLogs = ref.watch(auditProvider);
    final filteredLogs = _applyFilters(auditLogs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Logs',
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: _buildAuditContent(context, filteredLogs, ref),
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
                  color: Color(0xFF1A73E8),
                ),
                _StatCard(
                  title: 'Excel Exports',
                  value: excelExports.toString(),
                  icon: Icons.grid_on,
                  color: Color(0xFF27AE60),
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
  Widget _buildAuditLogEntry(AuditLogEntry log) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(log.actionType),
        subtitle: Text(log.description),
        trailing: Text(DateFormat('MMM dd, HH:mm').format(log.timestamp)),
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
