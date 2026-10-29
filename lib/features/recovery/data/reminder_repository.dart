import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/reminder_settings.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  try {
    return ReminderRepository(Supabase.instance.client);
  } catch (_) {
    return ReminderRepository(null);
  }
});

/// Repository for reminder settings and reminder dispatch records.
class ReminderRepository {
  final SupabaseClient? _client;
  static const _uuid = Uuid();

  ReminderRepository(this._client);

  /// Fetch reminder settings for a tenant (creates defaults if none exist).
  Future<ReminderSettings> fetchReminderSettings(String tenantId) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('reminder_settings')
        .select()
        .eq('tenant_id', tenantId)
        .maybeSingle();

    if (response != null) {
      return ReminderSettings.fromJson(response);
    }

    // Create default settings if none exist
    final newId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final defaultSettings = {
      'id': newId,
      'tenant_id': tenantId,
      'email_enabled': true,
      'sms_enabled': false,
      'email_offset_days': [3, 1, 0],
      'sms_offset_days': [3, 0],
      'message_template':
          'Dear {{customer_name}}, a payment of {{amount}} on account {{reference_number}} is due on {{due_date}}. Please make your payment to avoid further collection action.',
      'created_at': now,
      'updated_at': now,
    };

    final insertResponse = await client
        .from('reminder_settings')
        .insert(defaultSettings);

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
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final now = DateTime.now().toIso8601String();

    // Upsert: update if exists, insert otherwise
    final existing = await client
        .from('reminder_settings')
        .select('id')
        .eq('tenant_id', tenantId)
        .maybeSingle();

    if (existing != null) {
      final response = await client
          .from('reminder_settings')
          .update({
            'email_enabled': emailEnabled,
            'sms_enabled': smsEnabled,
            'email_offset_days': emailOffsetDays,
            'sms_offset_days': smsOffsetDays,
            'message_template': messageTemplate,
            'updated_at': now,
          })
          .eq('tenant_id', tenantId)
          .select()
          .single();

      return ReminderSettings.fromJson(response);
    } else {
      final newId = _uuid.v4();
      final response = await client
          .from('reminder_settings')
          .insert({
            'id': newId,
            'tenant_id': tenantId,
            'email_enabled': emailEnabled,
            'sms_enabled': smsEnabled,
            'email_offset_days': emailOffsetDays,
            'sms_offset_days': smsOffsetDays,
            'message_template': messageTemplate,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      return ReminderSettings.fromJson(response);
    }
  }

  /// Fetch reminder dispatches for a tenant, newest first.
  Future<List<ReminderDispatch>> fetchReminderDispatches(String tenantId) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('reminder_dispatches')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

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
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final newId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final response = await client
        .from('reminder_dispatches')
        .insert({
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
        })
        .select()
        .single();

    return ReminderDispatch.fromJson(response);
  }

  /// Fetch aggregated dashboard metrics for a tenant.
  Future<Map<String, dynamic>> fetchDashboardMetrics(String tenantId) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('interaction_logs')
        .select('''
          count: count(*),
          total_debt: sum(debt_balance),
          overdue_balance: sum(case when overdue_flag = true then debt_balance else 0 end),
          recovered_amount: sum(case when outcome = 'Payment Received' then debt_balance else 0 end)
        ''')
        .eq('tenant_id', tenantId);

    final row = response.isNotEmpty ? response[0] : null;
    if (row == null) {
      return {'totalCustomers': 0, 'totalDebt': 0.0, 'overdueBalance': 0.0, 'recoveredAmount': 0.0};
    }

    // Parse count separately since Supabase returns it differently
    final totalCustomers = row['count'] ?? 0;
    final totalDebt = (row['total_debt'] ?? 0.0).toDouble();
    final overdueBalance = (row['overdue_balance'] ?? 0.0).toDouble();
    final recoveredAmount = (row['recovered_amount'] ?? 0.0).toDouble();

    return {
      'totalCustomers': totalCustomers,
      'totalDebt': totalDebt,
      'overdueBalance': overdueBalance,
      'recoveredAmount': recoveredAmount,
    };
  }
}
