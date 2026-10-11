import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkstamp/features/friends/presentation/screens/friend_requests_screen.dart';
import 'package:inkstamp/features/friends/presentation/screens/friend_search_screen.dart';
import 'package:inkstamp/features/friends/presentation/screens/invite_friend_screen.dart';
import 'package:inkstamp/features/stamps/presentation/screens/audience_picker_screen.dart';

void main() {
  testWidgets('invite deep link opens a normalized username search', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FriendSearchScreen(initialUsername: 'mai.paper'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mai'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('accepting a request updates the requests screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FriendRequestsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vy'), findsOneWidget);
    await tester.tap(find.byTooltip('Accept').first);
    await tester.pumpAndSettle();

    expect(find.text('Vy'), findsNothing);
  });

  testWidgets('audience picker uses the friend graph counts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AudiencePickerScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('4 friends'), findsOneWidget);
    expect(find.text('2 people'), findsOneWidget);
    await tester.tap(find.text('Select People'));
    await tester.pump();
    expect(find.byType(CheckboxListTile), findsWidgets);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    expect(find.text('Send to 1 people'), findsOneWidget);
  });

  test('invite links encode usernames as one Android route segment', () {
    expect(
      inviteLinkForUsername('mai.paper'),
      'https://inkstamp.app/u/mai.paper',
    );
  });
}
