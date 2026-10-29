import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        isLoading: false,
        metrics: DashboardMetrics(
          totalCustomers: totalCustomers,
          totalDebt: totalDebt,
          overdueBalance: overdueBalance,
          recoveredAmount: recoveredAmount,
        ),
      );
  factory DashboardMetricsState.error(String message) => DashboardMetricsState(
        isLoading: false,
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

  /// Fetch dashboard metrics from Supabase backend
  Future<void> fetchDashboardMetrics() async {
    state = DashboardMetricsState.loading();
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final tenantId = user?.appMetadata['tenant_id'] as String? ?? 'default_tenant';

      final customerData = await supabase
          .from('customers')
          .select()
          .eq('tenant_id', tenantId);
      final totalCustomers = customerData.length;

      final debtData = await supabase.from('debts').select('balance, overdue');
      final totalDebt = debtData.fold(0.0, (sum, d) => sum + (d['balance'] ?? 0.0));
      final overdueBalance = debtData
          .where((d) => d['overdue'] == true)
          .fold(0.0, (sum, d) => sum + (d['balance'] ?? 0.0));

      final paymentData = await supabase.from('payments').select('amount');
      final recoveredAmount = paymentData.fold(0.0,
          (sum, p) => sum + (p['amount'] ?? 0.0));

      // totalCustomers already computed above
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
}

/// Provider for dashboard metrics notifier
final dashboardMetricsNotifierprovider =
    NotifierProvider<DashboardMetricsNotifier, DashboardMetricsState>(
  DashboardMetricsNotifier.new,
);