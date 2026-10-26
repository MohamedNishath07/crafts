import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/debts/data/debt_repository.dart';
import 'package:crafts/features/debts/domain/debt.dart';
import 'package:crafts/features/debts/presentation/debt_controller.dart';

class _MockDebtRepository extends DebtRepository {
  final List<Debt> _debts;

  _MockDebtRepository(this._debts) : super(null);

  @override
  Future<List<Debt>> fetchDebts(String tenantId) async {
    return List<Debt>.from(_debts);
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
    final newDebt = Debt(
      id: 'debt-${_debts.length + 1}',
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
    _debts.add(newDebt);
    return newDebt;
  }
}

void main() {
  final initialDebts = [
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
    Debt(
      id: 'd-3',
      tenantId: 'tenant-1',
      customerId: 'c-3',
      referenceNumber: 'DR-1003',
      principalAmountCents: 100000,
      remainingBalanceCents: 0,
      originDate: DateTime(2026, 3, 1),
      dueDate: DateTime(2026, 8, 1),
      status: 'settled',
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 8, 15),
    ),
  ];

  test('DebtController loads initial debts roster', () async {
    final repo = _MockDebtRepository([...initialDebts]);
    final container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final debts = await container.read(debtControllerProvider.future);
    expect(debts.length, 3);
    expect(debts.first.referenceNumber, 'DR-1001');
  });

