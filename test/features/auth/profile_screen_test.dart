import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/auth/domain/user_profile.dart';
import 'package:crafts/features/auth/presentation/auth_controller.dart';
import 'package:crafts/features/auth/presentation/profile_screen.dart';

class _MockProfileAuthController extends AuthController {
  UserProfile? _profile;
  String? updatedName;
  String? changedPassword;

  _MockProfileAuthController(this._profile);

  @override
  FutureOr<UserProfile?> build() {
    return _profile;
  }

  @override
  Future<void> updateProfile({required String fullName}) async {
    updatedName = fullName;
    if (_profile != null) {
      _profile = UserProfile(
        id: _profile!.id,
        tenantId: _profile!.tenantId,
        email: _profile!.email,
        fullName: fullName,
        role: _profile!.role,
        isActive: _profile!.isActive,
      );
      state = AsyncValue.data(_profile);
    }
  }

  @override
  Future<void> changePassword({required String newPassword}) async {
    changedPassword = newPassword;
  }
}

void main() {
  const testUser = UserProfile(
    id: 'user-123',
    tenantId: 'tenant-abc',
    email: 'sarah.officer@acme.com',
    fullName: 'Sarah Officer',
    role: UserRole.recoveryOfficer,
  );

  testWidgets('ProfileScreen renders current profile and role badge', (tester) async {
    final mockController = _MockProfileAuthController(testUser);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => mockController),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile & Security Settings'), findsOneWidget);
    expect(find.text('Profile Information'), findsOneWidget);
    expect(find.text('Security & Password'), findsOneWidget);
    expect(find.text('sarah.officer@acme.com'), findsOneWidget);
    expect(find.text('Recovery Officer'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Sarah Officer'), findsOneWidget);
  });

  testWidgets('ProfileScreen validates empty full name', (tester) async {
    final mockController = _MockProfileAuthController(testUser);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => mockController),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nameField = find.widgetWithText(TextFormField, 'Sarah Officer');
    await tester.enterText(nameField, '   ');
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(mockController.updatedName, isNull);
  });

  testWidgets('ProfileScreen submits valid full name update', (tester) async {
    final mockController = _MockProfileAuthController(testUser);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => mockController),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nameField = find.widgetWithText(TextFormField, 'Sarah Officer');
    await tester.enterText(nameField, 'Sarah Connor');
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(mockController.updatedName, 'Sarah Connor');
    expect(find.text('Profile details updated successfully'), findsOneWidget);
  });

  testWidgets('Password form validates empty, length, and mismatch constraints', (tester) async {
    final mockController = _MockProfileAuthController(testUser);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => mockController),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final changePasswordBtn = find.widgetWithText(ElevatedButton, 'Change Password');
    await tester.ensureVisible(changePasswordBtn);
    await tester.tap(changePasswordBtn);
    await tester.pumpAndSettle();

    expect(find.text('Please enter a new password'), findsOneWidget);

    // Test short password
    final newPasswordField = find.widgetWithText(TextFormField, 'New Password');
    await tester.enterText(newPasswordField, 'abc');
    await tester.ensureVisible(changePasswordBtn);
    await tester.tap(changePasswordBtn);
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 8 characters long'), findsOneWidget);

    // Test mismatched passwords
    await tester.enterText(newPasswordField, 'Pass1234');
    final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirm New Password');
    await tester.enterText(confirmPasswordField, 'DifferentPass1234');
    await tester.ensureVisible(changePasswordBtn);
    await tester.tap(changePasswordBtn);
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);

    // Test valid matching passwords
    await tester.enterText(confirmPasswordField, 'Pass1234');
    await tester.ensureVisible(changePasswordBtn);
    await tester.tap(changePasswordBtn);
    await tester.pumpAndSettle();

    expect(mockController.changedPassword, 'Pass1234');
    expect(find.text('Password changed successfully'), findsOneWidget);
  });
}
