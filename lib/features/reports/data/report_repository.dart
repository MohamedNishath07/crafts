import 'package:supabase_flutter/supabase_flutter.dart';
import 'financial_report_query.dart';

class ReportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch financial report rows based on query parameters
  Future<List<FinancialReportRow>> fetchReportRows(
      FinancialReportQuery query) async {
    final queryBuilder = _supabase
        .from('view_financial_reports')
        .select();

    // Apply date filters
    if (query.startDate != null) {
      queryBuilder.gte('payment_date', query.startDate!.toIso8601String());
    }
    if (query.endDate != null) {
      queryBuilder.lte('payment_date', query.endDate!.toIso8601String());
    }

    // Apply status filter
    if (query.statusFilter != null && query.statusFilter != 'All') {
      queryBuilder.eq('status', query.statusFilter as dynamic);
    }

    // Apply officer filter
    if (query.officerFilter != null) {
      queryBuilder.eq('officer_id', query.officerFilter as dynamic);
    }

    final response = await queryBuilder;

    return (response as List)
        .map((json) => FinancialReportRow.fromMap(
            Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Fetch summary totals for financial reports
  Future<FinancialReportSummary> fetchReportSummary(
      FinancialReportQuery query) async {
    final queryBuilder = _supabase
        .from('view_financial_reports')
        .select('''
          original_amount,
          collected_amount,
          status
        ''');

    // Apply date filters
    if (query.startDate != null) {
      queryBuilder.gte('payment_date', query.startDate!.toIso8601String());
    }
    if (query.endDate != null) {
      queryBuilder.lte('payment_date', query.endDate!.toIso8601String());
    }

    final response = await queryBuilder;

    final rows = (response as List)
        .map((json) => Map<String, dynamic>.from(json))
        .toList();

    final totalBilled = rows.fold<double>(0.0,
        (sum, row) => sum + (row['original_amount'] as num).toDouble());
    final totalCollected = rows.fold<double>(0.0,
        (sum, row) => sum + (row['collected_amount'] as num).toDouble());
    final totalOutstanding = totalBilled - totalCollected;

    return FinancialReportSummary(
      totalBilled: totalBilled,
      totalCollected: totalCollected,
      totalOutstanding: totalOutstanding,
      totalRecords: rows.length,
    );
  }
}