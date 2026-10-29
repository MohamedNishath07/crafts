/// Audit log entry model
class AuditLogEntry {
  final String id;
  final String userId;
  final String actionType;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool success;
  final String? errorMessage;

  AuditLogEntry({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.description,
    DateTime? timestamp,
    this.metadata,
    required this.success,
    this.errorMessage,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: (map['id'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      actionType: (map['actionType'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
      success: map['success'] as bool? ?? true,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'actionType': actionType,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'success': success,
      'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return 'AuditLogEntry{action: $actionType, user: $userId, time: $timestamp, success: $success}';
  }
}

/// Action types for audit logging
class AuditActionTypes {
  static const String reportGenerated = 'report_generated';
  static const String reportExportedPdf = 'report_exported_pdf';
  static const String reportExportedExcel = 'report_exported_excel';
  static const String filterApplied = 'filter_applied';
  static const String filterCleared = 'filter_cleared';
  static const String userLoggedIn = 'user_logged_in';
  static const String userLoggedOut = 'user_logged_out';
  static const String settingChanged = 'setting_changed';
  static const String errorOccurred = 'error_occurred';
}