import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository_backup.dart';
import '../domain/user_profile.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserProfile?>(() {
      return AuthController();
    });

class AuthController extends AsyncNotifier<UserProfile?> {
  final AuthRepository _repository = AuthRepository();

  @override
  FutureOr<UserProfile?> build() async {
    // Every app launch requires fresh credential submission, even if this
    // repository still contains a user from the previous running process.
    await _repository.signOut();
    return null;
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signIn(
        email: email,
        password: password,
        tenantId: 'default_tenant',
      );
      final user = await _repository.getCurrentProfile();
      if (!user.isActive) return null;
      return UserProfile(
        id: user.id,
        email: user.email,
        fullName: user.name ?? 'Staff Member',
        role: UserRole.recoveryOfficer,
        isActive: user.isActive,
        tenantId: user.tenantId ?? 'default_tenant',
      );
    });
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
  Future<void> updateProfile({required String fullName, String? phone}) async {
    final current = state.value;
    if (current == null) return;

    try {
      await _repository.updateProfile(fullName: fullName, phone: phone);
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

  /// Change the current user's password after validating the current password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Returns the stored phone number for the current user, if any.
  Future<String?> getCurrentPhone() async => _repository.getCurrentPhone();

  /// Returns the stored profile photo path for the current user, if any.
  Future<String?> getCurrentProfilePhoto() async =>
      _repository.getCurrentProfilePhoto();

  /// Updates the current user's profile photo path.
  Future<void> updateProfilePhoto({required String photoPath}) async =>
      _repository.updateProfilePhoto(photoPath: photoPath);

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
      return UserProfile(
        id: user.id,
        email: user.email,
        fullName: user.name ?? 'Staff Member',
        role: UserRole.recoveryOfficer,
        isActive: user.isActive,
        tenantId: 'default_tenant',
      );
    });
  }
}
