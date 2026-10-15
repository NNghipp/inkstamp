import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkstamp/app/router/app_routes.dart';
import 'package:inkstamp/app/theme/gallery_tokens.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int selectedIndex = switch (location) {
      String value when value.startsWith('/calendar') => 1,
      String value when value.startsWith('/camera') => 2,
      String value when value.startsWith('/profile') => 3,
      _ => 0,
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: GalleryTokens.secondary,
      ),
      child: Scaffold(
        body: child,
        bottomNavigationBar: _EditorialNavigation(
          selectedIndex: selectedIndex,
          onSelected: (int index) => context.go(
            <String>[
              AppRoutes.home,
              AppRoutes.calendar,
              AppRoutes.camera,
              AppRoutes.profile,
            ][index],
          ),
        ),
      ),
    );
  }
}

class _EditorialNavigation extends StatelessWidget {
  const _EditorialNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const List<(IconData, String)> items = <(IconData, String)>[
      (Icons.photo_library_outlined, 'Khoảnh khắc'),
      (Icons.calendar_today_outlined, 'Lịch'),
      (Icons.photo_camera_outlined, 'Máy ảnh'),
      (Icons.person_outline, 'Cá nhân'),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: GalleryTokens.secondary,
        border: Border(top: BorderSide(color: GalleryTokens.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List<Widget>.generate(items.length, (int index) {
              final bool selected = index == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        items[index].$1,
                        size: selected ? 22 : 20,
                        color: selected
                            ? GalleryTokens.text
                            : GalleryTokens.secondaryText,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[index].$2,
                        style: TextStyle(
                          color: selected
                              ? GalleryTokens.text
                              : GalleryTokens.secondaryText,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      SizedBox(
                        height: 3,
                        child: selected && index == 2
                            ? const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: GalleryTokens.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox.square(dimension: 3),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
