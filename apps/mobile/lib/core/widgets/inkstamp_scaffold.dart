import 'package:flutter/material.dart';

class InkstampScaffold extends StatelessWidget {
  const InkstampScaffold({
    required this.body,
    this.title,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.extendBody = false,
    super.key,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsets padding;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: title == null,
          child: Padding(padding: padding, child: body),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
