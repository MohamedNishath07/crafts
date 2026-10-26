import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/admin/data/staff_repository.dart';
import 'package:crafts/features/admin/presentation/admin_users_screen.dart';
import 'package:crafts/features/admin/presentation/widgets/add_staff_dialog.dart';
import '../../test_helpers/mock_staff_repository.dart';

void main() {
  testWidgets('AdminUsersScreen displays staff management UI and table', (tester) async {
    // Set viewport size for desktop layout
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = MockStaffRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: AdminUsersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and buttons
    expect(find.text('Staff User Management'), findsOneWidget);
    expect(find.text('Add Staff Member'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);

    // Verify staff members from roster are displayed
    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('Recovery Officer Bob'), findsOneWidget);
  });

  testWidgets('AddStaffDialog validates inputs and submits', (tester) async {
    final mockRepo = MockStaffRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staffRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AddStaffDialog(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap submit with empty fields
    final submitButton = find.widgetWithText(ElevatedButton, 'Add Member');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Validation messages shown
    expect(find.text('Please enter full name'), findsOneWidget);
    expect(find.text('Please enter email address'), findsOneWidget);

    // Enter valid details
    final nameField = find.widgetWithText(TextFormField, 'Full Name');
    final emailField = find.widgetWithText(TextFormField, 'Email Address');

    await tester.enterText(nameField, 'Sarah Connor');
    await tester.enterText(emailField, 'sarah@acme.com');
    await tester.pumpAndSettle();

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Validation errors should be cleared
    expect(find.text('Please enter full name'), findsNothing);
    expect(find.text('Please enter email address'), findsNothing);
  });
}
