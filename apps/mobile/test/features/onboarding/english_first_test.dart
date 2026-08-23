import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/app/app.dart';
import 'package:inkstamp/features/onboarding/presentation/screens/welcome_screen.dart';

void main() {
  testWidgets('the application is explicitly English-first', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const InkstampApp());

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.locale, const Locale('en'));

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  });

  testWidgets('welcome content is presented in English', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Small moments,\nkept for longer.'), findsOneWidget);
    expect(find.text('Get started with Inkstamp'), findsOneWidget);
    expect(find.textContaining('Capture a moment'), findsOneWidget);
  });
}