  test('DebtController creates new debt and prepends to state', () async {
    final repo = _MockDebtRepository([...initialDebts]);
    final container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(debtControllerProvider.future);

    await container.read(debtControllerProvider.notifier).createDebt(
          customerId: 'c-4',
          referenceNumber: 'DR-2001',
          principalAmountCents: 75000,
          originDate: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 12, 1),
        );

    final updated = container.read(debtControllerProvider).value!;
    expect(updated.length, 4);
    expect(updated.first.referenceNumber, 'DR-2001');
    expect(updated.first.remainingBalanceCents, 75000);
    expect(updated.first.status, 'active');
  });

  test('Debt.daysPastDue returns 0 for settled debts', () {
    final settled = Debt(
      id: 'd-settled',
      tenantId: 'tenant-1',
      customerId: 'c-1',
      referenceNumber: 'DR-SETTLED',
      principalAmountCents: 100000,
      remainingBalanceCents: 0,
      originDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 1, 15),
      status: 'settled',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 15),
    );
    expect(settled.daysPastDue, 0);
    expect(settled.agingBracket, 'Settled');
    expect(settled.isOverdue, false);
  });

  test('Debt.daysPastDue calculates overdue days for active debts', () {
    final overdue = Debt(
      id: 'd-overdue',
      tenantId: 'tenant-1',
      customerId: 'c-1',
      referenceNumber: 'DR-OVERDUE',
      principalAmountCents: 100000,
      remainingBalanceCents: 100000,
      originDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 1, 1),
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    expect(overdue.daysPastDue, greaterThanOrEqualTo(0));
    expect(overdue.agingBracket, isNotEmpty);
  });

  test('Debt.remainingBalance and principalAmount accessors convert cents correctly', () {
    final debt = Debt(
      id: 'd-1',
      tenantId: 'tenant-1',
      customerId: 'c-1',
      referenceNumber: 'DR-1001',
      principalAmountCents: 150000,
      remainingBalanceCents: 75000,
      originDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 12, 1),
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    expect(debt.principalAmount, 1500.0);
    expect(debt.remainingBalance, 750.0);
  });

  test('Debt.copyWith produces modified copy', () {
    final original = Debt(
      id: 'd-1',
      tenantId: 'tenant-1',
      customerId: 'c-1',
      referenceNumber: 'DR-1001',
      principalAmountCents: 100000,
      remainingBalanceCents: 100000,
      originDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 12, 1),
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final updated = original.copyWith(
      status: 'settled',
      remainingBalanceCents: 0,
    );
    expect(updated.status, 'settled');
    expect(updated.remainingBalanceCents, 0);
    expect(updated.principalAmountCents, 100000);
    expect(updated.id, 'd-1');
  });

  test('filteredDebtsProvider filters by reference number', () async {
    final repo = _MockDebtRepository([...initialDebts]);
    final container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(debtControllerProvider.future);

    expect(container.read(filteredDebtsProvider).length, 3);

    container.read(debtSearchQueryProvider.notifier).setQuery('DR-1002');
    expect(container.read(filteredDebtsProvider).length, 1);
    expect(container.read(filteredDebtsProvider).first.referenceNumber, 'DR-1002');

    container.read(debtSearchQueryProvider.notifier).setQuery('NonExistent');
    expect(container.read(filteredDebtsProvider).length, 0);

    container.read(debtSearchQueryProvider.notifier).setQuery('');
    expect(container.read(filteredDebtsProvider).length, 3);
  });

  test('paginatedDebtsProvider respects page size and page indexing', () async {
    final repo = _MockDebtRepository([...initialDebts]);
    final container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(debtControllerProvider.future);

    container.read(debtPageSizeProvider.notifier).setPageSize(2);
    container.read(debtPageIndexProvider.notifier).setPage(0);

    final page0 = container.read(paginatedDebtsProvider);
    expect(page0.length, 2);
    expect(page0[0].referenceNumber, 'DR-1001');
    expect(page0[1].referenceNumber, 'DR-1002');

    container.read(debtPageIndexProvider.notifier).nextPage();
    final page1 = container.read(paginatedDebtsProvider);
    expect(page1.length, 1);
    expect(page1[0].referenceNumber, 'DR-1003');
  });

  test('filteredDebtsProvider filters by overdue aging filter', () async {
    final repo = _MockDebtRepository([...initialDebts]);
    final container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(debtControllerProvider.future);

    // Default: all debts
    expect(container.read(filteredDebtsProvider).length, 3);

    // Filter by overdue
    container.read(debtAgingFilterProvider.notifier).setFilter('overdue');
    final overdue = container.read(filteredDebtsProvider);
    expect(overdue.every((d) => d.isOverdue), isTrue);
    expect(overdue.length, greaterThanOrEqualTo(1));
    expect(overdue.any((d) => d.referenceNumber == 'DR-1001'), isTrue);

    // Reset
    container.read(debtAgingFilterProvider.notifier).setFilter('all');
    expect(container.read(filteredDebtsProvider).length, 3);
  });

  test('filteredDebtsProvider filters by settled status', () async {
    final repo = _MockDebtRepository([...initialDebts]);
    final container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(debtControllerProvider.future);

    container.read(debtAgingFilterProvider.notifier).setFilter('settled');
    final settled = container.read(filteredDebtsProvider);
    expect(settled.every((d) => d.status == 'settled'), isTrue);
    expect(settled.length, 1);
    expect(settled.first.referenceNumber, 'DR-1003');
  });

  test('filteredDebtsProvider filters by current aging bracket', () async {
    final repo = _MockDebtRepository([...initialDebts]);
    final container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(debtControllerProvider.future);

    container.read(debtAgingFilterProvider.notifier).setFilter('current');
    final current = container.read(filteredDebtsProvider);
    expect(current.every((d) => d.agingBracket == 'Current'), isTrue);
  });

  test('filteredDebtsProvider combines search query and aging filter', () async {
    final repo = _MockDebtRepository([...initialDebts]);
    final container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(debtControllerProvider.future);

    container.read(debtSearchQueryProvider.notifier).setQuery('DR-1001');
    container.read(debtAgingFilterProvider.notifier).setFilter('overdue');
    final result = container.read(filteredDebtsProvider);
    expect(result.length, 1);
    expect(result.first.referenceNumber, 'DR-1001');
    expect(result.first.isOverdue, isTrue);
  });
}