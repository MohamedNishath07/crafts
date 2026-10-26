import 'package:crafts/features/auth/domain/user_profile.dart';
import 'package:crafts/features/admin/data/staff_repository.dart';

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
