import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import 'expandable_tab_bar.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentPath = GoRouterState.of(context).uri.toString();

    final navItems = _buildNavItems(user?.role ?? UserRole.recoveryOfficer);
    final tabItems = navItems
        .map((e) => TabBarItem(route: e.route, label: e.label, icon: e.icon))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: child,
      bottomNavigationBar: ExpandableTabBar(
        items: tabItems,
        currentPath: currentPath,
      ),
    );
  }

  List<_NavItem> _buildNavItems(UserRole role) {
    final list = <_NavItem>[
      const _NavItem(route: '/dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined),
      const _NavItem(route: '/customers', label: 'Customers', icon: Icons.people_outline),
      const _NavItem(route: '/debts', label: 'Debt Ledger', icon: Icons.receipt_long_outlined),
    ];

    if (role == UserRole.financeOfficer || role == UserRole.admin) {
      list.add(const _NavItem(route: '/payments', label: 'Payments', icon: Icons.payments_outlined));
    }

    if (role == UserRole.recoveryOfficer || role == UserRole.admin) {
      list.add(const _NavItem(route: '/recovery', label: 'Recovery Log', icon: Icons.phone_callback_outlined));
    }

    if (role == UserRole.financeOfficer || role == UserRole.admin) {
      list.add(const _NavItem(route: '/reports', label: 'Reports', icon: Icons.analytics_outlined));
    }

    if (role == UserRole.admin) {
      list.add(const _NavItem(route: '/admin/users', label: 'User Staff', icon: Icons.manage_accounts_outlined));
      list.add(const _NavItem(route: '/admin/audit-logs', label: 'Audit Logs', icon: Icons.security_outlined));
    }

    list.add(const _NavItem(route: '/profile', label: 'Settings', icon: Icons.settings_outlined));

    return list;
  }
}

class _NavItem {
  final String route;
  final String label;
  final IconData icon;

  const _NavItem({required this.route, required this.label, required this.icon});
}
