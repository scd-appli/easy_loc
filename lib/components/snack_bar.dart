import 'package:flutter/material.dart';

showSnackBar(BuildContext context, Widget content) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: content,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 4,
      duration: Duration(seconds: 3),
    ),
  );
}
