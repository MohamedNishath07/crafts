import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/auth/domain/user_profile.dart';
import 'package:crafts/features/admin/data/staff_repository.dart';
import 'package:crafts/features/admin/presentation/staff_controller.dart';

class MockStaffRepository extends StaffRepository {
  final List<UserProfile> _store;

  MockStaffRepository([List<UserProfile>? initial])
      : _store = initial ??
            [
              const UserProfile(
                id: '1',
                tenantId: 'tenant-1',
                email: 'admin@acme.com',
                fullName: 'Admin User',
                role: UserRole.admin,
                isActive: true,
              ),
              const UserProfile(
                id: '2',
                tenantId: 'tenant-1',
                email: 'officer@acme.com',
                fullName: 'Recovery Officer Bob',
                role: UserRole.recoveryOfficer,
                isActive: true,
              ),
              const UserProfile(
                id: '3',
                tenantId: 'tenant-1',
                email: 'finance@acme.com',
                fullName: 'Finance Specialist Carol',
                role: UserRole.financeOfficer,
                isActive: true,
              ),
            ],
        super(null);

  @override
  Future<List<UserProfile>> fetchStaffMembers(String tenantId) async {
    return List.from(_store);
  }

  @override
  Future<UserProfile> createStaffMember({
    required String tenantId,
    required String email,
    required String fullName,
    required UserRole role,
  }) async {
    final member = UserProfile(
      id: 'mock-${_store.length + 1}',
      tenantId: tenantId,
      email: email,
      fullName: fullName,
      role: role,
      isActive: true,
    );
    _store.insert(0, member);
    return member;
  }

  @override
  Future<UserProfile> updateStaffStatus({
    required String userId,
    required bool isActive,
  }) async {
    final index = _store.indexWhere((s) => s.id == userId);
    final current = _store[index];
    final updated = UserProfile(
      id: current.id,
      tenantId: current.tenantId,
      email: current.email,
      fullName: current.fullName,
      role: current.role,
      isActive: isActive,
    );
    _store[index] = updated;
    return updated;
  }

  @override
  Future<UserProfile> updateStaffRole({
    required String userId,
    required UserRole role,
  }) async {
    final index = _store.indexWhere((s) => s.id == userId);
    final current = _store[index];
    final updated = UserProfile(
      id: current.id,
      tenantId: current.tenantId,
      email: current.email,
      fullName: current.fullName,
      role: role,
      isActive: current.isActive,
    );
    _store[index] = updated;
    return updated;
  }
}

ProviderContainer createTestContainer() {
  return ProviderContainer(
    overrides: [
      staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
    ],
  );
}

void main() {
  group('StaffController & Filter Providers', () {
    test('loads default staff roster when initialized', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      final staffList = await container.read(staffControllerProvider.future);

      expect(staffList.isNotEmpty, isTrue);
      expect(staffList.any((s) => s.role == UserRole.admin), isTrue);
      expect(staffList.any((s) => s.role == UserRole.recoveryOfficer), isTrue);
      expect(staffList.any((s) => s.role == UserRole.financeOfficer), isTrue);
    });

    test('creates new staff member and updates state', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      await container.read(staffControllerProvider.future);

      await container.read(staffControllerProvider.notifier).createStaffMember(
            email: 'newuser@acme.com',
            fullName: 'New Staff User',
            role: UserRole.recoveryOfficer,
          );

      final updatedList = container.read(staffControllerProvider).value!;
      final newMember = updatedList.firstWhere((s) => s.email == 'newuser@acme.com');

      expect(newMember.fullName, 'New Staff User');
      expect(newMember.role, UserRole.recoveryOfficer);
      expect(newMember.isActive, isTrue);
    });

    test('toggles staff active status', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      final initialList = await container.read(staffControllerProvider.future);
      final target = initialList.first;
      final originalStatus = target.isActive;

      await container.read(staffControllerProvider.notifier).toggleStaffStatus(
            userId: target.id,
            currentStatus: originalStatus,
          );

      final updatedList = container.read(staffControllerProvider).value!;
      final updatedTarget = updatedList.firstWhere((s) => s.id == target.id);

      expect(updatedTarget.isActive, !originalStatus);
    });

    test('changes staff role', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      final initialList = await container.read(staffControllerProvider.future);
      final target = initialList.firstWhere((s) => s.role != UserRole.financeOfficer);

      await container.read(staffControllerProvider.notifier).changeStaffRole(
            userId: target.id,
            newRole: UserRole.financeOfficer,
          );

      final updatedList = container.read(staffControllerProvider).value!;
      final updatedTarget = updatedList.firstWhere((s) => s.id == target.id);

      expect(updatedTarget.role, UserRole.financeOfficer);
    });

    test('filteredStaffListProvider filters by role', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      await container.read(staffControllerProvider.future);

      // Filter by recoveryOfficer
      container.read(staffRoleFilterProvider.notifier).setRole(UserRole.recoveryOfficer);

      final filtered = container.read(filteredStaffListProvider);
      expect(filtered.every((s) => s.role == UserRole.recoveryOfficer), isTrue);
    });

    test('filteredStaffListProvider filters by search query', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      await container.read(staffControllerProvider.future);

      container.read(staffSearchQueryProvider.notifier).setQuery('Bob');

      final filtered = container.read(filteredStaffListProvider);
      expect(filtered.every((s) => s.fullName.contains('Bob') || s.email.contains('Bob')), isTrue);
    });
  });
}
