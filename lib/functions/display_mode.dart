import 'package:easy_loc/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Mode {
  final String key = "mode";
  ThemeMode _mode;
  SharedPreferencesAsync sharred;

  Mode(this._mode, this.sharred);

  void changeMode(BuildContext context, ThemeMode mode) async {
    _mode = mode;
    await sharred.setInt(key, mode.index);
    if (context.mounted) EasyLoc.of(context).changeTheme(mode);
  }

  ThemeMode get() => _mode;

  Future<ThemeMode> getSync() async {
    int? n = await sharred.getInt(key);

    if (n == null || n < 0 || n >= ThemeMode.values.length) {
      _mode = ThemeMode.system;
      return _mode;
    }

    _mode = ThemeMode.values[n];
    return _mode;
  }

  static String themeModeToString(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.system:
        return l10n.system;
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
    }
  }

  static int themeModeToInt(ThemeMode mode) {
    return mode.index;
  }

  static ThemeMode intToThemeMode(int n) {
    if (n < 0 || n >= ThemeMode.values.length) {
      return ThemeMode.system; // Default to system if out of bounds
    }
    return ThemeMode.values[n];
  }
}
