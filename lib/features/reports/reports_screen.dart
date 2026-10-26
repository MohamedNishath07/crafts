import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:crafts/core/constants/app_colors.dart';
import 'package:crafts/core/widgets/empty_state.dart';
import 'package:crafts/core/widgets/loading_state.dart';
import 'package:crafts/core/widgets/error_state.dart';
import 'package:crafts/features/reports/reports_provider.dart';
import 'package:crafts/features/reports/reports_model.dart';
import 'package:crafts/features/audit/audit_provider.dart';
import 'package:crafts/features/audit/audit_model.dart';

/// Widget that displays the financial reports screen
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter bottom sheet
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () async {
              final reportsState = ref.read(reportsProvider.notifier).state;
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating PDF...')),
              );

              // Generate PDF
              final pdfWidget = PdfReportPreview(
                reportsModel: reportsState,
                dateRange: reportsState.dateRange,
                selectedStatus: reportsState.selectedStatus,
                selectedOfficer: reportsState.selectedOfficer,
                filteredReports: reportsState.reports,
              );

              final pdfBytes = await pdfWidget._buildPdfBytes();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'PDF generated: ${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                  ),
                  action: SnackBarAction(
                    label: 'Open',
                    onPressed: () {
                      // TODO: Open PDF viewer
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: reportsState.when(
        loading: () => const LoadingState(message: 'Generating report...'),
        error: (error, stack) => ErrorState(
          error: error,
          onRetry: () => ref.read(reportsProvider.notifier).loadReports(),
        ),
        empty: () => const EmptyState(
          icon: Icons.description,
          message: 'No reports found',
        ),
        data: (reports) => _buildReportsContent(context, reports),
      ),
    );
  }

  Widget _buildReportsContent(BuildContext context, ReportsModel reports) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFiltersSection(context),
          const SizedBox(height: 24),
          _buildReportTable(context, reports),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildDateFilter(),
            const SizedBox(height: 12),
            _buildStatusFilter(),
            const SizedBox(height: 12),
            _buildOfficerFilter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return const ListTile(
      title: Text('Date Range'),
      subtitle: Text('Select start and end date'),
      trailing: Icon(Icons.calendar_today),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: 'All',
      decoration: const InputDecoration(
        labelText: 'Debt Status',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All')),
        DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
        DropdownMenuItem(value: 'Settled', child: Text('Settled')),
      ],
      onChanged: (value) {},
    );
  }

  Widget _buildOfficerFilter() {
    return const ListTile(
      title: Text('Officer'),
      subtitle: Text('Select reporting officer'),
      trailing: Icon(Icons.person),
    );
  }

  Widget _buildReportTable(BuildContext context, ReportsModel reports) {
    return Expanded(
      child: reports.reports.isEmpty
          ? const Center(child: Text('No report data available'))
          : ListView.builder(
              itemCount: reports.reports.length,
              itemBuilder: (context, index) {
                final report = reports.reports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report #${report.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildReportRow('Total Billed', '\$${report.totalBilled.toStringAsFixed(2)}'),
                        _buildReportRow('Total Collected', '\$${report.totalCollected.toStringAsFixed(2)}'),
                        _buildReportRow('Total Outstanding', '\$${report.totalOutstanding.toStringAsFixed(2)}'),
                        const Divider(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class PdfReportPreview {
  final ReportsModel reportsModel;
  final DateTimeRange? dateRange;
  final String? selectedStatus;
  final String? selectedOfficer;
  final List<ReportItem>? filteredReports;

  const PdfReportPreview({
    required this.reportsModel,
    this.dateRange,
    this.selectedStatus,
    this.selectedOfficer,
    this.filteredReports,
  });

  Future<List<int>> _buildPdfBytes() async {
    return _generateAndSavePdf();
  }

  List<int> _generateAndSavePdf() {
    final pdfDoc = pw.Document();
    pdfDoc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Center(
          child: pw.Text('PDF Generated'),
        ),
      ),
    );
    return pdfDoc.save();
  }
}