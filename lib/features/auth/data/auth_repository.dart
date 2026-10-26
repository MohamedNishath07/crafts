import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  try {
    return AuthRepository(Supabase.instance.client);
  } catch (_) {
    return AuthRepository(null);
  }
});

class AuthRepository {
  final SupabaseClient? _client;

  AuthRepository(this._client);

  Session? get currentSession => _client?.auth.currentSession;
  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client?.auth.onAuthStateChange ?? const Stream.empty();

  /// Sign in with email and password, then fetch the user's role profile
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client not initialized');
    }
    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Authentication failed: user not found');
    }

    // Fetch user profile from public.profiles table
    final profileData = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profileData != null) {
      return UserProfile.fromJson(profileData);
    }

    // Fallback: derive role from app_metadata if profile row is not yet propagated
    final tenantId = user.appMetadata['tenant_id'] as String? ?? 'default_tenant';
    final roleString = user.appMetadata['role'] as String? ?? 'recovery_officer';
    final fullName = user.userMetadata?['full_name'] as String? ?? email.split('@').first;

    return UserProfile(
      id: user.id,
      tenantId: tenantId,
      email: user.email ?? email,
      fullName: fullName,
      role: UserRole.fromString(roleString),
    );
  }

  /// Sign out current session
  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentProfile() async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return null;

    final profileData = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profileData != null) {
      return UserProfile.fromJson(profileData);
    }

    return UserProfile(
      id: user.id,
      tenantId: user.appMetadata['tenant_id'] as String? ?? 'default_tenant',
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'] as String? ?? 'Staff Member',
      role: UserRole.fromString(user.appMetadata['role'] as String? ?? 'recovery_officer'),
    );
  }

  /// Update user profile details (full name)
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client not initialized');
    }

    final response = await client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  /// Change password for the current authenticated user
  Future<void> updatePassword({
    required String newPassword,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client not initialized');
    }

    await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}

