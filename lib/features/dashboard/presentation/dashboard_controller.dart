import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(DashboardController.new);

class DashboardController extends Notifier<DashboardState> {
  late final DashboardRepository _repository;

  @override
  DashboardState build() {
    _repository = ref.watch(dashboardRepositoryProvider);
    // Trigger initial load after build
    Future.microtask(() => loadDashboard());
    return DashboardState.initial();
  }

  UserProfile? get _currentUser => ref.read(authControllerProvider).value;

  String get _currentTenantId {
    return _currentUser?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';
  }

  /// Full refresh of dashboard metrics, charts, and activities
  Future<void> loadDashboard({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final user = _currentUser;
      final tenantId = _currentTenantId;
      final role = user?.role ?? UserRole.admin;
      final officerId = user?.id;

      // Check if DB is empty
      final isEmpty = await _repository.isDatabaseEmpty(tenantId);

      // Fetch overview statistics
      final metrics = await _repository.fetchOverviewMetrics(
        tenantId,
        role: role,
        officerId: officerId,
      );

      // Fetch charts analytics
      final analytics = await _repository.fetchChartAnalytics(
        tenantId,
        state.dateFilter,
      );

      // Fetch recent activities
      final activities = await _repository.fetchRecentActivities(
        tenantId,
        filterType: state.activityFilter,
      );

      state = state.copyWith(
        isLoading: false,
        metrics: metrics,
        analytics: analytics,
        recentActivities: activities,
        isDatabaseEmpty: isEmpty,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data: ${e.toString()}',
      );
    }
  }

  /// Change the financial chart date filter (This Week, This Month, This Year)
  Future<void> setDateFilter(DashboardDateFilter filter) async {
    if (state.dateFilter == filter) return;
    state = state.copyWith(dateFilter: filter);

    try {
      final tenantId = _currentTenantId;
      final analytics = await _repository.fetchChartAnalytics(tenantId, filter);
      state = state.copyWith(analytics: analytics);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update chart for ${filter.label}: $e',
      );
    }
  }

  /// Filter recent activities category (all, payment, credit, recovery, customer)
  Future<void> setActivityFilter(String filter) async {
    if (state.activityFilter == filter) return;
    state = state.copyWith(activityFilter: filter);

    try {
      final tenantId = _currentTenantId;
      final activities = await _repository.fetchRecentActivities(
        tenantId,
        filterType: filter,
      );
      state = state.copyWith(recentActivities: activities);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to filter activities: $e',
      );
    }
  }

  /// Seed initial demo data into SQLite if desired
  Future<void> seedDemoData() async {
    state = state.copyWith(isLoading: true);
    try {
      final tenantId = _currentTenantId;
      final officerId = _currentUser?.id;
      await _repository.seedDemoData(tenantId, officerId: officerId);
      await loadDashboard(showLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to seed sample records: $e',
      );
    }
  }
}
