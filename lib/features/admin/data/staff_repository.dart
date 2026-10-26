import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../auth/domain/user_profile.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  try {
    return StaffRepository(Supabase.instance.client);
  } catch (_) {
    return StaffRepository(null);
  }
});

class StaffRepository {
  final SupabaseClient? _client;
  static const _uuid = Uuid();

  StaffRepository(this._client);

  /// Fetch all staff members belonging to the tenant
  Future<List<UserProfile>> fetchStaffMembers(String tenantId) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('profiles')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => UserProfile.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Create a new staff profile within the organization
  Future<UserProfile> createStaffMember({
    required String tenantId,
    required String email,
    required String fullName,
    required UserRole role,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final newId = _uuid.v4();

    final payload = {
      'id': newId,
      'tenant_id': tenantId,
      'email': email.trim().toLowerCase(),
      'full_name': fullName.trim(),
      'role': role.toDbValue(),
      'is_active': true,
    };

    final response = await client
        .from('profiles')
        .insert(payload)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  /// Update staff active status (activate / deactivate)
  Future<UserProfile> updateStaffStatus({
    required String userId,
    required bool isActive,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('profiles')
        .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  /// Update staff role allocation
  Future<UserProfile> updateStaffRole({
    required String userId,
    required UserRole role,
  }) async {
    final client = _client;
    if (client == null) {
      throw const PostgrestException(message: 'Supabase client not initialized');
    }

    final response = await client
        .from('profiles')
        .update({'role': role.toDbValue(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }
}
