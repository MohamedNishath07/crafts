import 'package:crafts/core/sqlitedatabase.dart';
import 'package:crafts/features/audit/audit_log_model.dart';

/// Repository for audit log operations
/// Handles writing audit entries and reading/filtering audit logs
class AuditLogRepository {
  final SQLiteDatabase _db;
  final String _tenantId;

  AuditLogRepository({String? tenantId}) : _tenantId = tenantId ?? 'default_tenant', _db = SQLiteDatabase();

  /// Write an audit log entry
  /// This is append-only - no UPDATE or DELETE permitted
  Future<AuditLogEntry> logAction({
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    final userId = 'anonymous';

    // Insert into audit_logs table - tenant_id isolation enforced by where clause
    final db = await _db.database;
    final id = await db.insert('audit_logs', {
      'tenant_id': _tenantId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'created_at': DateTime.now().toIso8601String(),
      'user_id': userId,
    });

    final results = await db.query(
      'audit_logs',
      where: 'id = ? AND tenant_id = ? AND action = ? AND created_at = ?',
      whereArgs: [id, _tenantId, action, DateTime.now().toIso8601String()],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return AuditLogEntry.fromMap(results.first);
    }

    throw Exception('Failed to write audit log entry');
  }

  /// Fetch audit logs with optional filtering
  Future<List<AuditLogEntry>> fetchLogs({
    String? actionFilter,
    String? entityTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    final db = await _db.database;

    // Build WHERE clause with tenant_id filtering
    final List<String> whereClauses = ['tenant_id = ?'];
    final List<dynamic> whereArgs = [_tenantId];

    // Build filter map for additional filters
    if (actionFilter != null && actionFilter.isNotEmpty) {
      whereClauses.add('action = ?');
      whereArgs.add(actionFilter);
    }
    if (entityTypeFilter != null && entityTypeFilter.isNotEmpty) {
      whereClauses.add('entity_type = ?');
      whereArgs.add(entityTypeFilter);
    }

    // Build date range filter
    if (startDate != null) {
      whereClauses.add('created_at >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('created_at <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final where = whereClauses.join(' AND ');

    final results = await db.query(
      'audit_logs',
      where: where,
      whereArgs: whereArgs,
      limit: limit,
    );

    return results.map((map) => AuditLogEntry.fromMap(map)).toList();
  }

  /// Log user login event
  Future<AuditLogEntry> logUserLogin({required String loginMethod}) async {
    return logAction(
      action: 'user_login',
      details: {'login_method': loginMethod},
    );
  }

  /// Log user logout event
  Future<AuditLogEntry> logUserLogout() async {
    return logAction(
      action: 'user_logout',
    );
  }

  /// Log debt modification
  Future<AuditLogEntry> logDebtModification({
    required String debtId,
    required String action, // e.g., 'modify', 'status_change'
    Map<String, dynamic>? changes,
  }) async {
    return logAction(
      action: action,
      entityType: 'debt',
      entityId: debtId,
      details: changes,
    );
  }

  /// Log payment recording
  Future<AuditLogEntry> logPaymentRecording({
    required String paymentId,
    required double amount,
    required String paymentMethod,
  }) async {
    return logAction(
      action: 'payment_recorded',
      entityType: 'payment',
      entityId: paymentId,
      details: {
        'amount': amount,
        'payment_method': paymentMethod,
      },
    );
  }

  /// Log payment adjustment/compensating transaction
  Future<AuditLogEntry> logPaymentAdjustment({
    required String paymentId,
    required String adjustmentType, // e.g., 'dispute', 'refund', 'correction'
    Map<String, dynamic>? details,
  }) async {
    return logAction(
      action: 'payment_adjustment',
      entityType: 'payment',
      entityId: paymentId,
      details: {'adjustment_type': adjustmentType, ...?details},
    );
  }

  /// Log staff account deactivation/activation
  Future<AuditLogEntry> logStaffRoleChange({
    required String staffId,
    required String action, // e.g., 'deactivate', 'activate'
    Map<String, dynamic>? changes,
  }) async {
    return logAction(
      action: action,
      entityType: 'staff',
      entityId: staffId,
      details: changes,
    );
  }
}