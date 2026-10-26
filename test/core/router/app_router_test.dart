import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/core/router/app_router.dart';
import 'package:crafts/features/admin/data/staff_repository.dart';
import 'package:crafts/features/auth/domain/user_profile.dart';
import 'package:crafts/features/auth/presentation/auth_controller.dart';
import '../../test_helpers/mock_staff_repository.dart';

class _MockAuthController extends AuthController {
  final UserProfile? _mockProfile;
  _MockAuthController(this._mockProfile);

  @override
  FutureOr<UserProfile?> build() {
    return _mockProfile;
  }
}

void main() {
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
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Since initialLocation is /dashboard, unauthenticated should redirect to /login
    expect(router.state.matchedLocation, '/login');
  });

  testWidgets('Recovery officer navigating to /admin/users is redirected to /dashboard', (tester) async {
    const recoveryUser = UserProfile(
      id: 'rec-1',
      tenantId: 't-1',
      email: 'rec@acme.com',
      fullName: 'Recovery Officer',
      role: UserRole.recoveryOfficer,
    );

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _MockAuthController(recoveryUser)),
        staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Now try to navigate to /admin/users
    router.go('/admin/users');
    await tester.pumpAndSettle();

    // Should be redirected back to /dashboard
    expect(router.state.matchedLocation, '/dashboard');
  });

  testWidgets('Administrator is allowed to access /admin/users', (tester) async {
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
        authControllerProvider.overrideWith(() => _MockAuthController(adminUser)),
        staffRepositoryProvider.overrideWithValue(MockStaffRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to /admin/users
    router.go('/admin/users');
    await tester.pumpAndSettle();

    // Should stay at /admin/users
    expect(router.state.matchedLocation, '/admin/users');
  });
}
