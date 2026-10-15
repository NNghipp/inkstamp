import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/app/theme/app_theme.dart';
import 'package:inkstamp/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('editorial feed fits the 412x892 target viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: HomeScreen(initializeCamera: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('khoảnh khắc'), findsOneWidget);
    expect(find.text('Những khoảnh khắc được giữ lại.'), findsOneWidget);
    expect(find.text('Nắng sớm ngõ nhỏ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
