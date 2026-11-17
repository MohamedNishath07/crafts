import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/reminder_settings.dart';

import '../../../core/sqlitedatabase.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  try {
    return ReminderRepository(SQLiteDatabase());
  } catch (_) {
    return ReminderRepository(null);
  }
});

class ReminderRepository {
  final SQLiteDatabase? _db;
  static const _uuid = Uuid();

  ReminderRepository(this._db);

  /// Fetch reminder settings for a tenant (creates defaults if none exist).
  Future<ReminderSettings> fetchReminderSettings(String tenantId) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final response = await _db.fetchReminderSettings(tenantId);
    if (response != null) {
      return ReminderSettings.fromJson(response);
    }

    // Create default settings if none exist
    final newId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final defaultSettings = {
      'id': newId,
      'tenant_id': tenantId,
      'email_enabled': 1,
      'sms_enabled': 0,
      'email_offset_days': '3,1,0',
      'sms_offset_days': '3,0',
      'message_template':
          'Dear {{customer_name}}, a payment of {{amount}} on account {{reference_number}} is due on {{due_date}}. Please make your payment to avoid further collection action.',
      'created_at': now,
      'updated_at': now,
    };

    final insertResponse = await _db.upsertReminderSettings(defaultSettings);
    return ReminderSettings.fromJson(insertResponse);
  }

  /// Update reminder settings for a tenant.
  Future<ReminderSettings> saveReminderSettings({
    required String tenantId,
    required bool emailEnabled,
    required bool smsEnabled,
    required List<int> emailOffsetDays,
    required List<int> smsOffsetDays,
    required String messageTemplate,
  }) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final now = DateTime.now().toIso8601String();

    final settings = {
      'tenant_id': tenantId,
      'email_enabled': emailEnabled ? 1 : 0,
      'sms_enabled': smsEnabled ? 1 : 0,
      'email_offset_days': emailOffsetDays.join(','),
      'sms_offset_days': smsOffsetDays.join(','),
      'message_template': messageTemplate,
      'updated_at': now,
    };

    await _db.upsertReminderSettings(settings);

    final saved = await _db.fetchReminderSettings(tenantId);
    return saved != null ? ReminderSettings.fromJson(saved) : ReminderSettings.initial();
  }

  /// Fetch reminder dispatches for a tenant, newest first.
  Future<List<ReminderDispatch>> fetchReminderDispatches(String tenantId) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final response = await _db.fetchReminderDispatches(tenantId);
    return response.map((row) => ReminderDispatch.fromJson(row)).toList();
  }

  /// Record a reminder dispatch.
  Future<ReminderDispatch> createReminderDispatch({
    required String tenantId,
    required String debtId,
    required String customerId,
    required String channel,
    required String recipient,
    required String message,
    required String status,
    DateTime? scheduledFor,
  }) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final newId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final response = await _db.insertReminderDispatch({
      'id': newId,
      'tenant_id': tenantId,
      'debt_id': debtId,
      'customer_id': customerId,
      'channel': channel,
      'recipient': recipient,
      'message': message,
      'status': status,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'sent_at': status == 'sent' ? now : null,
      'created_at': now,
    });

    return ReminderDispatch.fromJson(response);
  }

  /// Fetch aggregated dashboard metrics for a tenant.
  Future<Map<String, dynamic>> fetchDashboardMetrics(String tenantId) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final response = await _db.fetchInteractions(tenantId);
    final totalCustomers = response.length;
    final totalDebt =
        response.fold<double>(0.0, (sum, d) => sum + (d['debt_balance'] ?? 0.0)).toDouble();
    final overdueBalance = response
        .where((d) => d['overdue_flag'] == true)
        .fold<double>(0.0, (sum, d) => sum + (d['debt_balance'] ?? 0.0))
        .toDouble();
    final recoveredAmount = response
        .where((d) => d['outcome'] == 'Payment Received')
        .fold<double>(0.0, (sum, d) => sum + (d['debt_balance'] ?? 0.0))
        .toDouble();

    return {
      'totalCustomers': totalCustomers,
      'totalDebt': totalDebt,
      'overdueBalance': overdueBalance,
      'recoveredAmount': recoveredAmount,
    };
  }
}
