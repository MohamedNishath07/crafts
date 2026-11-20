import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:credit_recovery_system/core/constants/app_colors.dart';
import 'package:credit_recovery_system/core/sqlitedatabase.dart';

enum ReportFilterStatus { all, current, overdue, settled }

class DashboardReportScreen extends StatefulWidget {
  const DashboardReportScreen({super.key});
  @override
  State<DashboardReportScreen> createState() => _DashboardReportScreenState();
}

class _DashboardReportScreenState extends State<DashboardReportScreen> {
  ReportFilterStatus _selectedFilter = ReportFilterStatus.all;
  List<Map<String, dynamic>> _reportRows = [];
  bool _isLoading = false;
  double _totalAmount = 0.0;
  String? _error;
  late SQLiteDatabase _sqliteDatabase;
  final String _currentTenantId = 'default_tenant';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _sqliteDatabase = SQLiteDatabase();
    _fetchDebtsAndGenerateReport();
  }

  Future<void> _fetchDebtsAndGenerateReport() async {
    setState(() => _isLoading = true);
    try {
      final debtsData = await (await _sqliteDatabase.database).query(
        'debts',
        where: 'tenant_id = ?',
        whereArgs: [_currentTenantId],
      );
      setState(() {
        _reportRows = debtsData;
        _calculateTotal();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotal() {
    final total = _reportRows.fold(0.0, (s, r) => s + (r['amount'] ?? 0));
    setState(() => _totalAmount = total);
  }

  String _getFilterStatusLabel(ReportFilterStatus s) =>
      s == ReportFilterStatus.all ? 'All' :
      s == ReportFilterStatus.current ? 'Current' :
      s == ReportFilterStatus.overdue ? 'Overdue' : 'Settled';

  Widget _buildFilterToolbar(BuildContext ctx) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Filter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ReportFilterStatus.values.map((status) {
              final selected = _selectedFilter == status;
              return FilterChip(
                label: Text(_getFilterStatusLabel(status)),
                selected: selected,
                onSelected: (s) {
                  setState(() => _selectedFilter = s ? status : ReportFilterStatus.all);
                },
                selectedColor: AppColors.brandPrimary,
                checkmarkColor: AppColors.surfaceBase,
                backgroundColor: AppColors.surfaceRaised,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date Range'),
            subtitle: _startDate != null
                ? Text('${DateFormat('MMM dd, yyyy').format(_startDate!)}-${DateFormat('MMM dd, yyyy').format(_endDate!)}', style: const TextStyle(fontSize: 12))
                : const Text('Not set'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDateRange(ctx),
          ),
        ],
      ),
    ),
  );

  Future<void> _selectDateRange(BuildContext ctx) async {
    final picked = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterRow = _buildFilterToolbar(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.brandPrimary,
        elevation: 0,
        title: const Text('Reports', style: TextStyle(color: AppColors.surfaceBase, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surfaceBase),
            onPressed: _fetchDebtsAndGenerateReport,
            tooltip: 'Refresh report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? const Center(child: Text('Error occurred'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      filterRow,
                      const SizedBox(height: 24),
                      const Text('Debt Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Total rows: ${_reportRows.length}, Total amount: $_totalAmount',
                          style: const TextStyle(fontSize: 14, color: AppColors.inkSecondary)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
