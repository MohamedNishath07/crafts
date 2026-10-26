import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/interaction.dart';

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  try {
    return InteractionRepository(Supabase.instance.client);
  } catch (_) {
    return InteractionRepository(null);
  }
});

class InteractionRepository {
  final SupabaseClient? _client;
  static const _uuid = Uuid();

  InteractionRepository(this._client);

  /// Fetch all interactions for the tenant, newest first
  Future<List<Interaction>> fetchInteractions(String tenantId) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('interaction_logs')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Interaction.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetch interactions filtered by follow-up date
  Future<List<Interaction>> fetchFollowUpInteractions(String tenantId, DateTime followUpDate) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final start = DateTime(followUpDate.year, followUpDate.month, followUpDate.day).toIso8601String();
    final end = DateTime(followUpDate.year, followUpDate.month, followUpDate.day + 1).toIso8601String();

    final response = await client
        .from('interaction_logs')
        .select()
        .eq('tenant_id', tenantId)
        .gte('follow_up_date', start)
        .lte('follow_up_date', end)
        .order('follow_up_date', ascending: true);

    return (response as List<dynamic>)
        .map((row) => Interaction.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Save a new recovery interaction
  Future<Interaction> saveInteraction({
    required String debtId,
    required String debtCustomerId,
    required String officerId,
    required String actionType,
    required String outcome,
    DateTime? followUpDate,
    int? promisedAmountCents,
    String? notes,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final newId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    if (followUpDate != null) {
      final debtResponse = await client
          .from('debts')
          .select('status')
          .eq('id', debtId)
          .eq('tenant_id', debtId.contains('-') ? debtId.split('-').first : debtId)
          .single();

      if (debtResponse['status'] != 'settled') {
        await client
            .from('debts')
            .update({
              'status': 'ptp_scheduled',
              'updated_at': now,
            })
            .eq('id', debtId)
            .eq('tenant_id', debtId.contains('-') ? debtId.split('-').first : debtId);
      }
    }

    final response = await client
        .from('interaction_logs')
        .insert({
          'id': newId,
          'tenant_id': debtId,
          'debt_id': debtId,
          'customer_id': debtCustomerId,
          'officer_id': officerId,
          'action_type': actionType,
          'outcome': outcome,
          'follow_up_date': followUpDate?.toIso8601String(),
          'promised_amount_cents': promisedAmountCents,
          'notes': notes?.trim(),
          'created_at': now,
        })
        .select()
        .single();

    return Interaction.fromJson(response);
  }
}