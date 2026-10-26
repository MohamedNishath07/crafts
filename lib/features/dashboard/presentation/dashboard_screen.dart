import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operations Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 4),
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
                  children: const [
                    _MetricCard(
                      title: 'Total Outstanding Debt',
                      value: '\$142,500.00',
                      icon: Icons.account_balance,
                      accentColor: AppColors.brandPrimary,
                      trend: 'across 42 active debts',
                    ),
                    _MetricCard(
                      title: 'Overdue Balances',
                      value: '\$48,200.00',
                      icon: Icons.warning_amber_rounded,
                      accentColor: AppColors.accentDanger,
                      trend: '33.8% of portfolio',
                    ),
                    _MetricCard(
                      title: 'Recovered This Month',
                      value: '\$24,800.00',
                      icon: Icons.check_circle_outline,
                      accentColor: AppColors.accentSuccess,
                      trend: '+14% vs last month',
                    ),
                    _MetricCard(
                      title: 'Active Customers',
                      value: '148',
                      icon: Icons.people_outline,
                      accentColor: AppColors.accentInfo,
                      trend: '22 registered this week',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Status Breakdown & Recent Activity Placeholder
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aging Breakdown & Recovery Targets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Portfolio distribution across delinquency brackets (Current, 1-30 DPD, 31-60 DPD, 61-90 DPD, 90+ DPD)',
                    style: TextStyle(fontSize: 13, color: AppColors.inkSecondary),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      _AgingPill(label: 'Current', amount: '\$72,100', color: AppColors.accentSuccess),
                      SizedBox(width: 12),
                      _AgingPill(label: '1-30 DPD', amount: '\$22,200', color: AppColors.accentWarning),
                      SizedBox(width: 12),
                      _AgingPill(label: '31-60 DPD', amount: '\$18,400', color: Colors.orange),
                      SizedBox(width: 12),
                      _AgingPill(label: '61-90 DPD', amount: '\$15,600', color: AppColors.accentDanger),
                      SizedBox(width: 12),
                      _AgingPill(label: '90+ DPD', amount: '\$14,200', color: AppColors.accentUrgent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _AgingPill extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _AgingPill({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.inkPrimary)),
          ],
        ),
      ),
    );
  }
}
