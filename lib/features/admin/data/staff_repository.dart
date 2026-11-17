import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/domain/user_profile.dart';

import '../../../core/sqlitedatabase.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  try {
    return StaffRepository(SQLiteDatabase());
  } catch (_) {
    return StaffRepository(null);
  }
});

class StaffRepository {
  final SQLiteDatabase? _db;
  static const _uuid = Uuid();

  StaffRepository(this._db);

  /// Fetch all staff members belonging to the tenant
  Future<List<UserProfile>> fetchStaffMembers(String tenantId) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final response = await _db.fetchProfiles(tenantId);
    return response.map((row) => UserProfile.fromJson(row)).toList();
  }

  /// Create a new staff profile within the organization
  Future<UserProfile> createStaffMember({
    required String tenantId,
    required String email,
    required String fullName,
    required UserRole role,
  }) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final newId = _uuid.v4();

    final payload = {
      'id': newId,
      'tenant_id': tenantId,
      'email': email.trim().toLowerCase(),
      'full_name': fullName.trim(),
      'role': role.toDbValue(),
      'is_active': 1,
    };

    await _db.insert('profiles', payload);

    final profile = await _db.fetchProfiles(tenantId);
    return UserProfile.fromJson(profile.firstWhere((p) => p['id'] == newId));
  }

  /// Update staff active status (activate / deactivate)
  Future<UserProfile> updateStaffStatus({
    required String tenantId,
    required String userId,
    required bool isActive,
  }) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final now = DateTime.now().toIso8601String();

    await _db.updateProfile({
      'id': userId,
      'is_active': isActive ? 1 : 0,
      'updated_at': now,
    });

    final profiles = await _db.fetchProfiles(tenantId);
    return UserProfile.fromJson(profiles.firstWhere((p) => p['id'] == userId));
  }

  /// Update staff role allocation
  Future<UserProfile> updateStaffRole({
    required String tenantId,
    required String userId,
    required UserRole role,
  }) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final now = DateTime.now().toIso8601String();

    await _db.updateProfile({
      'id': userId,
      'role': role.toDbValue(),
      'updated_at': now,
    });

    final profiles = await _db.fetchProfiles(tenantId);
    return UserProfile.fromJson(profiles.firstWhere((p) => p['id'] == userId));
  }
}
