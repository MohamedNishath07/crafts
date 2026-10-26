import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_audit_logs_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/auth/domain/user_profile.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/debts/presentation/debts_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/recovery/presentation/recovery_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/shell/presentation/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (isLoading) return null;

      // Unauthenticated users are redirected to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // Authenticated users on login screen are redirected to dashboard
      if (isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }

      // Role permission guards
      if (isAuthenticated) {
        final role = authState.value!.role;
        final path = state.matchedLocation;

        if (path.startsWith('/admin') && role != UserRole.admin) {
          return '/dashboard';
        }

        if (path == '/payments' && role == UserRole.recoveryOfficer) {
          return '/dashboard';
        }

        if (path == '/reports' && role == UserRole.recoveryOfficer) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/debts',
            builder: (context, state) => const DebtsScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/recovery',
            builder: (context, state) => const RecoveryScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/audit-logs',
            builder: (context, state) => const AdminAuditLogsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
