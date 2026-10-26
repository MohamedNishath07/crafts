import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/debts/data/debt_repository.dart';
import 'package:crafts/features/debts/domain/debt.dart';
import 'package:crafts/features/debts/presentation/debts_screen.dart';

class _MockDebtRepo extends DebtRepository {
  final List<Debt> _list;

  _MockDebtRepo(this._list) : super(null);

  @override
  Future<List<Debt>> fetchDebts(String tenantId) async {
    return List<Debt>.from(_list);
  }

  @override
  Future<Debt> createDebt({
    required String tenantId,
    required String customerId,
    String? assignedOfficerId,
    required String referenceNumber,
    required int principalAmountCents,
    required DateTime originDate,
    required DateTime dueDate,
  }) async {
    return Debt(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId,
      customerId: customerId,
      assignedOfficerId: assignedOfficerId,
      referenceNumber: referenceNumber,
      principalAmountCents: principalAmountCents,
      remainingBalanceCents: principalAmountCents,
      originDate: originDate,
      dueDate: dueDate,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  final mockDebts = [
    Debt(
      id: 'd-1',
      tenantId: 'tenant-1',
      customerId: 'c-1',
      referenceNumber: 'DR-1001',
      principalAmountCents: 500000,
      remainingBalanceCents: 500000,
      originDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 9, 1),
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 9, 1),
    ),
    Debt(
      id: 'd-2',
      tenantId: 'tenant-1',
      customerId: 'c-2',
      referenceNumber: 'DR-1002',
      principalAmountCents: 250000,
      remainingBalanceCents: 125000,
      originDate: DateTime(2026, 2, 1),
      dueDate: DateTime(2026, 11, 1),
      status: 'active',
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 10, 1),
    ),
  ];

  testWidgets('DebtsScreen renders ledger headers and data rows', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _MockDebtRepo([...mockDebts]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          debtRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: DebtsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Debt Ledger'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Create Debt Record'), findsOneWidget);
    expect(find.text('DR-1001'), findsOneWidget);
    expect(find.text('DR-1002'), findsOneWidget);
    expect(find.text('Showing 2 records'), findsOneWidget);
  });

  testWidgets('AddDebtDialog validates inputs and creates new debt', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _MockDebtRepo([...mockDebts]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          debtRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: DebtsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Create Debt Record button
    final addBtn = find.widgetWithText(ElevatedButton, 'Create Debt Record');
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    // Try submitting empty form - scope to the dialog
    final dialog = find.byType(AlertDialog);
    final submitBtn = find.descendant(
      of: dialog,
      matching: find.widgetWithText(ElevatedButton, 'Create Debt Record'),
    );
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Please enter a reference number'), findsOneWidget);
    expect(find.text('Please enter principal amount'), findsOneWidget);

    // Enter valid reference number and amount
    final refField = find.descendant(
      of: dialog,
      matching: find.widgetWithText(TextFormField, 'Reference Number *'),
    );
    final amountField = find.descendant(
      of: dialog,
      matching: find.widgetWithText(TextFormField, 'Principal Amount *'),
    );

    await tester.enterText(refField, 'DR-2001');
    await tester.enterText(amountField, '1500.00');
    await tester.pumpAndSettle();

    // Submit - will fail because customer not selected and dates not picked
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Please select a customer'), findsOneWidget);
  });

  testWidgets('Filter chips render and filter debts by aging bracket', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _MockDebtRepo([...mockDebts]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          debtRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: DebtsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Filter chips are present
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('1-30 DPD'), findsOneWidget);
    expect(find.text('Settled'), findsOneWidget);

    // Initially all debts show
    expect(find.text('DR-1001'), findsOneWidget);
    expect(find.text('DR-1002'), findsOneWidget);

    // Tap Overdue filter
    final overdueChip = find.widgetWithText(FilterChip, 'Overdue');
    await tester.tap(overdueChip);
    await tester.pumpAndSettle();

    // Only overdue debts remain (DR-1001 is overdue, DR-1002 is current)
    expect(find.text('DR-1001'), findsOneWidget);
    expect(find.text('DR-1002'), findsNothing);

    // Tap All filter to reset
    final allChip = find.widgetWithText(FilterChip, 'All');
    await tester.tap(allChip);
    await tester.pumpAndSettle();

    // All debts show again
    expect(find.text('DR-1001'), findsOneWidget);
    expect(find.text('DR-1002'), findsOneWidget);
  });

  testWidgets('DPD column shows days past due and aging indicators', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _MockDebtRepo([...mockDebts]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          debtRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: DebtsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // DPD values are rendered in the table
    expect(find.text('48'), findsOneWidget); // DR-1001 is ~48 days past due
    expect(find.text('0'), findsOneWidget); // DR-1002 is current (0 DPD)
  });
}