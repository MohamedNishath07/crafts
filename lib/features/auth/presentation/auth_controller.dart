import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, UserProfile?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<UserProfile?> {
  late final AuthRepository _repository;

  @override
  FutureOr<UserProfile?> build() async {
    _repository = ref.watch(authRepositoryProvider);
    return _repository.getCurrentProfile();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.signIn(email: email, password: password);
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
}
