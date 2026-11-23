import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:credit_recovery_system/core/router/app_router.dart';
import 'package:credit_recovery_system/core/auth/user_model.dart';
import 'package:credit_recovery_system/features/admin/data/staff_repository.dart';
import 'package:credit_recovery_system/features/auth/domain/user_profile.dart';
import 'package:credit_recovery_system/features/auth/presentation/auth_controller.dart';
import 'package:credit_recovery_system/features/auth/data/auth_repository_backup.dart';

import '../../test_helpers/mock_staff_repository.dart';

class _MockAuthController extends AuthController {
  final UserProfile? _mockProfile;
  _MockAuthController(this._mockProfile);

  @override
  FutureOr<UserProfile?> build() {
    return _mockProfile;
  }
}

class _LoadingAuthController extends AuthController {
  final Completer<UserProfile?> completer = Completer<UserProfile?>();

  @override
  FutureOr<UserProfile?> build() => completer.future;
}

class _ReturningSessionRepository extends AuthRepository {
  bool hasActiveSession = true;

  @override
  Future<void> signOut() async {
    hasActiveSession = false;
  }

  @override
  Future<User> getCurrentProfile() async => User(
    id: 'returning-user',
    email: 'staff@acme.com',
    isActive: hasActiveSession,
  );
}

void main() {
  testWidgets('Pending authentication redirects protected deep links to logo', (
    tester,
  ) async {
    final authController = _LoadingAuthController();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => authController),
        staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/dashboard');
    await tester.pump();
    await tester.pump();
    expect(router.state.matchedLocation, '/');
  });

  testWidgets(
    'Launch starts on logo and continues to login after initialization',
    (tester) async {
      final authController = _LoadingAuthController();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => authController),
          staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      expect(router.state.matchedLocation, '/');
      authController.completer.complete(null);
      await tester.pump();
      await tester.pump();
      expect(router.state.matchedLocation, '/login');
    },
  );

  testWidgets('Returning launch requires a fresh sign-in', (tester) async {
    final repository = _ReturningSessionRepository();
    final authController = AuthController(repository: repository);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => authController),
        staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    expect(repository.hasActiveSession, isFalse);
    expect(router.state.matchedLocation, '/login');
  });

  testWidgets('Unauthenticated user is redirected to /login', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _MockAuthController(null)),
        staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, '/login');
  });

  testWidgets(
    'Recovery officer navigating to /admin/users is redirected to /dashboard',
    (tester) async {
      const recoveryUser = UserProfile(
        id: 'rec-1',
        tenantId: 't-1',
        email: 'rec@acme.com',
        fullName: 'Recovery Officer',
        role: UserRole.recoveryOfficer,
      );

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _MockAuthController(recoveryUser),
          ),
          staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Now try to navigate to /admin/users
      router.go('/admin/users');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should be redirected back to /dashboard
      expect(router.state.matchedLocation, '/dashboard');
    },
  );

  testWidgets('Administrator is allowed to access /admin/users', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const adminUser = UserProfile(
      id: 'admin-1',
      tenantId: 't-1',
      email: 'admin@acme.com',
      fullName: 'Admin User',
      role: UserRole.admin,
    );

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _MockAuthController(adminUser),
        ),
        staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to /admin/users
    router.go('/admin/users');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    // Should stay at /admin/users
    expect(router.state.matchedLocation, '/admin/users');
  });
}
