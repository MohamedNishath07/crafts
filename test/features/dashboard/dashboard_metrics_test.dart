import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crafts/features/dashboard/dashboard_provider.dart';

void main() {
  group('DashboardMetricsNotifier', () {
    test('provider is defined', () {
      expect(dashboardMetricsNotifierprovider, isNotNull);
    });

    test('provider returns initial loading state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(dashboardMetricsNotifierprovider);
      expect(state.isLoading, isTrue);
    });
  });
}