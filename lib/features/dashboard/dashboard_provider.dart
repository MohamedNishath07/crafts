import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sqlitedatabase.dart';

/// Async value state for dashboard metrics
class DashboardMetricsState {
  final bool isLoading;
  final String? error;
  final DashboardMetrics? metrics;

  DashboardMetricsState({
    this.isLoading = false,
    this.error,
    this.metrics,
  });

  factory DashboardMetricsState.loading() => DashboardMetricsState(isLoading: true);
  factory DashboardMetricsState.success({
    required int totalCustomers,
    required double totalDebt,
    required double overdueBalance,
    required double recoveredAmount,
  }) => DashboardMetricsState(
      metrics: DashboardMetrics(
        totalCustomers: totalCustomers,
        totalDebt: totalDebt,
        overdueBalance: overdueBalance,
        recoveredAmount: recoveredAmount,
      ),
    );
  factory DashboardMetricsState.error(String message) => DashboardMetricsState(
        error: message,
      );

  bool get hasError => error != null;
  String? get errorMessage => error;
}

/// Model class for dashboard metrics
class DashboardMetrics {
  final int totalCustomers;
  final double totalDebt;
  final double overdueBalance;
  final double recoveredAmount;

  DashboardMetrics({
    required this.totalCustomers,
    required this.totalDebt,
    required this.overdueBalance,
    required this.recoveredAmount,
  });
}

/// Notifier for dashboard metrics using StateNotifier
class DashboardMetricsNotifier extends Notifier<DashboardMetricsState> {
  @override
  DashboardMetricsState build() => DashboardMetricsState.loading();

  /// Fetch dashboard metrics from SQLite local database
  Future<void> fetchDashboardMetrics() async {
    state = DashboardMetricsState.loading();
    try {
      final db = SQLiteDatabase();
      final user = await _getCurrentUser();
      final tenantId = user?['tenant_id'] as String? ?? 'default_tenant';

      final customerData = await db.fetchCustomers(tenantId);
      final totalCustomers = customerData.length;

      final debtData = await db.fetchDebts(tenantId);
      final totalDebt = debtData.fold(0.0, (sum, d) => sum + (d['remaining_balance_cents'] ?? 0) / 100.0);
      final overdueBalance = debtData
          .where((d) => d['status'] == 'active')
          .fold<double>(0.0, (sum, d) => sum + (d['remaining_balance_cents'] ?? 0) / 100.0);

      final paymentData = await db.fetchPayments(tenantId);
      final recoveredAmount = paymentData.fold<double>(0.0, (sum, p) => sum + (p['amount_cents'] ?? 0) / 100.0);

      state = DashboardMetricsState.success(
        totalCustomers: totalCustomers,
        totalDebt: totalDebt,
        overdueBalance: overdueBalance,
        recoveredAmount: recoveredAmount,
      );
    } catch (e) {
      state = DashboardMetricsState.error(e.toString());
    }
  }

  /// Refresh dashboard metrics
  Future<void> refresh() async {
    await fetchDashboardMetrics();
  }

  Future<Map<String, dynamic>?> _getCurrentUser() async {
    // In a real implementation, this would integrate with auth
    // For now, return null and use default tenant
    return null;
  }
}

/// Provider for dashboard metrics notifier
final dashboardMetricsNotifierprovider = NotifierProvider<DashboardMetricsNotifier, DashboardMetricsState>(
  DashboardMetricsNotifier.new,
);