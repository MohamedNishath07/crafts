import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:credit_recovery_system/features/auth/domain/user_profile.dart';
import 'package:credit_recovery_system/features/dashboard/domain/dashboard_models.dart';
import 'package:credit_recovery_system/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:credit_recovery_system/features/dashboard/presentation/widgets/dashboard_overview_cards.dart';
import 'package:credit_recovery_system/features/dashboard/presentation/widgets/dashboard_quick_actions.dart';
import 'package:credit_recovery_system/features/dashboard/presentation/widgets/role_specific_section.dart';

void main() {
  group('Dashboard Components Tests', () {
    testWidgets('DashboardHeader displays user information and role', (tester) async {
      const user = UserProfile(
        id: 'u-1',
        tenantId: 't-1',
        email: 'admin@finance.com',
        fullName: 'Eleanor Vance',
        role: UserRole.admin,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardHeader(
              user: user,
              isRefreshing: false,
              isDatabaseEmpty: false,
              onRefresh: () {},
              onSeedDemoData: () {},
            ),
          ),
        ),
      );

      expect(find.text('Eleanor Vance'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('Real-time overview of outstanding debt and recovery performance'), findsOneWidget);
      expect(find.text('Offline SQLite Active'), findsOneWidget);
    });

    testWidgets('DashboardOverviewCards renders all 6 key financial metrics', (tester) async {
      const metrics = DashboardOverviewMetrics(
        totalCustomers: 42,
        totalCreditAmount: 150000.0,
        totalCollectedAmount: 95000.0,
        outstandingBalance: 55000.0,
        todayCollections: 3200.0,
        overdueBalance: 12500.0,
        overdueCount: 4,
        recoveryRate: 63.3,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardOverviewCards(
                metrics: metrics,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      // Verify all 6 prompt requirements are visible:
      expect(find.text('Total Customers'), findsOneWidget);
      expect(find.text('Total Credit Amount'), findsOneWidget);
      expect(find.text('Total Collected Amount'), findsOneWidget);
      expect(find.text('Outstanding Balance'), findsOneWidget);
      expect(find.text("Today's Collections"), findsOneWidget);
      expect(find.text('Overdue Payments'), findsOneWidget);

      // Verify formatted currency values:
      expect(find.text('\$150,000.00'), findsOneWidget);
      expect(find.text('\$95,000.00'), findsOneWidget);
      expect(find.text('\$55,000.00'), findsOneWidget);
      expect(find.text('\$3,200.00'), findsOneWidget);
      expect(find.text('\$12,500.00'), findsOneWidget);
    });

    testWidgets('DashboardQuickActions displays actions for Admin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardQuickActions(
                role: UserRole.admin,
                onActionCompleted: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.text('Create Credit Bill'), findsOneWidget);
      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('View Customers'), findsOneWidget);
      expect(find.text('Recovery Management'), findsOneWidget);
      expect(find.text('Financial Reports'), findsOneWidget);
    });

    testWidgets('DashboardQuickActions adapts for Recovery Officer role', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardQuickActions(
                role: UserRole.recoveryOfficer,
                onActionCompleted: () {},
              ),
            ),
          ),
        ),
      );

      // Recovery officer should see recovery actions and customer directory
      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.text('View Customers'), findsOneWidget);
      expect(find.text('Recovery Management'), findsOneWidget);
      expect(find.text('Debt Ledger'), findsOneWidget);

      // Should not show direct payment recording or financial reports per router rules
      expect(find.text('Record Payment'), findsNothing);
      expect(find.text('Financial Reports'), findsNothing);
    });

    testWidgets('RoleSpecificSection renders Recovery Officer queue correctly', (tester) async {
      const metrics = DashboardOverviewMetrics(
        totalCustomers: 20,
        totalCreditAmount: 50000.0,
        totalCollectedAmount: 20000.0,
        outstandingBalance: 30000.0,
        todayCollections: 1000.0,
        overdueBalance: 5000.0,
        overdueCount: 2,
        recoveryRate: 40.0,
        assignedCustomersCount: 12,
        assignedOutstandingBalance: 18000.0,
        todayFollowUpsCount: 3,
        todayPromisedAmount: 4500.0,
        todayInteractionsCount: 5,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleSpecificSection(
              role: UserRole.recoveryOfficer,
              metrics: metrics,
            ),
          ),
        ),
      );

      expect(find.text('Recovery Officer Workspace'), findsOneWidget);
      expect(find.text('Assigned Portfolio'), findsOneWidget);
      expect(find.text('Follow-ups Due Today'), findsOneWidget);
      expect(find.text("Today's Contacts"), findsOneWidget);
      expect(find.text('\$18,000.00'), findsOneWidget);
      expect(find.text('3 accounts'), findsOneWidget);
      expect(find.text('5 logged'), findsOneWidget);
    });

    testWidgets('RoleSpecificSection renders Finance Officer panel correctly', (tester) async {
      const metrics = DashboardOverviewMetrics(
        totalCustomers: 20,
        totalCreditAmount: 50000.0,
        totalCollectedAmount: 20000.0,
        outstandingBalance: 30000.0,
        todayCollections: 1000.0,
        overdueBalance: 5000.0,
        overdueCount: 2,
        recoveryRate: 40.0,
        totalPaymentsCount: 18,
        monthToDateCollections: 8500.0,
        activeBillsCount: 14,
        settledBillsCount: 6,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleSpecificSection(
              role: UserRole.financeOfficer,
              metrics: metrics,
            ),
          ),
        ),
      );

      expect(find.text('Finance Control Panel'), findsOneWidget);
      expect(find.text('Month-to-Date'), findsOneWidget);
      expect(find.text('Total Receipts'), findsOneWidget);
      expect(find.text('Active Bills'), findsOneWidget);
      expect(find.text('Fully Settled'), findsOneWidget);
      expect(find.text('\$8,500.00'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
    });
  });
}

