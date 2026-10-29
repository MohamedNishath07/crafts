import 'package:intl/intl.dart';

/// Report filter options for date range and status
class ReportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status; // 'current', 'overdue', 'settled', or null for all

  ReportFilter({
    this.startDate,
    this.endDate,
    this.status,
  });

  factory ReportFilter.fromDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? status,
  }) {
    return ReportFilter(
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
  }

  /// Check if a debt date falls within this filter range
  bool includes(DateTime date) {
    if (startDate != null && date.isBefore(startDate!)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    return true;
  }

  /// Check if a status matches this filter
  bool matchesStatus(bool isCurrent, bool isOverdue, bool isSettled) {
    if (status == null) return true;
    switch (status) {
      case 'current':
        return isCurrent && !isOverdue && !isSettled;
      case 'overdue':
        return isOverdue;
      case 'settled':
        return isSettled;
      default:
        return true;
    }
  }
}

/// Model for a report row
class ReportRow {
  final String id;
  final String customerName;
  final double amount;
  final String status;
  final DateTime date;
  final bool isCurrent;
  final bool isOverdue;
  final bool isSettled;

  ReportRow({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.date,
    required this.isCurrent,
    required this.isOverdue,
    required this.isSettled,
  });

  /// Convert to a map for export
  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'Customer': customerName,
      'Amount': amount,
      'Status': status,
      'Date': DateFormat('yyyy-MM-dd').format(date),
    };
  }
}

/// Generates a tabular report from dashboard metrics and debt data
/// This is a base class that can be extended for PDF/Excel generation
abstract class TabularReportGenerator {
  /// Generate report rows based on filter
  static List<ReportRow> generateRows({
    required List<dynamic> debts,
    required ReportFilter filter,
  }) {
    final rows = <ReportRow>[];

    for (final debt in debts) {
      final balance = (debt['balance'] ?? 0.0) as double;
      final isOverdue = debt['overdue'] == true;
      final isSettled = debt['status']?.toString().toLowerCase() == 'settled' || balance == 0;
      final isCurrent = !isOverdue && !isSettled; // simplified: if not overdue and not settled, it's current

      // Apply status filter
      if (!filter.matchesStatus(isCurrent, isOverdue, isSettled)) {
        continue;
      }

      // Apply date filter
      final date = debt['date'] != null
          ? (debt['date'] as dynamic).toDate()
          : DateTime.now();

      if (!filter.includes(date)) {
        continue;
      }

      final id = debt['id']?.toString() ?? '';
      final customerName = debt['customer_name']?.toString() ?? 'Unknown';

      rows.add(ReportRow(
        id: id,
        customerName: customerName,
        amount: balance,
        status: isOverdue ? 'Overdue' : (isSettled ? 'Settled' : 'Current'),
        date: date,
        isCurrent: isCurrent,
        isOverdue: isOverdue,
        isSettled: isSettled,
      ));
    }

    return rows;
  }
}