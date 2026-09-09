import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_router.dart';
import 'package:inkstamp/app/theme/app_theme.dart';
import 'package:inkstamp/features/authentication/presentation/controllers/session_controller.dart';

class InkstampApp extends ConsumerWidget {
  const InkstampApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Inkstamp',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

/// A [Listenable] that notifies when [SessionState.stage] changes so that
/// GoRouter re-evaluates its redirect callback.
class SessionRedirectNotifier extends ChangeNotifier {
  SessionRedirectNotifier(this._ref) {
    _ref.listen(sessionControllerProvider, (
      SessionState? previous,
      SessionState next,
    ) {
      if (previous?.stage != next.stage) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}
