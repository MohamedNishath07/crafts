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
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      width: double.infinity,
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
                      Icons.contact_phone_rounded,
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
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
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/recovery'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('Open Recovery Log', style: TextStyle(fontSize: 11)),
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
          // Recovery Target Tracker Grid (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 450;
              if (isSmall) {
                return Column(
                  children: [
                    _buildRecoveryHighlightCard(
                      'Assigned Portfolio',
                      currencyFmt.format(metrics.assignedOutstandingBalance),
                      'Across ${metrics.assignedCustomersCount} clients',
                      AppColors.brandPrimary,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildRecoveryHighlightCard(
                      'Follow-ups Due Today',
                      '${metrics.todayFollowUpsCount} accounts',
                      'Promised: ${currencyFmt.format(metrics.todayPromisedAmount)}',
                      AppColors.brandPrimary,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildRecoveryHighlightCard(
                      "Today's Contacts",
                      '${metrics.todayInteractionsCount} logged',
                      'Calls & visits made',
                      AppColors.brandPrimary,
                      isDark,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildRecoveryHighlightCard(
                      'Assigned Portfolio',
                      currencyFmt.format(metrics.assignedOutstandingBalance),
                      'Across ${metrics.assignedCustomersCount} clients',
                      AppColors.brandPrimary,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRecoveryHighlightCard(
                      'Follow-ups Due Today',
                      '${metrics.todayFollowUpsCount} accounts',
                      'Promised: ${currencyFmt.format(metrics.todayPromisedAmount)}',
                      AppColors.brandPrimary,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRecoveryHighlightCard(
                      "Today's Contacts",
                      '${metrics.todayInteractionsCount} logged',
                      'Calls & visits made',
                      AppColors.brandPrimary,
                      isDark,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _buildRecoveryHighlightCard(
  String title,
  String value,
  String subtitle,
  Color color,
  bool isDark,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.12 : 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryColor(isDark),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.textSecondaryColor(isDark),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
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
