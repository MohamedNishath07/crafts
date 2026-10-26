import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/reports/reports_model.dart';

/// Provider for reports state
final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportsModel>((ref) {
  return ReportsNotifier(ref);
});

/// Notifier for reports state management
class ReportsNotifier extends StateNotifier<ReportsModel> {
  final Ref _ref;
  ReportsNotifier(_ref) : _ref = _ref, super(ReportsModel.loading());

  Future<void> loadReports({
    DateTimeRange? dateRange,
    String? status,
    String? officer,
  }) async {
    state = state.copyWith(isLoading: true);

    // TODO: Replace with actual API call
    // For now, simulate with sample data
    await Future.delayed(const Duration(milliseconds: 500));

    final sampleReports = [
      ReportItem(
        id: 1,
        date: DateTime.now().subtract(const Duration(days: 30)),
        debtStatus: 'Overdue',
        amount: 5200.00,
        officerName: 'John Doe',
        customerName: 'ABC Corp',
      ),
      ReportItem(
        id: 2,
        date: DateTime.now().subtract(const Duration(days: 60)),
        debtStatus: 'Settled',
        amount: 3800.00,
        officerName: 'Jane Smith',
        customerName: 'XYZ Inc',
      ),
    ];

    state = state.copyWith(
      isLoading: false,
      reports: sampleReports,
      totalBilled: 9000.00,
      totalCollected: 5200.00,
      totalOutstanding: 3800.00,
    );
  }

  Future<void> generateReport({
    required DateTimeRange dateRange,
    required String status,
    required String officer,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Generate actual report with filters
    state = state.copyWith(isLoading: false);
  }
}