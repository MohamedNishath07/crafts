import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/payment.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  try {
    return PaymentRepository(Supabase.instance.client);
  } catch (_) {
    return PaymentRepository(null);
  }
});

class PaymentRepository {
  final SupabaseClient? _client;
  static const _uuid = Uuid();

  PaymentRepository(this._client);

  /// Fetch all payments for a given tenant, newest first
  Future<List<Payment>> fetchPayments(String tenantId) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('payments')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Payment.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Record a payment and atomically deflate the debt's remaining balance.
  ///
  /// Steps:
  /// 1. Insert into `payments` (append-only, immutable)
  /// 2. Decrement `debts.remaining_balance_cents` by amount_cents
  /// 3. If remaining balance reaches 0, set debt status to 'settled'
  Future<Payment> recordPayment({
    required String tenantId,
    required String debtId,
    required String recordedById,
    required int amountCents,
    required String paymentMethod,
    required String transactionReference,
    String? notes,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    // Fetch the current debt to validate balance and get remaining balance
    final debtResponse = await client
        .from('debts')
        .select('id, remaining_balance_cents, status, principal_amount_cents')
        .eq('id', debtId)
        .eq('tenant_id', tenantId)
        .single();

    final debt = debtResponse;
    final currentRemaining = debt['remaining_balance_cents'] as int;
    final currentStatus = debt['status'] as String;

    if (currentStatus == 'settled') {
      throw Exception('Cannot record payment on a settled debt.');
    }

    if (amountCents <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }

    if (amountCents > currentRemaining) {
      throw Exception(
        'Payment amount (\$${(amountCents / 100).toStringAsFixed(2)}) exceeds outstanding balance '
        '(\$${(currentRemaining / 100).toStringAsFixed(2)}).',
      );
    }

    final newId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final receiptNumber = 'RCP-${DateTime.now().millisecondsSinceEpoch}';

    final newRemaining = currentRemaining - amountCents;
    final newStatus = newRemaining == 0 ? 'settled' : currentStatus;

    // Insert payment record
    final paymentPayload = {
      'id': newId,
      'tenant_id': tenantId,
      'debt_id': debtId,
      'recorded_by_id': recordedById,
      'amount_cents': amountCents,
      'payment_method': paymentMethod,
      'transaction_reference': transactionReference.trim(),
      'receipt_number': receiptNumber,
      'notes': notes?.trim(),
      'created_at': now,
    };

    final paymentResponse = await client
        .from('payments')
        .insert(paymentPayload)
        .select()
        .single();

    // Update debt balance and status
    await client
        .from('debts')
        .update({
          'remaining_balance_cents': newRemaining,
          'status': newStatus,
          'updated_at': now,
        })
        .eq('id', debtId)
        .eq('tenant_id', tenantId);

    return Payment.fromJson(paymentResponse);
  }

  /// Default payment records used in offline development or test environments
  List<Payment> generateDefaultPayments(String tenantId, List<String> debtIds) {
    final now = DateTime.now();
    final List<Payment> payments = [];

    if (debtIds.isNotEmpty) {
      payments.add(Payment(
        id: 'p-00000000-0000-0000-0000-000000000001',
        tenantId: tenantId,
        debtId: debtIds[0],
        recordedById: '10000000-0000-0000-0000-000000000003',
        amountCents: 125000,
        paymentMethod: 'bank_transfer',
        transactionReference: 'WIRE-99210',
        receiptNumber: 'RCP-1000001',
        notes: 'Partial payment on DR-1001',
        createdAt: now.subtract(const Duration(days: 5)),
      ));
    }

    return payments;
  }
}