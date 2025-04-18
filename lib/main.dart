import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screens.dart';
import 'screens/settings.dart';
import 'functions/display_mode.dart';

void main() {
  runApp(const EasyLoc());
}

class EasyLoc extends StatefulWidget {
  const EasyLoc({super.key});

  @override
  State<EasyLoc> createState() => _EasyLocState();

  static _EasyLocState of(BuildContext context) =>
      context.findAncestorStateOfType<_EasyLocState>()!;
}

class _EasyLocState extends State<EasyLoc> {
  final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

  late Mode _mode;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() {
      _mode = Mode(DisplayMode.system, asyncPrefs);
    });

    final DisplayMode savedMode = await _mode.getSync();
    final ThemeMode newThemeMode = Mode.displayModeToThemeMode(savedMode);

    if (_themeMode != newThemeMode) changeTheme(newThemeMode);
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyLoc',
      theme: ThemeData(
        primaryColor: const Color(0xff7d82b8),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xff7d82b8),
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {'/settings': (context) => Settings()},
      supportedLocales: const [Locale('en'), Locale('fr')],
      home: const HomeScreen(),
    );
  }
}
