class AsyncDashboardMetrics {
  final bool isLoading;
  final bool hasError;
  final int totalCustomers;
  final double totalDebt;
  final double overdueBalance;
  final double recoveredAmount;
  final String errorMessage;

  AsyncDashboardMetrics._({
    this.isLoading = false,
    this.hasError = false,
    this.totalCustomers = 0,
    this.totalDebt = 0.0,
    this.overdueBalance = 0.0,
    this.recoveredAmount = 0.0,
    this.errorMessage = '',
  });

  factory AsyncDashboardMetrics.loading() => AsyncDashboardMetrics._(isLoading: true);

  factory AsyncDashboardMetrics.empty() => AsyncDashboardMetrics._();

  factory AsyncDashboardMetrics.success({
    required int totalCustomers,
    required double totalDebt,
    required double overdueBalance,
    required double recoveredAmount,
  }) => AsyncDashboardMetrics._(
        totalCustomers: totalCustomers,
        totalDebt: totalDebt,
        overdueBalance: overdueBalance,
        recoveredAmount: recoveredAmount,
      );

  factory AsyncDashboardMetrics.error(String message) => AsyncDashboardMetrics._(
        hasError: true,
        errorMessage: message,
      );

  AsyncDashboardMetrics copyWith({
    bool? isLoading,
    bool? hasError,
    int? totalCustomers,
    double? totalDebt,
    double? overdueBalance,
    double? recoveredAmount,
    String? errorMessage,
  }) => AsyncDashboardMetrics._(
        isLoading: isLoading ?? this.isLoading,
        hasError: hasError ?? this.hasError,
        totalCustomers: totalCustomers ?? this.totalCustomers,
        totalDebt: totalDebt ?? this.totalDebt,
        overdueBalance: overdueBalance ?? this.overdueBalance,
        recoveredAmount: recoveredAmount ?? this.recoveredAmount,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  String toString() =>
      'AsyncDashboardMetrics{totalCustomers: $totalCustomers, totalDebt: \$$totalDebt}, overdue: \$$overdueBalance, recovered: \$$recoveredAmount';
}