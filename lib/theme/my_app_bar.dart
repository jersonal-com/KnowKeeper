import 'package:flutter/material.dart';
import 'package:know_keeper/theme/app_theme.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? drawer;

  const MyAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              secondGradientColor,
            ],
          ),
        ),
      ),
      actions: actions,
      leading: _buildLeading(context),
      automaticallyImplyLeading: showBackButton,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (drawer != null) {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openDrawer(),
      );
    } else if (!showBackButton) {
      return Container();
    }
    return null; // This will show the default back button when showBackButton is true
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}