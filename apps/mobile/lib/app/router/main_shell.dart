import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int selectedIndex = switch (location) {
      String value when value.startsWith('/inbox') => 0,
      String value when value.startsWith('/camera') => 1,
      String value when value.startsWith('/calendar') => 2,
      _ => 3,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          final String route = switch (index) {
            0 => AppRoutes.inbox,
            1 => AppRoutes.camera,
            2 => AppRoutes.calendar,
            _ => AppRoutes.friends,
          };
          context.go(route);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.mail_outline_rounded),
            selectedIcon: Icon(Icons.mail_rounded),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: _CameraDestinationIcon(selected: false),
            selectedIcon: _CameraDestinationIcon(selected: true),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Friends',
          ),
        ],
      ),
    );
  }
}

class _CameraDestinationIcon extends StatelessWidget {
  const _CameraDestinationIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : AppColors.sky,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.camera_alt_rounded,
        color: selected ? AppColors.white : AppColors.ink,
        size: 21,
      ),
    );
  }
}
