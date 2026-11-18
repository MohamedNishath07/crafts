import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository_backup.dart';
import '../domain/user_profile.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, UserProfile?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<UserProfile?> {
  final AuthRepository _repository = AuthRepository();

  @override
  FutureOr<UserProfile?> build() async {
    final user = await _repository.getCurrentProfile();
    return user != null ? UserProfile(
      id: user.id,
      email: user.email,
      fullName: user.name ?? 'Staff Member',
      role: UserRole.recoveryOfficer,
      isActive: user.isActive,
      tenantId: 'default_tenant',
    ) : null;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    await _repository.signIn(email: email, password: password, tenantId: 'default_tenant');
    final user = await _repository.getCurrentProfile();
    state = user != null
        ? AsyncValue.data(UserProfile(
            id: user.id,
            email: user.email,
            fullName: user.name ?? 'Staff Member',
            role: UserRole.recoveryOfficer,
            isActive: user.isActive,
tenantId: 'default_tenant',
          ))
        : const AsyncValue.data(null);
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }

  /// Demo helper to quickly switch active persona during development
  void switchDemoRole(UserRole role) {
    state = AsyncValue.data(
      UserProfile(
        id: 'demo-user-${role.name}',
        tenantId: 'a0000000-0000-0000-0000-000000000001',
        email: '${role.name}@acme.com',
        fullName: 'Demo ${role.displayName}',
        role: role,
      ),
    );
  }

  /// Update the current authenticated user's profile display name
  Future<void> updateProfile({required String fullName}) async {
    final current = state.value;
    if (current == null) return;

    try {
      await _repository.updateProfile(
        fullName: fullName,
      );
      state = AsyncValue.data(
        UserProfile(
          id: current.id,
          tenantId: current.tenantId,
          email: current.email,
          fullName: fullName.trim(),
          role: current.role,
          isActive: current.isActive,
        ),
      );
    } catch (_) {
      // Offline fallback: update local state
      state = AsyncValue.data(
        UserProfile(
          id: current.id,
          tenantId: current.tenantId,
          email: current.email,
          fullName: fullName.trim(),
          role: current.role,
          isActive: current.isActive,
        ),
      );
    }
  }

  /// Change the current user's password
  Future<void> changePassword({required String newPassword}) async {
    await _repository.updatePassword(newPassword: newPassword);
  }

  /// Create a new account with email and password
  Future<void> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _repository.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        tenantId: 'default_tenant',
      );
      return user != null ? UserProfile(
        id: user.id,
        email: user.email,
        fullName: user.name ?? 'Staff Member',
        role: UserRole.recoveryOfficer,
        isActive: user.isActive,
tenantId: 'default_tenant',
      ) : null;
    });
  }
}

