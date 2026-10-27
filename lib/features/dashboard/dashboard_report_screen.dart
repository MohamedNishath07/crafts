import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crafts/core/constants/app_colors.dart';
import 'package:crafts/features/dashboard/dashboard_report_controller.dart';

enum ReportFilterStatus { all, current, overdue, settled }

class DashboardReportScreen extends StatefulWidget {
  const DashboardReportScreen({super.key});

  @override
  State<DashboardReportScreen> createState() => _DashboardReportScreenState();
}

class _DashboardReportScreenState extends State<DashboardReportScreen> {
  ReportFilterStatus _selectedFilter = ReportFilterStatus.all;
  DateTime? _startDate;
  DateTime? _endDate;

  List<ReportRow> _reportRows = [];
  bool _isLoading = false;
  String? _error;
  double _totalAmount = 0.0;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchDebtsAndGenerateReport();
  }

  Future<void> _fetchDebtsAndGenerateReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = _supabase.auth.currentUser;
      final tenantId = user?.appMetadata['tenant_id'] as String? ?? 'default_tenant';
      final debtsData = await _supabase.from('debts').select().eq('tenant_id', tenantId);
      final allRows = ReportFilter.generateRows(
        debts: debtsData,
        filter: ReportFilter(),
      );
      setState(() {
        _reportRows = allRows;
        _calculateTotal();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotal() {
    final total = _reportRows.fold(0.0, (sum, row) => sum + row.amount);
    setState(() => _totalAmount = total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.brandPrimary,
        elevation: 0,
        title: const Text(
          'Reports',
          style: TextStyle(color: AppColors.surfaceBase, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surfaceBase),
            onPressed: _fetchDebtsAndGenerateReport,
            tooltip: 'Refresh report',
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error occurred'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchDebtsAndGenerateReport, child: const Text('Retry')),
          ],
        ),
      );
    }

    final filterRow = _buildFilterToolbar(context);
    final dataTable = _buildDataTable(context);
    final exportSection = _buildExportSection(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filterRow,
          const SizedBox(height: 24),
          const Text(
            'Debt Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Total rows: $_reportRows, Total amount: $_totalAmount',
            style: const TextStyle(fontSize: 14, color: AppColors.inkSecondary),
          ),
          const SizedBox(height: 24),
          dataTable,
          const SizedBox(height: 24),
          exportSection,
        ],
      ),
    );
  }

  String _getFilterStatusLabel(ReportFilterStatus status) {
    switch (status) {
      case ReportFilterStatus.current:
        return 'Current';
      case ReportFilterStatus.overdue:
        return 'Overdue';
      case ReportFilterStatus.settled:
        return 'Settled';
      case ReportFilterStatus.all:
        return 'All';
    }
  }

  Widget _buildFilterToolbar(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Filter',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ReportFilterStatus.values.map((status) {
                final isSelected = _selectedFilter == status;
                return FilterChip(
                  label: Text(_getFilterStatusLabel(status)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = selected ? status : ReportFilterStatus.all;
                    });
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
                  ? Text(
                      '${DateFormat('MMM dd, yyyy').format(_startDate!)}-${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                      style: const TextStyle(fontSize: 12),
                    )
                  : const Text('Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDateRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(duration: Duration(days: 1)),
      currentRangeStart: _startDate,
      currentRangeEnd: _endDate,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_reportRows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }
    // TODO: Implement PDF export using pdf package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export feature coming soon')),
    );
  }

  Future<void> _exportExcel() async {
    if (_reportRows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }
    // TODO: Implement Excel export using excel package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel export feature coming soon')),
    );
  }
}
    if (_reportRows.isEmpty) {
      return const Center(
        child: Text(
          'No data found matching the current filter criteria.',
          style: TextStyle(fontSize: 16, color: AppColors.inkSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceRaised),
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
        ],
        rows: _reportRows.map((row) => DataRow(cells: [
          DataCell(Text(row.id)),
          DataCell(Text(row.customerName)),
          DataCell(Text('\$${row.amount.toStringAsFixed(2)}')),
          DataCell(Text(row.status)),
          DataCell(Text(DateFormat('yyyy-MM-dd').format(row.date))),
        ])).toList(),
      ),
    );
  }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error occurred'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchDebtsAndGenerateReport, child: const Text('Retry')),
          ],
        ),
      );
    }

    final filterRow = _buildFilterToolbar(context);
    final dataTable = _buildDataTable(context);
    final exportSection = _buildExportSection(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filterRow,
          const SizedBox(height: 24),
          const Text(
            'Debt Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Total rows: $_reportRows, Total amount: $_totalAmount',
            style: const TextStyle(fontSize: 14, color: AppColors.inkSecondary),
          ),
          const SizedBox(height: 24),
          dataTable,
          const SizedBox(height: 24),
          exportSection,
        ],
      ),
    );
  }