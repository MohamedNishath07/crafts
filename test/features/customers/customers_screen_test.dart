import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/customers/data/customer_repository.dart';
import 'package:crafts/features/customers/domain/customer.dart';
import 'package:crafts/features/customers/presentation/customers_screen.dart';

class _MockCustomerRepo extends CustomerRepository {
  final List<Customer> _list;

  _MockCustomerRepo(this._list) : super(null);

  @override
  Future<List<Customer>> fetchCustomers(String tenantId) async {
    return List<Customer>.from(_list);
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
    return Customer(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
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
  }
}

void main() {
  final mockCustomers = [
    Customer(
      id: 'c-1',
      tenantId: 'tenant-1',
      fullName: 'Marcus Vance',
      phoneNumber: '+1-555-0101',
      email: 'marcus@example.com',
      nationalId: 'NAT-100',
      address: '742 Evergreen Terrace',
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
      address: '1048 Elm Street',
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    ),
  ];

  testWidgets('CustomersScreen renders directory headers, search toolbar, and data rows', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _MockCustomerRepo([...mockCustomers]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: CustomersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer Directory'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Add Customer'), findsOneWidget);
    expect(find.text('Customer Name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Marcus Vance'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Showing 1-2 of 2 records'), findsOneWidget);
  });

  testWidgets('CustomersScreen filters customers in real time via search', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _MockCustomerRepo([...mockCustomers]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: CustomersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Jenkins');
    await tester.pumpAndSettle();

    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Marcus Vance'), findsNothing);
    expect(find.text('Showing 1-1 of 1 records'), findsOneWidget);
  });

  testWidgets('AddCustomerDialog validates inputs and registers new customer', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _MockCustomerRepo([...mockCustomers]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: CustomersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Add Customer button
    final addBtn = find.widgetWithText(ElevatedButton, 'Add Customer');
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    expect(find.text('Register New Customer'), findsOneWidget);

    // Try submitting empty form
    final submitBtn = find.widgetWithText(ElevatedButton, 'Register Customer');
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Please enter customer full name'), findsOneWidget);
    expect(find.text('Please enter primary phone number'), findsOneWidget);

    // Enter valid details
    final nameField = find.widgetWithText(TextFormField, 'Full Name *');
    final phoneField = find.widgetWithText(TextFormField, 'Primary Phone Number *');
    final emailField = find.widgetWithText(TextFormField, 'Email Address (Optional)');

    await tester.enterText(nameField, 'Diana Prince');
    await tester.enterText(phoneField, '+1-555-8888');
    await tester.enterText(emailField, 'diana@themyscira.gov');
    await tester.pumpAndSettle();

    // Submit valid customer
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Dialog dismissed and customer appears in the table
    expect(find.text('Register New Customer'), findsNothing);
    expect(find.text('Customer "Diana Prince" registered successfully'), findsOneWidget);
    expect(find.text('Diana Prince'), findsOneWidget);
  });
}
