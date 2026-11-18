/// Available date range filters for financial analytics
enum DashboardDateFilter {
  thisWeek,
  thisMonth,
  thisYear;

  String get label {
    switch (this) {
      case DashboardDateFilter.thisWeek:
        return 'This Week';
      case DashboardDateFilter.thisMonth:
        return 'This Month';
      case DashboardDateFilter.thisYear:
        return 'This Year';
    }
  }
}

/// Category of recent activity
enum ActivityType {
  customer,
  credit,
  payment,
  recovery;

  String get displayName {
    switch (this) {
      case ActivityType.customer:
        return 'Customer';
      case ActivityType.credit:
        return 'Credit Bill';
      case ActivityType.payment:
        return 'Payment';
      case ActivityType.recovery:
        return 'Recovery';
    }
  }
}

/// Unified recent activity item across the system
class RecentActivity {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final double? amount;
  final String? status;
  final String? reference;
  final String? customerName;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.amount,
    this.status,
    this.reference,
    this.customerName,
  });
}

/// Data model representing time series point for charts
class TimeSeriesDataPoint {
  final String label;
  final double collectionAmount;
  final double creditAmount;

  const TimeSeriesDataPoint({
    required this.label,
    required this.collectionAmount,
    this.creditAmount = 0.0,
  });
}

/// Comprehensive chart analytics model
class ChartAnalyticsData {
  final DashboardDateFilter filter;
  final List<TimeSeriesDataPoint> points;
  final Map<String, double> statusBreakdown; // Current, Overdue, Settled
  final Map<String, double> agingBreakdown; // Current, 1-30 DPD, 31-60 DPD, 61-90 DPD, 90+ DPD
  final double totalBilledInPeriod;
  final double totalCollectedInPeriod;
  final double maxChartValue;

  const ChartAnalyticsData({
    required this.filter,
    required this.points,
    required this.statusBreakdown,
    required this.agingBreakdown,
    required this.totalBilledInPeriod,
    required this.totalCollectedInPeriod,
    required this.maxChartValue,
  });

  factory ChartAnalyticsData.empty(DashboardDateFilter filter) {
    return ChartAnalyticsData(
      filter: filter,
      points: const [],
      statusBreakdown: const {'Current': 0, 'Overdue': 0, 'Settled': 0},
      agingBreakdown: const {'Current': 0, '1-30 DPD': 0, '31-60 DPD': 0, '61-90 DPD': 0, '90+ DPD': 0},
      totalBilledInPeriod: 0,
      totalCollectedInPeriod: 0,
      maxChartValue: 1000,
    );
  }
}

/// Real calculated overview metrics from SQLite
class DashboardOverviewMetrics {
  // Global Metrics
  final int totalCustomers;
  final double totalCreditAmount;
  final double totalCollectedAmount;
  final double outstandingBalance;
  final double todayCollections;
  final double overdueBalance;
  final int overdueCount;
  final double recoveryRate; // percentage 0-100%

  // Backward compatibility aliases
  double get totalDebt => totalCreditAmount;
  double get recoveredAmount => totalCollectedAmount;

  // Recovery Officer specifics
  final int assignedCustomersCount;
  final double assignedOutstandingBalance;
  final int todayFollowUpsCount;
  final double todayPromisedAmount;
  final int todayInteractionsCount;

  // Finance Officer specifics
  final int totalPaymentsCount;
  final double monthToDateCollections;
  final int activeBillsCount;
  final int settledBillsCount;

  // Admin specifics
  final int staffCount;
  final int auditLogCount;

  const DashboardOverviewMetrics({
    required this.totalCustomers,
    required this.totalCreditAmount,
    required this.totalCollectedAmount,
    required this.outstandingBalance,
    required this.todayCollections,
    required this.overdueBalance,
    required this.overdueCount,
    required this.recoveryRate,
    this.assignedCustomersCount = 0,
    this.assignedOutstandingBalance = 0.0,
    this.todayFollowUpsCount = 0,
    this.todayPromisedAmount = 0.0,
    this.todayInteractionsCount = 0,
    this.totalPaymentsCount = 0,
    this.monthToDateCollections = 0.0,
    this.activeBillsCount = 0,
    this.settledBillsCount = 0,
    this.staffCount = 0,
    this.auditLogCount = 0,
  });

  factory DashboardOverviewMetrics.zero() {
    return const DashboardOverviewMetrics(
      totalCustomers: 0,
      totalCreditAmount: 0.0,
      totalCollectedAmount: 0.0,
      outstandingBalance: 0.0,
      todayCollections: 0.0,
      overdueBalance: 0.0,
      overdueCount: 0,
      recoveryRate: 0.0,
      assignedCustomersCount: 0,
      assignedOutstandingBalance: 0.0,
      todayFollowUpsCount: 0,
      todayPromisedAmount: 0.0,
      todayInteractionsCount: 0,
      totalPaymentsCount: 0,
      monthToDateCollections: 0.0,
      activeBillsCount: 0,
      settledBillsCount: 0,
      staffCount: 0,
      auditLogCount: 0,
    );
  }
}

/// State representation for the dashboard
class DashboardState {
  final bool isLoading;
  final String? errorMessage;
  final DashboardOverviewMetrics metrics;
  final ChartAnalyticsData analytics;
  final List<RecentActivity> recentActivities;
  final DashboardDateFilter dateFilter;
  final String activityFilter;
  final bool isDatabaseEmpty;

  const DashboardState({
    required this.isLoading,
    this.errorMessage,
    required this.metrics,
    required this.analytics,
    required this.recentActivities,
    required this.dateFilter,
    required this.activityFilter,
    required this.isDatabaseEmpty,
  });

  bool get hasError => errorMessage != null;

  factory DashboardState.initial() {
    return DashboardState(
      isLoading: true,
      errorMessage: null,
      metrics: DashboardOverviewMetrics.zero(),
      analytics: ChartAnalyticsData.empty(DashboardDateFilter.thisWeek),
      recentActivities: const [],
      dateFilter: DashboardDateFilter.thisWeek,
      activityFilter: 'all',
      isDatabaseEmpty: false,
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    DashboardOverviewMetrics? metrics,
    ChartAnalyticsData? analytics,
    List<RecentActivity>? recentActivities,
    DashboardDateFilter? dateFilter,
    String? activityFilter,
    bool? isDatabaseEmpty,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      metrics: metrics ?? this.metrics,
      analytics: analytics ?? this.analytics,
      recentActivities: recentActivities ?? this.recentActivities,
      dateFilter: dateFilter ?? this.dateFilter,
      activityFilter: activityFilter ?? this.activityFilter,
      isDatabaseEmpty: isDatabaseEmpty ?? this.isDatabaseEmpty,
    );
  }
}
