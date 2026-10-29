import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/financial_report_query.dart';
import '../data/report_repository.dart';
import 'export_action_buttons.dart';
import 'report_filter_toolbar.dart';

/// Main Reports Screen with tabular report generation and export capabilities
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _exportExcel(BuildContext context) async {
    try {
      final repository = ReportRepository();
      final rows = await repository.fetchReportRows(FinancialReportQuery());
      final summary = await repository.fetchReportSummary(FinancialReportQuery());

      final excel = Excel.createExcel();
      final sheet = excel['Financial Report'];

      sheet.appendRow([
        TextCellValue('Customer Name'),
        TextCellValue('Customer ID'),
        TextCellValue('Debt ID'),
        TextCellValue('Original Amount'),
        TextCellValue('Collected Amount'),
        TextCellValue('Outstanding Amount'),
        TextCellValue('Status'),
        TextCellValue('Due Date'),
        TextCellValue('Payment Date'),
        TextCellValue('Officer'),
      ]);

      for (final row in rows) {
        sheet.appendRow([
          TextCellValue(row.customerName),
          TextCellValue(row.customerId),
          TextCellValue(row.debtId),
          DoubleCellValue(row.originalAmount),
          DoubleCellValue(row.collectedAmount),
          DoubleCellValue(row.outstandingAmount),
          TextCellValue(row.status),
          TextCellValue(row.dueDate.toIso8601String()),
          TextCellValue(row.paymentDate?.toIso8601String() ?? ''),
          TextCellValue(row.officerName ?? ''),
        ]);
      }

      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('TOTALS'),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(summary.totalBilled),
        DoubleCellValue(summary.totalCollected),
        DoubleCellValue(summary.totalOutstanding),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/financial_report.xlsx');
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes, flush: true);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportFilterToolbar(
                initialQuery: FinancialReportQuery(),
                onQueryChanged: (query) {},
                selectedOfficer: '',
                onOfficerChanged: (_) {},
              ),
              const SizedBox(height: 24),
              const Text('Report table area - Story 6.1'),
              const SizedBox(height: 24),
              const Text('Summary totals - Story 6.1'),
              const SizedBox(height: 24),
              ExportActionButtons(
                onPdfExport: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF export is not yet implemented.'),
                    ),
                  );
                },
                onExcelExport: () {
                  _exportExcel(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
