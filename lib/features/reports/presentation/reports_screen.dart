import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/financial_report_query.dart';
import 'report_filter_toolbar.dart';
import 'export_action_buttons.dart';

/// Main Reports Screen with tabular report generation and export capabilities
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

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
              // Filter toolbar
              ReportFilterToolbar(
                initialQuery: FinancialReportQuery(),
                onQueryChanged: (query) {},
                selectedOfficer: '',
                onOfficerChanged: (_) {},
              ),
              const SizedBox(height: 24),

              // Report table area
              const Text('Report table area - Story 6.1'),
              const SizedBox(height: 24),

              // Summary totals
              const Text('Summary totals - Story 6.1'),
              const SizedBox(height: 24),

              // Export buttons
              ExportActionButtons(
                onPdfExport: () {
                  // TODO: Implement PDF export (Story 6.2)
                },
                onExcelExport: () {
                  // TODO: Implement Excel export (Story 6.3)
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
