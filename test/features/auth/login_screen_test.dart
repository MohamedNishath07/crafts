import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:credit_recovery_system/features/auth/presentation/login_screen.dart';
import 'package:credit_recovery_system/features/auth/presentation/auth_controller.dart';
import 'package:credit_recovery_system/features/auth/data/auth_repository_backup.dart';
import 'package:credit_recovery_system/core/auth/user_model.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository extends AuthRepository {
  final String signInResult;
  final bool activeProfile;
  bool signedOut = false;

  _FakeAuthRepository({required this.signInResult, this.activeProfile = true});

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
    required String tenantId,
  }) async {
    if (signInResult == 'invalid') {
      throw Exception('Authentication failed: invalid password');
    }
  }

  @override
  Future<User> getCurrentProfile() async {
    return User(
      id: 'user-1',
      email: 'staff@acme.com',
      name: 'Staff Member',
      tenantId: 'default_tenant',
      isActive: activeProfile,
    );
  }
}

Finder _signInButton() => find.ancestor(
  of: find.text('Sign In'),
  matching: find.byType(ElevatedButton),
);

void main() {
  testWidgets('LoginScreen shows validation errors on empty submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_email_field')), '');
    await tester.enterText(find.byKey(const Key('login_password_field')), '');
    await tester.pumpAndSettle();

    final signInButton = _signInButton();
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('LoginScreen validates invalid email format', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'not-an-email',
    );
    await tester.pumpAndSettle();

    final signInButton = _signInButton();
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('Successful sign-in navigates to dashboard', (tester) async {
    final repository = _FakeAuthRepository(signInResult: 'success');
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => AuthController(repository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'staff@acme.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'password',
    );
    await tester.tap(_signInButton());
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/dashboard');
  });

  testWidgets('Failed sign-in stays on login with error feedback', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(signInResult: 'invalid');
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => AuthController(repository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'staff@acme.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'wrong-password',
    );
    await tester.tap(_signInButton());
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/login');
    expect(find.textContaining('Login failed:'), findsOneWidget);
  });

  testWidgets('Inactive-profile sign-in stays on login with error feedback', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(
      signInResult: 'success',
      activeProfile: false,
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => AuthController(repository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'staff@acme.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'password',
    );
    await tester.tap(_signInButton());
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/login');
    expect(find.textContaining('Login failed:'), findsOneWidget);
  });
}
