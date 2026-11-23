import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/user_profile.dart';
import '../../domain/dashboard_models.dart';

class RoleSpecificSection extends StatelessWidget {
  final UserRole role;
  final DashboardOverviewMetrics metrics;

  const RoleSpecificSection({
    super.key,
    required this.role,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.admin:
        return _AdminSection(metrics: metrics);
      case UserRole.recoveryOfficer:
        return _RecoverySection(metrics: metrics);
      case UserRole.financeOfficer:
        return _FinanceSection(metrics: metrics);
    }
  }
}

/// 1. Admin Role Specialized Banner
class _AdminSection extends StatelessWidget {
  final DashboardOverviewMetrics metrics;

  const _AdminSection({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBgColor(isDark);
    final borderDark = AppColors.borderDarkColor(isDark);
    final surfaceRaised = AppColors.surfaceRaisedColor(isDark);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrative Console',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryColor(isDark),
                        ),
                      ),
                      Text(
                        'System oversight & governance',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryColor(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin/users'),
                    icon: const Icon(Icons.manage_accounts_rounded, size: 14),
                    label: const Text('Manage Staff', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.brandPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin/audit-logs'),
                    icon: const Icon(Icons.security_rounded, size: 14),
                    label: const Text('Audit Logs', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryColor(isDark),
                      side: BorderSide(color: borderDark),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Health & performance summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceRaised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Recovery Rate', '${metrics.recoveryRate.toStringAsFixed(1)}%', AppColors.brandPrimary, isDark),
                  const SizedBox(width: 24),
                  _buildMiniStat('Active Staff', '${metrics.staffCount}', AppColors.brandPrimary, isDark),
                  const SizedBox(width: 24),
                  _buildMiniStat('Overdue Ratio', '${metrics.totalCreditAmount > 0 ? ((metrics.overdueBalance / metrics.totalCreditAmount) * 100).toStringAsFixed(1) : 0}%', AppColors.brandPrimary, isDark),
                  const SizedBox(width: 24),
                  _buildMiniStat('Audit Events', '${metrics.auditLogCount}', AppColors.brandPrimary, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Recovery Officer Specialized Section
class _RecoverySection extends StatelessWidget {
  final DashboardOverviewMetrics metrics;

  const _RecoverySection({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBgColor(isDark);
    final borderDark = AppColors.borderDarkColor(isDark);
    final stats = _recoveryStats();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.contact_phone_rounded,
                  color: AppColors.brandPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recovery Officer Workspace',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryColor(isDark),
                      ),
                    ),
                    Text(
                      'Assigned accounts & daily follow-up queue',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryColor(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => context.go('/recovery'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('Open Recovery Log',
                    style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760
                  ? 3
                  : (constraints.maxWidth >= 480 ? 2 : 1);
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.6 : 2.6,
                children: [
                  for (final stat in stats) _RecoveryStatCard(stat: stat),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<_RecoveryStat> _recoveryStats() {
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    return [
      _RecoveryStat(
        label: 'Assigned Portfolio',
        value: currency.format(metrics.assignedOutstandingBalance),
        subtitle: 'Across ${metrics.assignedCustomersCount} clients',
        icon: Icons.account_balance_wallet_rounded,
      ),
      _RecoveryStat(
        label: 'Follow-ups Due Today',
        value: '${metrics.todayFollowUpsCount} accounts',
        subtitle: 'Promised: ${currency.format(metrics.todayPromisedAmount)}',
        icon: Icons.event_available_rounded,
      ),
      _RecoveryStat(
        label: "Today's Contacts",
        value: '${metrics.todayInteractionsCount} logged',
        subtitle: 'Calls & visits made',
        icon: Icons.phone_in_talk_rounded,
      ),
    ];
  }
}

/// Immutable view-model for a single recovery highlight card.
class _RecoveryStat {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  const _RecoveryStat({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}

/// Reusable, theme-aware stat card with an icon and accessible semantics.
class _RecoveryStatCard extends StatelessWidget {
  final _RecoveryStat stat;

  const _RecoveryStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.brandPrimary;

    return Semantics(
      label: '${stat.label}: ${stat.value}. ${stat.subtitle}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(stat.icon, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      stat.value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondaryColor(isDark),
                    ),
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

/// 3. Finance Officer Specialized Section
class _FinanceSection extends StatelessWidget {
  final DashboardOverviewMetrics metrics;

  const _FinanceSection({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBgColor(isDark);
    final borderDark = AppColors.borderDarkColor(isDark);
    final surfaceRaised = AppColors.surfaceRaisedColor(isDark);
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finance Control Panel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryColor(isDark),
                        ),
                      ),
                      Text(
                        'Cash collections, reconciliation & summaries',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryColor(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/reports'),
                icon: const Icon(Icons.receipt_rounded, size: 14),
                label: const Text('Generate Reports', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Finance Summary Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceRaised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Month-to-Date', currencyFmt.format(metrics.monthToDateCollections), AppColors.brandPrimary, isDark),
                  const SizedBox(width: 24),
                  _buildMiniStat('Total Receipts', '${metrics.totalPaymentsCount}', AppColors.brandPrimary, isDark),
                  const SizedBox(width: 24),
                  _buildMiniStat('Active Bills', '${metrics.activeBillsCount}', AppColors.brandPrimary, isDark),
                  const SizedBox(width: 24),
                  _buildMiniStat('Fully Settled', '${metrics.settledBillsCount}', AppColors.brandPrimary, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildMiniStat(String label, String value, Color color, bool isDark) {
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryColor(isDark),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}
