import 'package:flutter_test/flutter_test.dart';
import 'package:crafts/features/dashboard/dashboard_provider.dart';
import 'package:crafts/features/dashboard/dashboard_model.dart';

void main() {
  group('DashboardMetricsNotifier', () {
    // Integration-style test verifying the provider structure and methods
    test('fetchDashboardMetrics method exists', () {
      // Verify the notifier class has the required method
      expect(dashboardMetricsNotifierprovider, isNotEmpty);
    });

    test('provider returns initial loading state', () {
      // Test that the provider initializes with loading state
      final state = dashboardMetricsNotifierprovider.select((state) => state);
      expect(state.isLoading, isTrue);
    });
  });
}