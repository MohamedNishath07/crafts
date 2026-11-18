import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sqlitedatabase.dart';
import 'data/dashboard_repository.dart';

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
  }) =>
      DashboardMetricsState(
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

/// Notifier for dashboard metrics using Notifier
class DashboardMetricsNotifier extends Notifier<DashboardMetricsState> {
  @override
  DashboardMetricsState build() {
    Future.microtask(() => fetchDashboardMetrics());
    return DashboardMetricsState.loading();
  }

  /// Fetch dashboard metrics from SQLite local database
  Future<void> fetchDashboardMetrics() async {
    state = DashboardMetricsState.loading();
    try {
      final repo = DashboardRepository(SQLiteDatabase());
      final metrics = await repo.fetchOverviewMetrics('a0000000-0000-0000-0000-000000000001');

      state = DashboardMetricsState.success(
        totalCustomers: metrics.totalCustomers,
        totalDebt: metrics.totalCreditAmount,
        overdueBalance: metrics.overdueBalance,
        recoveredAmount: metrics.totalCollectedAmount,
      );
    } catch (e) {
      state = DashboardMetricsState.error(e.toString());
    }
  }

  /// Refresh dashboard metrics
  Future<void> refresh() async {
    await fetchDashboardMetrics();
  }
}

/// Provider for dashboard metrics notifier
final dashboardMetricsNotifierprovider =
    NotifierProvider<DashboardMetricsNotifier, DashboardMetricsState>(
  DashboardMetricsNotifier.new,
);
