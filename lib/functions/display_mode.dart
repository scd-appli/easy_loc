import 'package:easy_loc/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum DisplayMode { system, light, dark }

class Mode {
  DisplayMode _mode;
  SharedPreferencesAsync sharred;

  Mode(this._mode, this.sharred);

  void changeMode(BuildContext context, DisplayMode mode) async {
    _mode = mode;
    await sharred.setInt("mode", displayModeToInt(mode));
    EasyLoc.of(context).changeTheme(Mode.displayModeToThemeMode(mode));
  }

  DisplayMode get() => _mode;

  Future<DisplayMode> getSync() async {
    int? n = await sharred.getInt("mode");

    if (n == null) {
      _mode = DisplayMode.system;
      return _mode;
    }

    _mode = intToDisplayMode(n);
    return _mode;
  }

  static String displayModeToString(BuildContext context, DisplayMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case DisplayMode.system:
        return l10n.system;
      case DisplayMode.light:
        return l10n.light;
      case DisplayMode.dark:
        return l10n.dark;
    }
  }

  static DisplayMode intToDisplayMode(int n) {
    switch (n) {
      case 0:
        return DisplayMode.system;
      case 1:
        return DisplayMode.light;
      case 2:
        return DisplayMode.dark;
      default:
        return DisplayMode.system;
    }
  }

  static int displayModeToInt(DisplayMode mode) {
    switch (mode) {
      case DisplayMode.system:
        return 0;
      case DisplayMode.light:
        return 1;
      case DisplayMode.dark:
        return 2;
    }
  }

  static ThemeMode displayModeToThemeMode(DisplayMode mode) {
    switch (mode) {
      case DisplayMode.light:
        return ThemeMode.light;
      case DisplayMode.dark:
        return ThemeMode.dark;
      case DisplayMode.system:
        return ThemeMode.system;
    }
  }
}
