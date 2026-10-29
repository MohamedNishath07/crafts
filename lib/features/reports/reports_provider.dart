import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crafts/features/reports/reports_model.dart';

/// Provider for reports state
final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportsModel>((ref) {
  return ReportsNotifier();
});

/// Notifier for reports state management
class ReportsNotifier extends StateNotifier<ReportsModel> {
  ReportsNotifier() : super(ReportsModel.loading());

  Future<void> loadReports({
    DateTimeRange<DateTime>? dateRange,
    String? status,
    String? officer,
  }) async {
    state = state.copyWith(isLoading: true, hasError: false, errorMessage: '');
    try {
      final supabase = Supabase.instance.client;

      var query = supabase.from('debts').select();
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (officer != null && officer.isNotEmpty) {
        query = query.eq('officer_name', officer);
      }
      if (dateRange != null) {
        query = query
            .gte('created_at', dateRange.start.toIso8601String())
            .lte('created_at', dateRange.end.toIso8601String());
      }

      final data = await query;
      final reports = (data as List).map((row) {
        return ReportItem(
          id: row['id'] is int
              ? row['id'] as int
              : int.tryParse(row['id'].toString()) ?? 0,
          date: row['created_at'] != null
              ? DateTime.parse(row['created_at'].toString())
              : DateTime.now(),
          debtStatus: row['status']?.toString() ?? 'Unknown',
          amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
          officerName: row['officer_name']?.toString() ?? '',
          customerName: row['customer_name']?.toString() ?? '',
        );
      }).toList();

      final totalBilled = reports.fold<double>(0.0, (s, r) => s + r.amount);
      final totalCollected = reports
          .where((r) => r.debtStatus.toLowerCase() == 'settled')
          .fold<double>(0.0, (s, r) => s + r.amount);
      final totalOutstanding = totalBilled - totalCollected;

      state = state.copyWith(
        isLoading: false,
        reports: reports,
        totalBilled: totalBilled,
        totalCollected: totalCollected,
        totalOutstanding: totalOutstanding,
        dateRange: dateRange,
        selectedStatus: status,
        selectedOfficer: officer,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> generateReport({
    required DateTimeRange<DateTime> dateRange,
    required String status,
    required String officer,
  }) async {
    await loadReports(
      dateRange: dateRange,
      status: status,
      officer: officer,
    );
  }
}