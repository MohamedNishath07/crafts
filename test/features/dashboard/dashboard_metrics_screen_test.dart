import 'package:flutter_test/flutter_test.dart';
import 'package:crafts/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  group('DashboardScreen', () {
    testWidgets('renders DashboardScreen scaffold', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: DashboardScreen(),
      ));

      expect(find.text('Operations Dashboard'), findsOneWidget);
      expect(find.text('Real-time overview of outstanding debt and recovery performance'), findsOneWidget);
    });

    testWidgets('metric cards are present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: DashboardScreen(),
      ));

      // Check for metric card titles
      expect(find.text('Total Outstanding Debt'), findsOneWidget);
      expect(find.text('Overdue Balances'), findsOneWidget);
      expect(find.text('Recovered This Month'), findsOneWidget);
      expect(find.text('Active Customers'), findsOneWidget);
    });
  });
}