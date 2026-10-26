import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/financial_report_query.dart';

class ReportFilterToolbar extends StatefulWidget {
  final FinancialReportQuery? initialQuery;
  final ValueChanged<FinancialReportQuery> onQueryChanged;
  final String? selectedOfficer;
  final ValueChanged<String?> onOfficerChanged;

  const ReportFilterToolbar({
    super.key,
    this.initialQuery,
    required this.onQueryChanged,
    this.selectedOfficer,
    required this.onOfficerChanged,
  });

  @override
  State<ReportFilterToolbar> createState() => _ReportFilterToolbarState();
}

class _ReportFilterToolbarState extends State<ReportFilterToolbar> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialQuery?.startDate ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    _endDate = widget.initialQuery?.endDate ??
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(context, _startDate, (d) =>
                      setState(() => _startDate = d), false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDatePicker(context, _endDate, (d) =>
                      setState(() => _endDate = d), false),
                ),
              ],
            ),
            if (_startDate.day != 1 ||
                _endDate.day != 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Selected: ${_startDate.toLocal().toString().split(' ').first} - ${_endDate.toLocal().toString().split(' ').first}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
      BuildContext context, DateTime selected, Function(DateTime) onSelected,
      bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null && picked != selected) {
          onSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Text(
            _formatDate(selected),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat.yMMMd();
    return formatter.format(date);
  }
}