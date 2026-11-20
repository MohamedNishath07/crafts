import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../auth/data/php_auth_session.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../dashboard_provider.dart';
import '../domain/dashboard_models.dart';
import 'dashboard_controller.dart';
import 'widgets/dashboard_analytics_section.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_overview_cards.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/dashboard_recent_activities.dart';
import 'widgets/role_specific_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get current user (either from authController or phpAuthSession)
    final user =
        ref.watch(authControllerProvider).value ??
        ref.watch(phpAuthSessionProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);

    final primaryNavy = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDarkSecondary : Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: AppColors.brandPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Operations Dashboard',
              style: TextStyle(
                color: isDark ? Colors.white : primaryNavy,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All system notifications are up to date.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(
              Icons.manage_accounts_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
            onPressed: () => context.go('/profile'),
            tooltip: 'Profile & Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brandPrimary,
        onRefresh: () async {
          await controller.loadDashboard();
          ref.read(dashboardMetricsNotifierprovider.notifier).refresh();
        },
        child: dashboardState.hasError
            ? _buildErrorView(context, ref, dashboardState.errorMessage!)
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16.0,
                  20.0,
                  16.0,
                  20.0 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Welcome & Operational Header Banner
                    DashboardHeader(
                      user: user,
                      isRefreshing: dashboardState.isLoading,
                      isDatabaseEmpty: dashboardState.isDatabaseEmpty,
                      onRefresh: () => controller.loadDashboard(),
                      onSeedDemoData: () => controller.seedDemoData(),
                    ),

                    const SizedBox(height: 20),

                    // 2. Financial Overview Cards (6 core metrics from SQLite)
                    DashboardOverviewCards(
                      metrics: dashboardState.metrics,
                      isLoading: dashboardState.isLoading,
                    ),

                    const SizedBox(height: 20),

                    // 3. Role-Tailored Section (Admin / Recovery / Finance)
                    RoleSpecificSection(
                      role: user?.role ?? UserRole.admin,
                      metrics: dashboardState.metrics,
                    ),

                    const SizedBox(height: 20),

                    // 4. Quick Actions Section
                    DashboardQuickActions(
                      role: user?.role ?? UserRole.admin,
                      onActionCompleted: () =>
                          controller.loadDashboard(showLoading: false),
                    ),

                    const SizedBox(height: 20),

                    // 5. Financial Analytics Section with Interactive Charts & Filters
                    DashboardAnalyticsSection(
                      analytics: dashboardState.analytics,
                      selectedFilter: dashboardState.dateFilter,
                      onFilterChanged: (DashboardDateFilter filter) =>
                          controller.setDateFilter(filter),
                    ),

                    const SizedBox(height: 20),

                    // 6. Recent Activities Feed from SQLite
                    DashboardRecentActivities(
                      activities: dashboardState.recentActivities,
                      selectedFilter: dashboardState.activityFilter,
                      onFilterChanged: (filter) =>
                          controller.setActivityFilter(filter),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentDanger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.accentDanger,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Financial Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              onPressed: () {
                ref.read(dashboardControllerProvider.notifier).loadDashboard();
              },
            ),
          ],
        ),
      ),
    );
  }
}
