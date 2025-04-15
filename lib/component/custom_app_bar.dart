import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onTitleTap;

  const CustomAppBar({super.key, required this.title, this.onTitleTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(onTap: onTitleTap, child: Text(title)),
      centerTitle: true,
      leading: const Icon(Icons.history, size: 30),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Icon(Icons.settings_outlined, size: 30),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
