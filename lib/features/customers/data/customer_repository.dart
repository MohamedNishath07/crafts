import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/customer.dart';

import '../../../core/sqlitedatabase.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  try {
    return CustomerRepository(SQLiteDatabase());
  } catch (_) {
    return CustomerRepository(null);
  }
});

class CustomerRepository {
  final SQLiteDatabase? _db;
  static const _uuid = Uuid();

  CustomerRepository(this._db);

  /// Fetch all customers for a given tenant
  Future<List<Customer>> fetchCustomers(String tenantId) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final response = await _db.fetchCustomers(tenantId);
    return response.map((row) => Customer.fromJson(row)).toList();
  }

  /// Create a new customer record
  Future<Customer> createCustomer({
    required String tenantId,
    required String fullName,
    required String phoneNumber,
    String? secondaryPhone,
    String? email,
    String? nationalId,
    String? address,
  }) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final newId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final secondaryPhoneTrimmed = secondaryPhone?.trim();
    final emailTrimmed = email?.trim();
    final nationalIdTrimmed = nationalId?.trim();
    final addressTrimmed = address?.trim();

    final payload = {
      'id': newId,
      'tenant_id': tenantId,
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
      'secondary_phone':
          secondaryPhoneTrimmed?.isNotEmpty == true ? secondaryPhoneTrimmed : null,
      'email': emailTrimmed?.isNotEmpty == true ? emailTrimmed!.toLowerCase() : null,
      'national_id': nationalIdTrimmed?.isNotEmpty == true ? nationalIdTrimmed : null,
      'address': addressTrimmed?.isNotEmpty == true ? addressTrimmed : null,
      'created_at': now,
      'updated_at': now,
    };

    await _db.getRawDatabase().insert('customers', payload);

    final customer = await _db.fetchCustomerById(newId, tenantId);
    return Customer.fromJson(customer!);
  }

  /// Update an existing customer record
  Future<Customer> updateCustomer({
    required String customerId,
    required String tenantId,
    required String fullName,
    required String phoneNumber,
    String? secondaryPhone,
    String? email,
    String? nationalId,
    String? address,
  }) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final now = DateTime.now().toIso8601String();

    final secondaryPhoneTrimmed = secondaryPhone?.trim();
    final emailTrimmed = email?.trim();
    final nationalIdTrimmed = nationalId?.trim();
    final addressTrimmed = address?.trim();

    final payload = {
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
      'secondary_phone':
          secondaryPhoneTrimmed?.isNotEmpty == true ? secondaryPhoneTrimmed : null,
      'email': emailTrimmed?.isNotEmpty == true ? emailTrimmed!.toLowerCase() : null,
      'national_id': nationalIdTrimmed?.isNotEmpty == true ? nationalIdTrimmed : null,
      'address': addressTrimmed?.isNotEmpty == true ? addressTrimmed : null,
      'updated_at': now,
    };

    await _db.getRawDatabase().update(
      'customers',
      payload,
      where: 'id = ?',
      whereArgs: [customerId],
    );

    // Fetch the updated customer record
    final customer = await _db.fetchCustomerById(customerId, tenantId);
    return Customer.fromJson(customer!);
  }

  /// Default customer records used in offline development or test environments
  List<Customer> generateDefaultCustomers(String tenantId) {
    final now = DateTime.now();
    return [
      Customer(
        id: '20000000-0000-0000-0000-000000000001',
        tenantId: tenantId,
        fullName: 'Marcus Vance',
        phoneNumber: '+1-555-0101',
        secondaryPhone: '+1-555-0102',
        email: 'marcus.vance@example.com',
        nationalId: 'NAT-99881',
        address: '742 Evergreen Terrace, Springfield',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 90)),
      ),
      Customer(
        id: '20000000-0000-0000-0000-000000000002',
        tenantId: tenantId,
        fullName: 'Sarah Jenkins',
        phoneNumber: '+1-555-0202',
        secondaryPhone: null,
        email: 'sarah.j@example.org',
        nationalId: 'NAT-88772',
        address: '1048 Elm Street, Dallas, TX',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 60)),
      ),
      Customer(
        id: '20000000-0000-0000-0000-000000000003',
        tenantId: tenantId,
        fullName: 'Robert Chen',
        phoneNumber: '+1-555-0303',
        secondaryPhone: '+1-555-0304',
        email: 'r.chen@company.net',
        nationalId: 'NAT-77663',
        address: '42 Wallaby Way, Sydney',
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 45)),
      ),
      Customer(
        id: '20000000-0000-0000-0000-000000000004',
        tenantId: tenantId,
        fullName: 'Elena Rostova',
        phoneNumber: '+1-555-0404',
        secondaryPhone: null,
        email: 'elena.rostova@example.com',
        nationalId: 'NAT-66554',
        address: '12 Grimmauld Place, London',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      Customer(
        id: '20000000-0000-0000-0000-000000000005',
        tenantId: tenantId,
        fullName: 'James Wilson',
        phoneNumber: '+1-555-0505',
        secondaryPhone: '+1-555-0506',
        email: 'j.wilson@corp.org',
        nationalId: 'NAT-55443',
        address: '221B Baker Street, London',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
    ];
  }
}

