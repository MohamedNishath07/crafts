import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/audit/audit_log_model.dart';
import 'package:crafts/features/audit/audit_log_repository.dart';

/// Notifier for audit log operations
class AuditLogNotifier extends StateNotifier<AuditLogFilterState> {
  final AuditLogRepository _repository;

  AuditLogNotifier(this._repository) : super(const AuditLogFilterState());

  /// Fetch audit logs with current filter
  Future<List<AuditLogEntry>> fetchLogs({int limit = 100}) async {
    state = state.copyWith(
      action: state.action,
      entityType: state.entityType,
      startDate: state.startDate,
      endDate: state.endDate,
    );
    final logs = await _repository.fetchLogs(
      actionFilter: state.action,
      entityTypeFilter: state.entityType,
      startDate: state.startDate,
      endDate: state.endDate,
      limit: limit,
    );
    return logs;
  }

  /// Set action filter
  void setActionFilter(String? action) {
    state = state.copyWith(action: action);
  }

  /// Set entity type filter
  void setEntityTypeFilter(String? entityType) {
    state = state.copyWith(entityType: entityType);
  }

  /// Set date range filter
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  /// Clear all filters
  void clearFilters() {
    state = const AuditLogFilterState();
  }
}

/// Extension for [AuditLogFilterState] copyWith
extension AuditLogFilterStateExtension on AuditLogFilterState {
  AuditLogFilterState copyWith({
    String? action,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AuditLogFilterState(
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}