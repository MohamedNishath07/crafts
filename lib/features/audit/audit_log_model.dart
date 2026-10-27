

/// Model for an audit log entry
class AuditLogEntry {
  final String id;
  final String tenantId;
  final String? userId;
  final String action;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.tenantId,
    this.userId,
    required this.action,
    this.entityType,
    this.entityId,
    this.details,
    required this.createdAt,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id']?.toString() ?? '',
      tenantId: map['tenant_id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      action: map['action']?.toString() ?? '',
      entityType: map['entity_type']?.toString(),
      entityId: map['entity_id']?.toString(),
      details: map['details'] != null
          ? Map<String, dynamic>.from(map['details'])
          : null,
      createdAt: map['created_at'] != null
          ? (map['created_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if this entry matches a filter
  bool matchesFilter({
    String? actionFilter,
    String? entityTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (actionFilter != null && action != actionFilter) return false;
    if (entityTypeFilter != null && entityType != entityTypeFilter) return false;
    if (startDate != null && createdAt.isBefore(startDate)) return false;
    if (endDate != null && createdAt.isAfter(endDate)) return false;
    return true;
  }
}

/// Filter options for audit log viewer
class AuditLogFilter {
  final String? action;
  final String? entityType;
  final DateTime? startDate;
  final DateTime? endDate;

  const AuditLogFilter({
    this.action,
    this.entityType,
    this.startDate,
    this.endDate,
  });

  factory AuditLogFilter.fromMap(Map<String, dynamic> map) {
    return AuditLogFilter(
      action: map['action'] as String?,
      entityType: map['entity_type'] as String?,
      startDate: map['start_date'] != null
          ? (map['start_date'] as dynamic).toDate()
          : null,
      endDate: map['end_date'] != null
          ? (map['end_date'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'entity_type': entityType,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}