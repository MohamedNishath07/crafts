import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows validation errors on empty submission', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Clear initial demo values
    final emailField = find.widgetWithText(TextFormField, 'Email Address');
    final passwordField = find.widgetWithText(TextFormField, 'Password');

    await tester.enterText(emailField, '');
    await tester.enterText(passwordField, '');
    await tester.pumpAndSettle();

    // Tap the submit button
    final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    // Verify error messages appear
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('LoginScreen validates invalid email format', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final emailField = find.widgetWithText(TextFormField, 'Email Address');
    await tester.enterText(emailField, 'not-an-email');
    await tester.pumpAndSettle();

    final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email'), findsOneWidget);
  });
}
