import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screens.dart';

void main() {
  runApp(const EasyLoc());
}

class EasyLoc extends StatelessWidget {
  const EasyLoc({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyLoc',
      theme: ThemeData(
        primaryColor: const Color(0xff7d82b8),
        brightness: Brightness.light,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr')],
      home: const HomeScreen(),
    );
  }
}
