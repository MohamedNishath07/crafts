import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/customer_repository.dart';
import '../domain/customer.dart';

final customerControllerProvider = AsyncNotifierProvider<CustomerController, List<Customer>>(() {
  return CustomerController();
});

class CustomerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}
final customerSearchQueryProvider = NotifierProvider<CustomerSearchQueryNotifier, String>(CustomerSearchQueryNotifier.new);

class CustomerPageSizeNotifier extends Notifier<int> {
  @override
  int build() => 25;
  void setPageSize(int size) => state = size;
}
final customerPageSizeProvider = NotifierProvider<CustomerPageSizeNotifier, int>(CustomerPageSizeNotifier.new);

class CustomerPageIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setPage(int page) => state = page;
  void nextPage() => state++;
  void previousPage() {
    if (state > 0) state--;
  }
}
final customerPageIndexProvider = NotifierProvider<CustomerPageIndexNotifier, int>(CustomerPageIndexNotifier.new);

/// Provider returning all customers matching the current search query
final filteredCustomersProvider = Provider<List<Customer>>((ref) {
  final customersAsync = ref.watch(customerControllerProvider);
  final searchQuery = ref.watch(customerSearchQueryProvider).trim().toLowerCase();

  final customers = customersAsync.value ?? [];
  if (searchQuery.isEmpty) return customers;

  return customers.where((c) {
    final nameMatches = c.fullName.toLowerCase().contains(searchQuery);
    final phoneMatches = c.phoneNumber.toLowerCase().contains(searchQuery);
    final secondaryPhoneMatches = c.secondaryPhone?.toLowerCase().contains(searchQuery) ?? false;
    final emailMatches = c.email?.toLowerCase().contains(searchQuery) ?? false;
    final nationalIdMatches = c.nationalId?.toLowerCase().contains(searchQuery) ?? false;

    return nameMatches || phoneMatches || secondaryPhoneMatches || emailMatches || nationalIdMatches;
  }).toList();
});

/// Provider returning the current paginated slice of filtered customers
final paginatedCustomersProvider = Provider<List<Customer>>((ref) {
  final filtered = ref.watch(filteredCustomersProvider);
  final pageSize = ref.watch(customerPageSizeProvider);
  final pageIndex = ref.watch(customerPageIndexProvider);

  final startIndex = pageIndex * pageSize;
  if (startIndex >= filtered.length) return [];

  final endIndex = (startIndex + pageSize) > filtered.length
      ? filtered.length
      : startIndex + pageSize;

  return filtered.sublist(startIndex, endIndex);
});

class CustomerController extends AsyncNotifier<List<Customer>> {
  late final CustomerRepository _repository;

  @override
  FutureOr<List<Customer>> build() async {
    _repository = ref.watch(customerRepositoryProvider);
    final authProfile = ref.read(authControllerProvider).value;
    final tenantId = authProfile?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';

    try {
      final list = await _repository.fetchCustomers(tenantId).timeout(
        const Duration(seconds: 2),
      );
      return list.isNotEmpty ? list : _repository.generateDefaultCustomers(tenantId);
    } catch (_) {
      return _repository.generateDefaultCustomers(tenantId);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authProfile = ref.read(authControllerProvider).value;
      final tenantId = authProfile?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';
      try {
        final list = await _repository.fetchCustomers(tenantId).timeout(
          const Duration(seconds: 2),
        );
        return list.isNotEmpty ? list : (state.value ?? _repository.generateDefaultCustomers(tenantId));
      } catch (_) {
        return state.value ?? _repository.generateDefaultCustomers(tenantId);
      }
    });
  }

  Future<Customer> createCustomer({
    required String fullName,
    required String phoneNumber,
    String? secondaryPhone,
    String? email,
    String? nationalId,
    String? address,
  }) async {
    final authProfile = ref.read(authControllerProvider).value;
    final tenantId = authProfile?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';
    final currentList = state.value ?? [];

    try {
      final newCustomer = await _repository.createCustomer(
        tenantId: tenantId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        secondaryPhone: secondaryPhone,
        email: email,
        nationalId: nationalId,
        address: address,
      ).timeout(const Duration(seconds: 2));

      state = AsyncValue.data([newCustomer, ...currentList]);
      return newCustomer;
    } catch (_) {
      // Local fallback in offline / test mode
      final localCustomer = Customer(
        id: 'cust-${DateTime.now().millisecondsSinceEpoch}',
        tenantId: tenantId,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        secondaryPhone: secondaryPhone?.trim().isNotEmpty == true ? secondaryPhone!.trim() : null,
        email: email?.trim().isNotEmpty == true ? email!.trim().toLowerCase() : null,
        nationalId: nationalId?.trim().isNotEmpty == true ? nationalId!.trim() : null,
        address: address?.trim().isNotEmpty == true ? address!.trim() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = AsyncValue.data([localCustomer, ...currentList]);
      return localCustomer;
    }
  }
}
