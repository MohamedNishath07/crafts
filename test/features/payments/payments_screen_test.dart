import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/payments/data/payment_repository.dart';
import 'package:crafts/features/payments/domain/payment.dart';
import 'package:crafts/features/payments/presentation/payments_screen.dart';
import 'package:crafts/features/debts/data/debt_repository.dart';
import 'package:crafts/features/debts/domain/debt.dart';

class _MockPaymentRepo extends PaymentRepository {
  final List<Payment> _list;

  _MockPaymentRepo(this._list) : super(null);

  @override
  Future<List<Payment>> fetchPayments(String tenantId) async {
    return List<Payment>.from(_list);
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
    return Payment(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId,
      debtId: debtId,
      recordedById: recordedById,
      amountCents: amountCents,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      receiptNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch}',
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}

class _MockDebtRepo extends DebtRepository {
  final List<Debt> _list;

  _MockDebtRepo(this._list) : super(null);

  @override
  Future<List<Debt>> fetchDebts(String tenantId) async {
    return List<Debt>.from(_list);
  }
}

void main() {
  final mockPayments = [
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

  final mockDebts = [
    Debt(
      id: 'd-1',
      tenantId: 'tenant-1',
      customerId: 'c-1',
      referenceNumber: 'DR-1001',
      principalAmountCents: 500000,
      remainingBalanceCents: 375000,
      originDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 12, 1),
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 10, 1),
    ),
  ];

  testWidgets('PaymentsScreen renders headers and payment rows', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final payRepo = _MockPaymentRepo([...mockPayments]);
    final debtRepo = _MockDebtRepo([...mockDebts]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(payRepo),
          debtRepositoryProvider.overrideWithValue(debtRepo),
        ],
        child: const MaterialApp(
          home: PaymentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payments & Transactions'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Record Payment'), findsOneWidget);
    expect(find.text('WIRE-99210'), findsOneWidget);
    expect(find.text('CASH-5500'), findsOneWidget);
    expect(find.text('Showing 2 records'), findsOneWidget);
  });

  testWidgets('Record Payment dialog opens and shows form fields', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final payRepo = _MockPaymentRepo([...mockPayments]);
    final debtRepo = _MockDebtRepo([...mockDebts]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(payRepo),
          debtRepositoryProvider.overrideWithValue(debtRepo),
        ],
        child: const MaterialApp(
          home: PaymentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addBtn = find.widgetWithText(ElevatedButton, 'Record Payment');
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);

    // Debt dropdown is present (labeled field)
    expect(find.text('Outstanding Debt *'), findsOneWidget);

    final amountField = find.descendant(
      of: dialog,
      matching: find.widgetWithText(TextFormField, 'Payment Amount *'),
    );
    expect(amountField, findsOneWidget);

    final txnRefField = find.descendant(
      of: dialog,
      matching: find.widgetWithText(TextFormField, 'Transaction Reference *'),
    );
    expect(txnRefField, findsOneWidget);
  });

  testWidgets('Record Payment dialog validates empty form', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final payRepo = _MockPaymentRepo([...mockPayments]);
    final debtRepo = _MockDebtRepo([...mockDebts]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(payRepo),
          debtRepositoryProvider.overrideWithValue(debtRepo),
        ],
        child: const MaterialApp(
          home: PaymentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addBtn = find.widgetWithText(ElevatedButton, 'Record Payment');
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    final submitBtn = find.descendant(
      of: dialog,
      matching: find.widgetWithText(ElevatedButton, 'Record Payment'),
    );
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Please select an outstanding debt'), findsOneWidget);
    expect(find.text('Please enter payment amount'), findsOneWidget);
    expect(find.text('Please enter a transaction reference'), findsOneWidget);
  });
}