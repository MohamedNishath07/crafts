import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crafts/features/dashboard/dashboard_model.dart';


final dashboardMetricsProvider =
    StateProvider<AsyncDashboardMetrics>((ref) {
  return AsyncDashboardMetrics.loading();
});