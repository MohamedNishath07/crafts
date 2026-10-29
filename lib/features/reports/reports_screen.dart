import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crafts/core/constants/app_colors.dart';
import 'package:crafts/features/reports/reports_provider.dart';
import 'package:crafts/features/reports/reports_model.dart';

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
              showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const SizedBox(height: 200, child: Center(child: Text("Filter"))),);
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () async {
              final reportsState = ref.read(reportsProvider);
              
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

              // Save PDF to a temporary file so it can be opened
              final tempDir = await getTemporaryDirectory();
              final fileName = '${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
              final file = File('${tempDir.path}/$fileName');
              await file.writeAsBytes(pdfBytes);

              if (!context.mounted) return;

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'PDF generated: ${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                  ),
                    action: SnackBarAction(
                      label: 'Open',
                      onPressed: () async {
                        final uri = Uri.file(file.path);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                ),
              );
            },
          ),
        ],
      ),
      body: reportsState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : reportsState.hasError
               ? Center(child: Text(reportsState.errorMessage))
               : reportsState.reports.isEmpty
                   ? const Center(child: Text('No reports found'))
                   : _buildReportsContent(context, reportsState),





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
      initialValue: 'All',
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
                        _buildReportRow('Total Billed', '\$${report.amount.toStringAsFixed(2)}'),
                        _buildReportRow('Total Collected', '\$${report.amount.toStringAsFixed(2)}'),
                        _buildReportRow('Total Outstanding', '\$${report.amount.toStringAsFixed(2)}'),
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

  Future<List<int>> _generateAndSavePdf() async {
    final pdfDoc = pw.Document();
    pdfDoc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Center(
          child: pw.Text('PDF Generated'),
        ),
      ),
    );
    return await pdfDoc.save();
  }
}
