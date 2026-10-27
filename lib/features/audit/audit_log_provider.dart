import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/audit/audit_log_model.dart';
import 'package:crafts/features/audit/audit_log_repository.dart';

/// Provider for the audit log repository
final auditLogRepositoryProvider = Provider((ref) => AuditLogRepository());

/// Provider for the current tenant ID
final tenantIdProvider = StateProvider((ref) => 'default_tenant');

/// State for audit log filter
class AuditLogFilterState {
  final String? action;
  final String? entityType;
  final DateTime? startDate;
  final DateTime? endDate;

  const AuditLogFilterState({
    this.action,
    this.entityType,
    this.startDate,
    this.endDate,
  });

  AuditLogFilter toFilter() => AuditLogFilter(
        action: action,
        entityType: entityType,
        startDate: startDate,
        endDate: endDate,
      );

  Map<String, dynamic> toMap() => toFilter().toMap();

  factory AuditLogFilterState.fromMap(Map<String, dynamic> map) {
    return AuditLogFilterState(
      action: map['action'] as String?,
      entityType: map['entity_type'] as String?,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
    );
  }
}

/// Notifier for audit log operations
class AuditLogNotifier extends StateNotifier<AuditLogFilterState> {
  final AuditLogRepository _repository;

  AuditLogNotifier(this._repository)
      : super(const AuditLogFilterState());

  /// Fetch audit logs with current filter
  Future<List<AuditLogEntry>> fetchLogs({int limit = 100}) async {
    this.state = this.state.copyWith(
      action: this.state.action,
      entityType: this.state.entityType,
      startDate: this.state.startDate,
      endDate: this.state.endDate,
    );
    final logs = await _repository.fetchLogs(
      actionFilter: this.state.action,
      entityTypeFilter: this.state.entityType,
      startDate: this.state.startDate,
      endDate: this.state.endDate,
      limit: limit,
    );
    return logs;
  }

  /// Set action filter
  void setActionFilter(String? action) {
    this.state = this.state.copyWith(action: action);
  }

  /// Set entity type filter
  void setEntityTypeFilter(String? entityType) {
    this.state = this.state.copyWith(entityType: entityType);
  }

  /// Set date range filter
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    this.state = this.state.copyWith(startDate: startDate, endDate: endDate);
  }

  /// Clear all filters
  void clearFilters() {
    this.state = const AuditLogFilterState();
  }
}

/// Riverpod provider for the audit log notifier
final auditLogNotifierProvider =
    StateNotifierProvider((ref) {
  return AuditLogNotifier(AuditLogRepository());
}

/// Extensions for AuditLogFilterState
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