import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/debt.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  try {
    return DebtRepository(Supabase.instance.client);
  } catch (_) {
    return DebtRepository(null);
  }
});

class DebtRepository {
  final SupabaseClient? _client;
  static const _uuid = Uuid();

  DebtRepository(this._client);

  /// Fetch all debts for a given tenant
  Future<List<Debt>> fetchDebts(String tenantId) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('debts')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Debt.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Create a new debt record. remaining_balance is initialized to principal_amount.
  Future<Debt> createDebt({
    required String tenantId,
    required String customerId,
    String? assignedOfficerId,
    required String referenceNumber,
    required int principalAmountCents,
    required DateTime originDate,
    required DateTime dueDate,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final newId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final payload = {
      'id': newId,
      'tenant_id': tenantId,
      'customer_id': customerId,
      'assigned_officer_id': assignedOfficerId,
      'reference_number': referenceNumber.trim(),
      'principal_amount_cents': principalAmountCents,
      'remaining_balance_cents': principalAmountCents,
      'origin_date': originDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': 'active',
      'created_at': now,
      'updated_at': now,
    };

    final response = await client
        .from('debts')
        .insert(payload)
        .select()
        .single();

    return Debt.fromJson(response);
  }

  /// Update an existing debt record (e.g. status or assigned officer).
  Future<Debt> updateDebt({
    required String debtId,
    String? referenceNumber,
    int? principalAmountCents,
    int? remainingBalanceCents,
    DateTime? originDate,
    DateTime? dueDate,
    String? status,
    String? assignedOfficerId,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final now = DateTime.now().toIso8601String();
    final payload = <String, dynamic>{
      'updated_at': now,
    };

    if (referenceNumber != null) payload['reference_number'] = referenceNumber.trim();
    if (principalAmountCents != null) payload['principal_amount_cents'] = principalAmountCents;
    if (remainingBalanceCents != null) payload['remaining_balance_cents'] = remainingBalanceCents;
    if (originDate != null) payload['origin_date'] = originDate.toIso8601String();
    if (dueDate != null) payload['due_date'] = dueDate.toIso8601String();
    if (status != null) payload['status'] = status;
    if (assignedOfficerId != null) payload['assigned_officer_id'] = assignedOfficerId;

    final response = await client
        .from('debts')
        .update(payload)
        .eq('id', debtId)
        .select()
        .single();

    return Debt.fromJson(response);
  }

  /// Fetch a single debt by ID (tenant-scoped)
  Future<Debt?> fetchDebtById(String tenantId, String debtId) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('debts')
        .select()
        .eq('id', debtId)
        .eq('tenant_id', tenantId)
        .maybeSingle();

    if (response == null) return null;
    return Debt.fromJson(response);
  }

  /// Default debt records used in offline development or test environments
  List<Debt> generateDefaultDebts(String tenantId, List<String> customerIds) {
    final now = DateTime.now();
    final List<Debt> debts = [];

    // Marcus Vance - overdue
    debts.add(Debt(
      id: 'd-00000000-0000-0000-0000-000000000001',
      tenantId: tenantId,
      customerId: customerIds.isNotEmpty ? customerIds[0] : 'c-1',
      assignedOfficerId: null,
      referenceNumber: 'DR-1001',
      principalAmountCents: 500000,
      remainingBalanceCents: 500000,
      originDate: now.subtract(const Duration(days: 120)),
      dueDate: now.subtract(const Duration(days: 30)),
      status: 'active',
      createdAt: now.subtract(const Duration(days: 120)),
      updatedAt: now.subtract(const Duration(days: 30)),
    ));

    // Sarah Jenkins - current
    if (customerIds.length > 1) {
      debts.add(Debt(
        id: 'd-00000000-0000-0000-0000-000000000002',
        tenantId: tenantId,
        customerId: customerIds[1],
        assignedOfficerId: null,
        referenceNumber: 'DR-1002',
        principalAmountCents: 250000,
        remainingBalanceCents: 125000,
        originDate: now.subtract(const Duration(days: 60)),
        dueDate: now.add(const Duration(days: 15)),
        status: 'active',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ));
    }

    // Robert Chen - settled
    if (customerIds.length > 2) {
      debts.add(Debt(
        id: 'd-00000000-0000-0000-0000-000000000003',
        tenantId: tenantId,
        customerId: customerIds[2],
        assignedOfficerId: null,
        referenceNumber: 'DR-1003',
        principalAmountCents: 100000,
        remainingBalanceCents: 0,
        originDate: now.subtract(const Duration(days: 45)),
        dueDate: now.subtract(const Duration(days: 5)),
        status: 'settled',
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ));
    }

    return debts;
  }
}