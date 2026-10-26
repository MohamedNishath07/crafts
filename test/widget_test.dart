import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/main.dart';

void main() {
  testWidgets('DebitRecoveryApp smoke test: displays brand and login form', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DebitRecoveryApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify brand heading and sign in form render cleanly
    expect(find.text('Debit Recovery'), findsWidgets);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
