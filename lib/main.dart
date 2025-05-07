import 'dart:io';

import 'package:easy_loc/screens/camera_scan_screen.dart';
import 'package:easy_loc/screens/history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screens.dart';
import 'screens/settings.dart';
import 'functions/display_mode.dart';
import 'functions/display_language.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const EasyLoc());
}

class EasyLoc extends StatefulWidget {
  const EasyLoc({super.key});

  @override
  State<EasyLoc> createState() => _EasyLocState();

  // ignore: library_private_types_in_public_api
  static _EasyLocState of(BuildContext context) =>
      context.findAncestorStateOfType<_EasyLocState>()!;
}

class _EasyLocState extends State<EasyLoc> {
  final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

  late Mode _mode;
  ThemeMode _themeMode = ThemeMode.system;
  SupportedLanguages _languageSetting = SupportedLanguages.system;
  Locale _locale = Locale(Platform.localeName.split('_')[0]);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    _loadTheme();
    _loadLanguage();
  }

  void _loadTheme() async {
    setState(() {
      _mode = Mode(DisplayMode.system, asyncPrefs);
    });

    final DisplayMode savedMode = await _mode.getSync();
    final ThemeMode newThemeMode = Mode.displayModeToThemeMode(savedMode);

    if (_themeMode != newThemeMode) changeTheme(newThemeMode);
  }

  void _loadLanguage() async {
    final languageManager = DisplayLanguage(asyncPrefs);
    final newLocale = await languageManager.loadSavedSetting();
    final newSetting = languageManager.getCurrentSetting();

    if (newSetting != _languageSetting || newLocale != _locale) {
      setState(() {
        _languageSetting = newSetting;
        _locale = newLocale;
      });
    }
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
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
      locale: _locale,
      routes: {
        '/settings': (context) => Settings(),
        '/history': (context) => History(),
        '/scan': (context) => CameraScanScreen()
      },
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
