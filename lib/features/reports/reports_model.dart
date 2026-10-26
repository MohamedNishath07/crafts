/// Model for reports state
class ReportsModel {
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final List<ReportItem> reports;
  final double totalBilled;
  final double totalCollected;
  final double totalOutstanding;
  final DateTimeRange? dateRange;
  final String? selectedStatus;
  final String? selectedOfficer;

  ReportsModel._({
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
    this.reports = const [],
    this.totalBilled = 0.0,
    this.totalCollected = 0.0,
    this.totalOutstanding = 0.0,
    this.dateRange,
    this.selectedStatus,
    this.selectedOfficer,
  });

  factory ReportsModel.loading() => ReportsModel._(isLoading: true);
  factory ReportsModel.empty() => ReportsModel._();
  factory ReportsModel.success({
    required List<ReportItem> reports,
    required double totalBilled,
    required double totalCollected,
    required double totalOutstanding,
  }) => ReportsModel._()
    ..reports = reports
    ..totalBilled = totalBilled
    ..totalCollected = totalCollected
    ..totalOutstanding = totalOutstanding;

  ReportsModel copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    List<ReportItem>? reports,
    double? totalBilled,
    double? totalCollected,
    double? totalOutstanding,
    DateTimeRange? dateRange,
    String? selectedStatus,
    String? selectedOfficer,
  }) => ReportsModel._()
    ..isLoading = isLoading ?? this.isLoading
    ..hasError = hasError ?? this.hasError
    ..errorMessage = errorMessage ?? this.errorMessage
    ..reports = reports ?? this.reports
    ..totalBilled = totalBilled ?? this.totalBilled
    ..totalCollected = totalCollected ?? this.totalCollected
    ..totalOutstanding = totalOutstanding ?? this.totalOutstanding
    ..dateRange = dateRange ?? this.dateRange
    ..selectedStatus = selectedStatus ?? this.selectedStatus
    ..selectedOfficer = selectedOfficer ?? this.selectedOfficer;
}

/// Individual report item
class ReportItem {
  final int id;
  final DateTime date;
  final String debtStatus;
  final double amount;
  final String officerName;
  final String customerName;

  ReportItem({
    required this.id,
    required this.date,
    required this.debtStatus,
    required this.amount,
    required this.officerName,
    required this.customerName,
  });
}