import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:credit_recovery_system/core/sqlitedatabase.dart';
import 'package:credit_recovery_system/features/reports/reports_model.dart';

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsModel>((ref) {
  return ReportsNotifier();
});

class ReportsNotifier extends StateNotifier<ReportsModel> {
  ReportsNotifier() : super(ReportsModel.loading());

  Future<void> loadReports({
    DateTimeRange<DateTime>? dateRange,
    String? status,
    String? officer,
  }) async {
    state = state.copyWith(isLoading: true, hasError: false, errorMessage: '');
    try {
      final sqldb = SQLiteDatabase();
      final db = await sqldb.database;
      final tenantId = await _getTenantId();
      var query = await db.query(
        'debts',
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
      );
      if (status != null && status.isNotEmpty) {
        query = await db.query(
          'debts',
          where: 'tenant_id = ? AND status = ?',
          whereArgs: [tenantId, status],
        );
      }
      if (officer != null && officer.isNotEmpty) {
        query = await db.query(
          'debts',
          where: 'tenant_id = ? AND officer_name = ?',
          whereArgs: [tenantId, officer],
        );
      }
      if (dateRange != null) {
        final startStr = dateRange.start.toIso8601String();
        final endStr = dateRange.end.toIso8601String();
        query = await db.query(
          'debts',
          where: 'tenant_id = ? AND created_at >= ? AND created_at <= ?',
          whereArgs: [tenantId, startStr, endStr],
        );
      }

      final reports = (query as List).map((row) {
        return ReportItem(
          id: row['id'] is int
              ? row['id'] as int
              : 0,
          date: row['created_at'] as DateTime,
          debtStatus: row['status'] as String,
          amount: (row['remaining_balance_cents'] as num).toDouble() / 100.0,
          officerName: row['officer_name'] as String? ?? '',
          customerName: row['customer_name'] as String? ?? '',
        );
      }).toList();

      final totalBilled = reports.fold(0.0, (sum, r) => sum + r.amount);
      final totalCollected = reports.fold(0.0, (sum, r) => sum + (r.amount * 0.5));
      final totalOutstanding = totalBilled - totalCollected;

      state = ReportsModel.success(
        reports: reports,
        totalBilled: totalBilled,
        totalCollected: totalCollected,
        totalOutstanding: totalOutstanding,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<String> _getTenantId() async {
    return 'default_tenant';
  }
}

