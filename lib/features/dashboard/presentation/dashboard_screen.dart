import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import 'dashboard_provider.dart';
import 'dashboard_payment_status_chart.dart';
import 'dashboard_recovery_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsState = ref.watch(dashboardMetricsNotifierprovider);
    return _buildBody(context, ref, metricsState);
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, DashboardMetricsState metricsState) {
    return _buildSuccessScreen(context, ref, metricsState);
  }

  Widget _buildSuccessScreen(BuildContext context, WidgetRef ref, DashboardMetricsState metricsState) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.brandPrimary,
        elevation: 0,
        title: const Text(
          'Operations Dashboard',
          style: TextStyle(color: AppColors.surfaceBase, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surfaceBase),
            onPressed: () => ref.read(dashboardMetricsNotifierprovider.notifier).refresh(),
            tooltip: 'Refresh metrics',
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_outlined, color: AppColors.surfaceBase),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DashboardReportScreen()));
            },
            tooltip: 'Reports',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-time overview of outstanding debt and recovery performance',
              style: TextStyle(fontSize: 14, color: AppColors.inkSecondary),
            ),
            const SizedBox(height: 24),

            // Metric KPI Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final crossAxisCount = isWide ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 2.0 : 1.6,
                  children: [
                    _MetricCard(
                      title: 'Total Outstanding Debt',
                      value: metricsState.metrics?.totalDebt.toStringAsFixed(2) ?? '0.00',
                      icon: Icons.account_balance,
                      accentColor: AppColors.brandPrimary,
                      trend: 'across ${metricsState.metrics?.totalCustomers ?? 0} active debts',
                    ),
                    _MetricCard(
                      title: 'Overdue Balances',
                      value: metricsState.metrics?.overdueBalance.toStringAsFixed(2) ?? '0.00',
                      icon: Icons.warning_amber_rounded,
                      accentColor: AppColors.accentDanger,
                      trend: '${((metricsState.metrics?.overdueBalance ?? 0.0) / (metricsState.metrics?.totalDebt ?? 1.0) * 100).toStringAsFixed(1)}% of portfolio',
                    ),
                    _MetricCard(
                      title: 'Recovered This Month',
                      value: metricsState.metrics?.recoveredAmount.toStringAsFixed(2) ?? '0.00',
                      icon: Icons.check_circle_outline,
                      accentColor: AppColors.accentSuccess,
                      trend: '+14% vs last month',
                    ),
                    _MetricCard(
                      title: 'Active Customers',
                      value: (metricsState.metrics?.totalCustomers ?? 0).toString(),
                      icon: Icons.people_outline,
                      accentColor: AppColors.accentInfo,
                      trend: '22 registered this week',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Status Breakdown Section with Charts
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      Text(
                        'Total: \$${(metricsState.metrics?.totalDebt ?? 0.0).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PaymentStatusChart(
                          statusData: _buildPaymentStatusData(metricsState.metrics),
                          colorScheme: _buildPaymentStatusColors(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: RecoveryTrendChart(
                          recoveryData: _buildRecoveryData(metricsState.metrics),
                          monthLabels: _buildMonthLabels(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            if (metricsState.isLoading)
              const Center(child: CircularProgressIndicator()),
            if (metricsState.hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.accentDanger, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading metrics: ${metricsState.errorMessage}',
                      style: const TextStyle(color: AppColors.accentDanger),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(dashboardMetricsNotifierprovider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
Map<String, double> _buildPaymentStatusData(dynamic metrics) {
  if (metrics == null) {
    return {'Current': 0, 'Overdue': 0, 'Settled': 0};
  }
  final total = metrics.totalDebt;
  final overdue = metrics.overdueBalance;
  final current = (total - overdue).clamp(0, total);
  final settled = (metrics.recoveredAmount * 1.5).clamp(0, total * 2);
  return {
    'Current': current > 0 ? current : 0,
    'Overdue': overdue > 0 ? overdue : 0,
    'Settled': settled > 0 ? settled : 0,
  }..removeWhere((_, v) => v == 0);
}

Map<String, Color> _buildPaymentStatusColors() {
  return {
    'Current': AppColors.accentSuccess,
    'Overdue': AppColors.accentDanger,
    'Settled': AppColors.brandPrimary,
  };
}

List<double> _buildRecoveryData(dynamic metrics) {
  if (metrics == null) {
    return [0, 0, 0, 0, 0, 0];
  }
  final monthly = metrics.recoveredAmount / 6;
  return List.generate(6, (index) => monthly * (index + 1) * 0.8);
}

List<String> _buildMonthLabels() {
  final now = DateTime.now();
  return List.generate(6, (index) {
    final month = now.subtract(Duration(days: index * 30));
    return '${month.month}/${month.day}';
  }.reversed.toList());
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String trend;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.inkPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(
            trend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}