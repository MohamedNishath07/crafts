import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:credit_recovery_system/features/auth/domain/user_profile.dart';
import 'package:credit_recovery_system/features/auth/presentation/auth_controller.dart';
import 'package:credit_recovery_system/features/auth/presentation/profile_screen.dart';

class _MockProfileAuthController extends AuthController {
  UserProfile? _profile;
  String? updatedName;
  String? updatedPhone;
  String? changedPasswordCurrent;
  String? changedPasswordNew;

  _MockProfileAuthController(this._profile);

  @override
  FutureOr<UserProfile?> build() => _profile;

  @override
  Future<void> updateProfile({required String fullName, String? phone}) async {
    updatedName = fullName;
    updatedPhone = phone;
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
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changedPasswordCurrent = currentPassword;
    changedPasswordNew = newPassword;
  }

  @override
  Future<String?> getCurrentPhone() async => null;

  @override
  Future<String?> getCurrentProfilePhoto() async => null;

  @override
  Future<void> updateProfilePhoto({required String photoPath}) async {}
}

const testUser = UserProfile(
  id: 'user-123',
  tenantId: 'tenant-abc',
  email: 'sarah.officer@acme.com',
  fullName: 'Sarah Officer',
  role: UserRole.recoveryOfficer,
);

ProviderContainer _container() => ProviderContainer(
  overrides: [
    authControllerProvider.overrideWith(
      () => _MockProfileAuthController(testUser),
    ),
  ],
);

_MockProfileAuthController _mock(
  WidgetTester tester,
  ProviderContainer container,
) {
  return container.read(authControllerProvider.notifier)
      as _MockProfileAuthController;
}

Finder _button(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(ElevatedButton));

void main() {
  testWidgets('ProfileScreen renders current profile and role badge', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sarah Officer'), findsWidgets);
    expect(find.text('sarah.officer@acme.com'), findsWidgets);
    expect(find.text('Recovery Officer'), findsWidgets);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Change Password'), findsWidgets);
    expect(find.text('Notification Preferences'), findsOneWidget);
    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('About Debit Recovery'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('ProfileScreen validates empty full name', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('profile_full_name_field'));
    await tester.enterText(nameField, '   ');
    await tester.pumpAndSettle();

    final saveButton = _button('Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(_mock(tester, container).updatedName, isNull);
  });

  testWidgets('ProfileScreen submits valid full name update', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('profile_full_name_field'));
    await tester.enterText(nameField, 'Sarah Connor');
    final phoneField = find.byKey(const Key('profile_phone_field'));
    await tester.enterText(phoneField, '555 000 0000');
    await tester.pumpAndSettle();

    final saveButton = _button('Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(_mock(tester, container).updatedName, 'Sarah Connor');
    expect(find.text('Profile details updated successfully'), findsOneWidget);
  });

  testWidgets(
    'Password form validates current, length, and match constraints',
    (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final changeButton = _button('Change Password');
      await tester.ensureVisible(changeButton);
      await tester.tap(changeButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your current password'), findsOneWidget);

      final currentField = find.byKey(
        const Key('profile_current_password_field'),
      );
      await tester.enterText(currentField, 'oldpass123');
      await tester.pumpAndSettle();

      final newField = find.byKey(const Key('profile_new_password_field'));
      await tester.enterText(newField, 'abc');
      await tester.pumpAndSettle();

      await tester.tap(changeButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );

      await tester.enterText(newField, 'NewPass123');
      await tester.pumpAndSettle();

      final confirmField = find.byKey(
        const Key('profile_confirm_password_field'),
      );
      await tester.enterText(confirmField, 'DifferentPass123');
      await tester.pumpAndSettle();

      await tester.tap(changeButton);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);

      await tester.enterText(confirmField, 'NewPass123');
      await tester.pumpAndSettle();

      await tester.tap(changeButton);
      await tester.pumpAndSettle();

      final mock = _mock(tester, container);
      expect(mock.changedPasswordCurrent, 'oldpass123');
      expect(mock.changedPasswordNew, 'NewPass123');
      expect(find.text('Password changed successfully'), findsOneWidget);
    },
  );
}

