import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/payments/data/payment_repository.dart';
import 'package:crafts/features/payments/domain/payment.dart';
import 'package:crafts/features/payments/presentation/payment_controller.dart';

class _MockPaymentRepository extends PaymentRepository {
  final List<Payment> _payments;

  _MockPaymentRepository(this._payments) : super(null);

  @override
  Future<List<Payment>> fetchPayments(String tenantId) async {
    return List<Payment>.from(_payments);
  }

  @override
  Future<Payment> recordPayment({
    required String tenantId,
    required String debtId,
    required String recordedById,
    required int amountCents,
    required String paymentMethod,
    required String transactionReference,
    String? notes,
  }) async {
    final newPayment = Payment(
      id: 'payment-${_payments.length + 1}',
      tenantId: tenantId,
      debtId: debtId,
      recordedById: recordedById,
      amountCents: amountCents,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      receiptNumber: 'RCP-${_payments.length + 1}',
      notes: notes,
      createdAt: DateTime.now(),
    );
    _payments.add(newPayment);
    return newPayment;
  }
}

void main() {
  final initialPayments = [
    Payment(
      id: 'p-1',
      tenantId: 'tenant-1',
      debtId: 'd-1',
      recordedById: 'u-1',
      amountCents: 125000,
      paymentMethod: 'bank_transfer',
      transactionReference: 'WIRE-99210',
      receiptNumber: 'RCP-1000001',
      notes: 'Partial payment',
      createdAt: DateTime(2026, 10, 10),
    ),
    Payment(
      id: 'p-2',
      tenantId: 'tenant-1',
      debtId: 'd-2',
      recordedById: 'u-3',
      amountCents: 50000,
      paymentMethod: 'cash',
      transactionReference: 'CASH-5500',
      receiptNumber: 'RCP-1000002',
      createdAt: DateTime(2026, 10, 12),
    ),
  ];

  test('PaymentController loads initial payments list', () async {
    final repo = _MockPaymentRepository([...initialPayments]);
    final container = ProviderContainer(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final payments = await container.read(paymentControllerProvider.future);
    expect(payments.length, 2);
    expect(payments.first.transactionReference, 'WIRE-99210');
  });

  test('PaymentController records new payment and prepends to state', () async {
    final repo = _MockPaymentRepository([...initialPayments]);
    final container = ProviderContainer(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(paymentControllerProvider.future);

    await container.read(paymentControllerProvider.notifier).recordPayment(
          debtId: 'd-1',
          amountCents: 75000,
          paymentMethod: 'cash',
          transactionReference: 'CASH-750',
        );

    final updated = container.read(paymentControllerProvider).value!;
    expect(updated.length, 3);
    expect(updated.first.transactionReference, 'CASH-750');
    expect(updated.first.amountCents, 75000);
  });

  test('Payment.amount converts cents to display currency', () {
    final payment = Payment(
      id: 'p-1',
      tenantId: 'tenant-1',
      debtId: 'd-1',
      recordedById: 'u-1',
      amountCents: 150000,
      paymentMethod: 'cash',
      transactionReference: 'TXN-1',
      receiptNumber: 'RCP-1',
      createdAt: DateTime(2026, 10, 10),
    );
    expect(payment.amount, 1500.0);
  });

  test('filteredPaymentsProvider filters by transaction reference', () async {
    final repo = _MockPaymentRepository([...initialPayments]);
    final container = ProviderContainer(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(paymentControllerProvider.future);

    expect(container.read(filteredPaymentsProvider).length, 2);

    container.read(paymentSearchQueryProvider.notifier).setQuery('WIRE');
    expect(container.read(filteredPaymentsProvider).length, 1);
    expect(container.read(filteredPaymentsProvider).first.transactionReference, 'WIRE-99210');

    container.read(paymentSearchQueryProvider.notifier).setQuery('CASH');
    expect(container.read(filteredPaymentsProvider).length, 1);

    container.read(paymentSearchQueryProvider.notifier).setQuery('');
    expect(container.read(filteredPaymentsProvider).length, 2);
  });

  test('paginatedPaymentsProvider respects page size', () async {
    final repo = _MockPaymentRepository([...initialPayments]);
    final container = ProviderContainer(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(paymentControllerProvider.future);

    container.read(paymentPageSizeProvider.notifier).setPageSize(1);
    container.read(paymentPageIndexProvider.notifier).setPage(0);

    final page0 = container.read(paginatedPaymentsProvider);
    expect(page0.length, 1);

    container.read(paymentPageIndexProvider.notifier).nextPage();
    final page1 = container.read(paginatedPaymentsProvider);
    expect(page1.length, 1);
  });

  test('Payment.copyWith produces modified copy', () {
    final original = Payment(
      id: 'p-1',
      tenantId: 'tenant-1',
      debtId: 'd-1',
      recordedById: 'u-1',
      amountCents: 100000,
      paymentMethod: 'cash',
      transactionReference: 'TXN-1',
      receiptNumber: 'RCP-1',
      createdAt: DateTime(2026, 10, 10),
    );
    final updated = original.copyWith(amountCents: 200000, paymentMethod: 'check');
    expect(updated.amountCents, 200000);
    expect(updated.paymentMethod, 'check');
    expect(updated.id, 'p-1');
    expect(updated.transactionReference, 'TXN-1');
  });
}