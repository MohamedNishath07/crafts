import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/customers/data/customer_repository.dart';
import 'package:crafts/features/customers/domain/customer.dart';
import 'package:crafts/features/customers/presentation/customer_controller.dart';

class _MockCustomerRepository extends CustomerRepository {
  final List<Customer> _customers;

  _MockCustomerRepository(this._customers) : super(null);

  @override
  Future<List<Customer>> fetchCustomers(String tenantId) async {
    return List<Customer>.from(_customers);
  }

  @override
  Future<Customer> createCustomer({
    required String tenantId,
    required String fullName,
    required String phoneNumber,
    String? secondaryPhone,
    String? email,
    String? nationalId,
    String? address,
  }) async {
    final newCust = Customer(
      id: 'cust-${_customers.length + 1}',
      tenantId: tenantId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      secondaryPhone: secondaryPhone,
      email: email,
      nationalId: nationalId,
      address: address,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _customers.add(newCust);
    return newCust;
  }
}

void main() {
  final initialCustomers = [
    Customer(
      id: 'c-1',
      tenantId: 'tenant-1',
      fullName: 'Marcus Vance',
      phoneNumber: '+1-555-0101',
      email: 'marcus@example.com',
      nationalId: 'NAT-100',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    Customer(
      id: 'c-2',
      tenantId: 'tenant-1',
      fullName: 'Sarah Jenkins',
      phoneNumber: '+1-555-0202',
      email: 'sarah@example.com',
      nationalId: 'NAT-200',
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    ),
    Customer(
      id: 'c-3',
      tenantId: 'tenant-1',
      fullName: 'Robert Chen',
      phoneNumber: '+1-555-0303',
      email: 'robert@example.com',
      nationalId: 'NAT-300',
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    ),
  ];

  test('CustomerController loads initial customers roster', () async {
    final repo = _MockCustomerRepository([...initialCustomers]);
    final container = ProviderContainer(
      overrides: [
        customerRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final customers = await container.read(customerControllerProvider.future);
    expect(customers.length, 3);
    expect(customers.first.fullName, 'Marcus Vance');
  });

  test('CustomerController creates new customer and prepends to state', () async {
    final repo = _MockCustomerRepository([...initialCustomers]);
    final container = ProviderContainer(
      overrides: [
        customerRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(customerControllerProvider.future);

    await container.read(customerControllerProvider.notifier).createCustomer(
          fullName: 'Alice Wonder',
          phoneNumber: '+1-555-9999',
          email: 'alice@example.com',
        );

    final updated = container.read(customerControllerProvider).value!;
    expect(updated.length, 4);
    expect(updated.first.fullName, 'Alice Wonder');
  });

  test('filteredCustomersProvider filters by name, phone, or nationalId', () async {
    final repo = _MockCustomerRepository([...initialCustomers]);
    final container = ProviderContainer(
      overrides: [
        customerRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(customerControllerProvider.future);

    // Initial state: 3 customers
    expect(container.read(filteredCustomersProvider).length, 3);

    // Search by name
    container.read(customerSearchQueryProvider.notifier).setQuery('Jenkins');
    expect(container.read(filteredCustomersProvider).length, 1);
    expect(container.read(filteredCustomersProvider).first.fullName, 'Sarah Jenkins');

    // Search by phone
    container.read(customerSearchQueryProvider.notifier).setQuery('0303');
    expect(container.read(filteredCustomersProvider).length, 1);
    expect(container.read(filteredCustomersProvider).first.fullName, 'Robert Chen');

    // Search with no match
    container.read(customerSearchQueryProvider.notifier).setQuery('NonExistent');
    expect(container.read(filteredCustomersProvider).length, 0);

    // Reset query
    container.read(customerSearchQueryProvider.notifier).setQuery('');
    expect(container.read(filteredCustomersProvider).length, 3);
  });

  test('paginatedCustomersProvider respects page size and page indexing', () async {
    final repo = _MockCustomerRepository([...initialCustomers]);
    final container = ProviderContainer(
      overrides: [
        customerRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(customerControllerProvider.future);

    // Set page size to 2
    container.read(customerPageSizeProvider.notifier).setPageSize(2);
    container.read(customerPageIndexProvider.notifier).setPage(0);

    final page0 = container.read(paginatedCustomersProvider);
    expect(page0.length, 2);
    expect(page0[0].fullName, 'Marcus Vance');
    expect(page0[1].fullName, 'Sarah Jenkins');

    // Advance to page 1
    container.read(customerPageIndexProvider.notifier).nextPage();
    final page1 = container.read(paginatedCustomersProvider);
    expect(page1.length, 1);
    expect(page1[0].fullName, 'Robert Chen');
  });
}
