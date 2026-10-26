import 'package:flutter/material.dart';

import '../data/financial_report_query.dart';

/// Action buttons for exporting reports (PDF and Excel)
class ExportActionButtons extends StatelessWidget {
  final FinancialReportQuery? query;
  final VoidCallback? onPdfExport;
  final VoidCallback? onExcelExport;

  const ExportActionButtons({
    super.key,
    this.query,
    this.onPdfExport,
    this.onExcelExport,
  });

  @override
  Widget build(BuildContext context) {
    final canExport = query != null;

    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: canExport && onPdfExport != null
              ? onPdfExport
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          label: const Text('Export PDF'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        OutlinedButton.icon(
          onPressed: canExport && onExcelExport != null
              ? onExcelExport
              : null,
          icon: const Icon(Icons.insert_chart),
          label: const Text('Export Excel'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}