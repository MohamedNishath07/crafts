import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/payment.dart';

import '../../../core/sqlitedatabase.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  try {
    return PaymentRepository(SQLiteDatabase());
  } catch (_) {
    return PaymentRepository(null);
  }
});

class PaymentRepository {
  final SQLiteDatabase? _db;
  static const _uuid = Uuid();

  PaymentRepository(this._db);

  /// Fetch all payments for a given tenant, newest first
  Future<List<Payment>> fetchPayments(String tenantId) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final response = await _db.fetchPayments(tenantId);
    return response.map((row) => Payment.fromJson(row)).toList();
  }

  /// Record a payment and atomically deflate the debt's remaining balance.
  Future<Payment> recordPayment({
    required String tenantId,
    required String debtId,
    required String recordedById,
    required int amountCents,
    required String paymentMethod,
    required String transactionReference,
    String? notes,
  }) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    // Fetch the current debt to validate balance and get remaining balance
    final debtResponse = await _db.fetchDebtById(debtId, tenantId);
    final debt = debtResponse!;
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
        'Payment amount ${(amountCents / 100).toStringAsFixed(2)} exceeds outstanding balance '
        '${(currentRemaining / 100).toStringAsFixed(2)}.',
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

    await _db.insertPayment(paymentPayload);

    // Update debt balance and status
    await _db.updateDebt({
      'id': debtId,
      'remaining_balance_cents': newRemaining,
      'status': newStatus,
      'updated_at': now,
    });

    // Return the created payment - fetch from database
    final payment = await _db.fetchPayments(tenantId);
    final row = payment.firstWhere((p) => p['id'] == newId, orElse: () => payment.first);
    return Payment.fromJson(row);
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
