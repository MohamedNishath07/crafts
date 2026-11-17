import 'financial_report_query.dart';

import '../../../core/sqlitedatabase.dart';

class ReportRepository {
  final SQLiteDatabase _db = SQLiteDatabase();

  /// Fetch financial report rows based on query parameters
  Future<List<FinancialReportRow>> fetchReportRows(FinancialReportQuery query) async {
    final response = await _db.fetchInteractions(query.tenantId);
    // Filter by date range
    final filtered = response.where((row) {
      final paymentDate = row['created_at'] as String?;
      if (paymentDate == null) return false;
      final date = DateTime.tryParse(paymentDate);
      if (date == null) return false;
      if (query.startDate != null && date.isBefore(query.startDate!)) return false;
      if (query.endDate != null && date.isAfter(query.endDate!)) return false;
      return true;
    }).toList();

    // Apply status filter
    final statusFiltered = query.statusFilter != null && query.statusFilter != 'All'
        ? filtered.where((row) => row['outcome'] == query.statusFilter).toList()
        : filtered;

    // Apply officer filter
    final officerFiltered = query.officerFilter != null
        ? statusFiltered.where((row) => row['officer_id'] == query.officerFilter).toList()
        : statusFiltered;

    return officerFiltered
        .map((json) => FinancialReportRow.fromMap(
            Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Fetch summary totals for financial reports
  Future<FinancialReportSummary> fetchReportSummary(FinancialReportQuery query) async {
    final response = await _db.fetchInteractions(query.tenantId);
    // Filter by date range
    final filtered = response.where((row) {
      final paymentDate = row['created_at'] as String?;
      if (paymentDate == null) return false;
      final date = DateTime.tryParse(paymentDate);
      if (date == null) return false;
      if (query.startDate != null && date.isBefore(query.startDate!)) return false;
      if (query.endDate != null && date.isAfter(query.endDate!)) return false;
      return true;
    }).toList();

    final totalBilled = filtered.fold<double>(0.0,
        (sum, row) => sum + (row['principal_amount_cents'] ?? 0) / 100.0);
    final totalCollected = filtered.fold<double>(0.0,
        (sum, row) => sum + (row['amount_cents'] ?? 0) / 100.0);
    final totalOutstanding = totalBilled - totalCollected;

    return FinancialReportSummary(
      totalBilled: totalBilled,
      totalCollected: totalCollected,
      totalOutstanding: totalOutstanding,
      totalRecords: filtered.length,
    );
  }
}