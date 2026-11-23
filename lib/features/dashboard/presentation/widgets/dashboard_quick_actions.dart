import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../customers/presentation/widgets/add_customer_dialog.dart';
import '../../../debts/presentation/widgets/add_debt_dialog.dart';
import '../../../payments/presentation/widgets/record_payment_dialog.dart';

class DashboardQuickActions extends StatelessWidget {
  final UserRole role;
  final VoidCallback onActionCompleted;

  const DashboardQuickActions({
    super.key,
    required this.role,
    required this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBgColor(isDark);
    final primaryTextColor = AppColors.textPrimaryColor(isDark);
    final secondaryTextColor = AppColors.textSecondaryColor(isDark);
    final borderDark = AppColors.borderDarkColor(isDark);

    final actions = _getActionsForRole(context, role);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderDark,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              Text(
                'Instant operations',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final crossAxisCount = isWide ? 6 : (constraints.maxWidth >= 600 ? 3 : 2);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.3 : 1.35,
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  return _QuickActionCard(
                    item: actions[index],
                    isDark: isDark,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<_QuickActionItem> _getActionsForRole(BuildContext context, UserRole role) {
    final list = <_QuickActionItem>[];

    // 1. Add Customer (Available to all)
    list.add(
      _QuickActionItem(
        title: 'Add Customer',
        subtitle: 'New profile',
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.brandPrimary,
        onTap: () async {
          final res = await showDialog<bool>(
            context: context,
            builder: (_) => const AddCustomerDialog(),
          );
          if (res == true) onActionCompleted();
        },
      ),
    );

    // 2. Create Credit Bill (Admin & Finance)
    if (role == UserRole.admin || role == UserRole.financeOfficer) {
      list.add(
        _QuickActionItem(
          title: 'Create Credit Bill',
          subtitle: 'Issue debt',
          icon: Icons.post_add_rounded,
          color: AppColors.brandPrimary,
          onTap: () async {
            final res = await showDialog<bool>(
              context: context,
              builder: (_) => const AddDebtDialog(),
            );
            if (res == true) onActionCompleted();
          },
        ),
      );
    }

    // 3. Record Payment (Admin & Finance)
    if (role == UserRole.admin || role == UserRole.financeOfficer) {
      list.add(
        _QuickActionItem(
          title: 'Record Payment',
          subtitle: 'Collect funds',
          icon: Icons.payments_rounded,
          color: AppColors.brandPrimary,
          onTap: () async {
            final res = await showDialog<bool>(
              context: context,
              builder: (_) => const RecordPaymentDialog(),
            );
            if (res == true) onActionCompleted();
          },
        ),
      );
    }

    // 4. View Customers (Available to all)
    list.add(
      _QuickActionItem(
        title: 'View Customers',
        subtitle: 'Directory',
        icon: Icons.groups_rounded,
        color: AppColors.brandPrimary,
        onTap: () => context.go('/customers'),
      ),
    );

    // 5. Recovery Management (Admin & Recovery Officer)
    if (role == UserRole.admin || role == UserRole.recoveryOfficer) {
      list.add(
        _QuickActionItem(
          title: 'Recovery Management',
          subtitle: 'Logs & calls',
          icon: Icons.phone_callback_rounded,
          color: AppColors.brandPrimary,
          onTap: () => context.go('/recovery'),
        ),
      );
    }

    // 6. Financial Reports (Admin & Finance)
    if (role == UserRole.admin || role == UserRole.financeOfficer) {
      list.add(
        _QuickActionItem(
          title: 'Financial Reports',
          subtitle: 'Statements',
          icon: Icons.analytics_rounded,
          color: AppColors.brandPrimary,
          onTap: () => context.go('/reports'),
        ),
      );
    }

    // If Recovery Officer, show Debt Ledger navigation instead of blocked payments/reports
    if (role == UserRole.recoveryOfficer) {
      list.add(
        _QuickActionItem(
          title: 'Debt Ledger',
          subtitle: 'Assigned bills',
          icon: Icons.receipt_long_rounded,
          color: AppColors.brandPrimary,
          onTap: () => context.go('/debts'),
        ),
      );
    }

    return list;
  }
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatefulWidget {
  final _QuickActionItem item;
  final bool isDark;

  const _QuickActionCard({
    required this.item,
    required this.isDark,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = AppColors.cardBgColor(isDark);
    final borderSubtle = AppColors.borderSubtleColor(isDark);
    final borderDark = AppColors.borderDarkColor(isDark);
    final borderColor = _isHovered
        ? widget.item.color.withValues(alpha: 0.5)
        : (isDark ? borderDark : borderSubtle);

    return InkWell(
      onTap: widget.item.onTap,
      borderRadius: BorderRadius.circular(14),
      onHover: (hovered) => setState(() => _isHovered = hovered),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.item.color.withValues(alpha: widget.isDark ? 0.2 : 0.08)
              : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: _isHovered ? 1.5 : 1.0),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: widget.item.color.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.item.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.item.icon,
                color: widget.item.color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor(isDark),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.item.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondaryColor(isDark),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
