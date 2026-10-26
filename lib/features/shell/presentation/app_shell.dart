import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentPath = GoRouterState.of(context).uri.toString();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    final navItems = _buildNavItems(user?.role ?? UserRole.recoveryOfficer);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.surfaceSidebar,
              foregroundColor: AppColors.inkWhite,
              title: const Text(
                'Debit Recovery System',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: _buildSidebarContent(context, ref, user, currentPath, navItems),
            ),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 250,
              child: _buildSidebarContent(context, ref, user, currentPath, navItems),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(context, ref, user),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, WidgetRef ref, UserProfile? user) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Acme Credit Solutions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleBadgeColor(user.role).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getRoleBadgeColor(user.role).withOpacity(0.4)),
              ),
              child: Text(
                user.role.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getRoleBadgeColor(user.role),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.logout, size: 20, color: AppColors.inkSecondary),
              tooltip: 'Sign Out',
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
                context.go('/login');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    WidgetRef ref,
    UserProfile? user,
    String currentPath,
    List<_NavItem> items,
  ) {
    return Container(
      color: AppColors.surfaceSidebar,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: AppColors.accentSuccess, size: 24),
                SizedBox(width: 10),
                Text(
                  'Debit Recovery',
                  style: TextStyle(
                    color: AppColors.inkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: items.map((item) {
                final isSelected = currentPath == item.route;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF1E293B),
                    leading: Icon(
                      item.icon,
                      color: isSelected ? AppColors.accentSuccess : AppColors.inkMuted,
                      size: 20,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? AppColors.inkWhite : const Color(0xFFCBD5E1),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      context.go(item.route);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleBadgeColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.accentDanger;
      case UserRole.financeOfficer:
        return AppColors.accentSuccess;
      case UserRole.recoveryOfficer:
        return AppColors.accentWarning;
    }
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

    return list;
  }
}

class _NavItem {
  final String route;
  final String label;
  final IconData icon;

  const _NavItem({required this.route, required this.label, required this.icon});
}
