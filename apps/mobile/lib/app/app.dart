import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_router.dart';
import 'package:inkstamp/app/theme/app_theme.dart';

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
