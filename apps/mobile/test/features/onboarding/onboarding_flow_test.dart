import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/app/app.dart';

void main() {
  testWidgets('the router completes the in-memory onboarding flow', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: InkstampApp()));
    await tester.pumpAndSettle();
    expect(find.text('Small moments,\nkept for longer.'), findsOneWidget);

    await tester.tap(find.text('Get started with Inkstamp'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Inkstamp'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('A little access'), findsOneWidget);

    await tester.tap(find.text('Allow and continue'));
    await tester.pumpAndSettle();
    expect(find.text('Stamps on your Home Screen'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('INKSTAMP'), findsOneWidget);
    expect(find.bySemanticsLabel('Take photo'), findsOneWidget);
  });
}
