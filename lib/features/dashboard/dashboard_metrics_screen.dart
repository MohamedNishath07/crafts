import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/core/constants/app_colors.dart';
import 'package:crafts/features/dashboard/dashboard_provider.dart';
import 'package:crafts/features/dashboard/dashboard_model.dart';
import 'dashboard_recovery_trend_chart.dart';
import 'dashboard_payment_status_chart.dart';

/// Widget that displays the 4 metric cards
class DashboardMetricsScreen extends ConsumerWidget {
  const DashboardMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardMetricsProvider.notifier).state = AsyncDashboardMetrics.loading(),
          ),
        ],
      ),
      body: metrics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.accentDanger),
          ),
        ),
        empty: () => const Center(child: Text('No data available')),
        data: (metrics) => _buildDashboardContent(context, metrics),
      ),
    );
  }

  Widget _buildMetricCards(BuildContext context, AsyncDashboardMetrics metrics) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _MetricCard(
            title: 'Total Customers',
            value: _formatInt(metrics.totalCustomers),
            icon: Icons.people,
            color: AppColors.brandPrimary,
            backgroundColor: isDark
                ? AppColors.surfaceRaised
                : AppColors.surfaceBase,
          ),
          _MetricCard(
            title: 'Total Debt',
            value: '\$${metrics.totalDebt.toStringAsFixed(2)}',
            icon: Icons.money,
            color: AppColors.accentWarning,
            backgroundColor: isDark
                ? AppColors.surfaceRaised
                : AppColors.surfaceBase,
          ),
          _MetricCard(
            title: 'Overdue',
            value: '\$${metrics.overdueBalance.toStringAsFixed(2)}',
            icon: Icons.warning,
            color: AppColors.accentDanger,
            backgroundColor: isDark
                ? AppColors.surfaceRaised
                : AppColors.surfaceBase,
          ),
          _MetricCard(
            title: 'Recovered',
            value: '\$${metrics.recoveredAmount.toStringAsFixed(2)}',
            icon: Icons.check_circle,
            color: AppColors.accentSuccess,
            backgroundColor: isDark
                ? AppColors.surfaceRaised
                : AppColors.surfaceBase,
          ),
        ],
      ),
    );
  }
Widget _buildDashboardContent(BuildContext context, AsyncDashboardMetrics metrics) {
  // TODO: implement dashboard content
  return SingleChildScrollView();
}

Widget _buildChartsSection(BuildContext context, AsyncDashboardMetrics metrics) {
  RecoveryTrendChart(
          recoveryData: [4500.00, 5200.00, 3800.00, 6100.00, 7000.00, 8500.00],
          monthLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        ),
}

const SizedBox(height: 32),
      Text(
        'Payment Status Breakdown',
        style: TextStyle(
          color: isDark ? AppColors.inkPrimary : AppColors.inkSecondary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      PaymentStatusChart(
        statusData: {
          'Current': 50000.00,
          'Overdue': 15000.00,
          'Settled': 40000.00,
        },
        colorScheme: {
          'Current': AppColors.accentSuccess,
          'Overdue': AppColors.accentDanger,
          'Settled': AppColors.brandPrimary,
        },
      ),
/// Individual metric card widget
class _MetricCard extends StatelessWidget {
}
  (int value) => value.toString();\+(?!\d)')
}

/// Individual metric card widget
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: backgroundColor,
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.inkPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
);
}

/// Individual metric card widget
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: backgroundColor,
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.inkPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}