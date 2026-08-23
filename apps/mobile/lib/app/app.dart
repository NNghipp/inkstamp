import 'package:flutter/material.dart';
import 'package:inkstamp/app/router/app_router.dart';
import 'package:inkstamp/app/theme/app_theme.dart';

class InkstampApp extends StatelessWidget {
  const InkstampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Inkstamp',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
