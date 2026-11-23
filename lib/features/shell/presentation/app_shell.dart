import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/data/php_auth_session.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import 'expandable_tab_bar.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(authControllerProvider).value ??
        ref.watch(phpAuthSessionProvider);
    final currentPath = GoRouterState.of(context).uri.toString();

    final navItems = _buildNavItems(user?.role ?? UserRole.recoveryOfficer);
    final tabItems = navItems
        .map((e) => TabBarItem(route: e.route, label: e.label, icon: e.icon))
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.surfaceBaseColor(isDark),
      body: child,
      bottomNavigationBar: ExpandableTabBar(
        items: tabItems,
        currentPath: currentPath,
      ),
    );
  }

  List<_NavItem> _buildNavItems(UserRole role) {
    // Ordered by workflow, not by feature name:
    // Home -> daily driver -> entities (who / what they owe) -> money in ->
    // actions -> insights -> administration -> settings (always last).
    const dashboard = _NavItem(
      route: '/dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
    );
    const recovery = _NavItem(
      route: '/recovery',
      label: 'Recovery Log',
      icon: Icons.phone_callback_outlined,
    );
    const customers = _NavItem(
      route: '/customers',
      label: 'Customers',
      icon: Icons.people_outline,
    );
    const debts = _NavItem(
      route: '/debts',
      label: 'Debt Ledger',
      icon: Icons.receipt_long_outlined,
    );
    const payments = _NavItem(
      route: '/payments',
      label: 'Payments',
      icon: Icons.payments_outlined,
    );
    const reports = _NavItem(
      route: '/reports',
      label: 'Reports',
      icon: Icons.analytics_outlined,
    );
    const users = _NavItem(
      route: '/admin/users',
      label: 'User Staff',
      icon: Icons.manage_accounts_outlined,
    );
    const auditLogs = _NavItem(
      route: '/admin/audit-logs',
      label: 'Audit Logs',
      icon: Icons.security_outlined,
    );
    const settings = _NavItem(
      route: '/profile',
      label: 'Settings',
      icon: Icons.settings_outlined,
    );

    final canSeePayments =
        role == UserRole.financeOfficer || role == UserRole.admin;
    final canSeeRecovery =
        role == UserRole.recoveryOfficer || role == UserRole.admin;
    final canSeeReports =
        role == UserRole.financeOfficer || role == UserRole.admin;
    final isAdmin = role == UserRole.admin;

    final items = <_NavItem>[dashboard];

    // A recovery officer lives in the recovery log day-to-day, so it sits
    // directly after Home rather than behind the reference data.
    if (role == UserRole.recoveryOfficer) {
      items.add(recovery);
    }

    items.add(customers);
    items.add(debts);

    if (canSeePayments) items.add(payments);
    // Admins see Recovery Log after the money screens; officers already have it
    // at position 2 above.
    if (canSeeRecovery && role != UserRole.recoveryOfficer) {
      items.add(recovery);
    }
    if (canSeeReports) items.add(reports);

    if (isAdmin) {
      items.add(users);
      items.add(auditLogs);
    }

    items.add(settings);

    return items;
  }
}

class _NavItem {
  final String route;
  final String label;
  final IconData icon;

  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
  });
}
