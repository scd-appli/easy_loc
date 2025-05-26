import 'dart:io';

import 'package:easy_loc/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum SupportedLanguages { system, en, fr }

class DisplayLanguage {
  final String key = "lang";
  SupportedLanguages _languageSetting;
  SharedPreferencesAsync sharred;

  // Constructor initializes with a setting, defaulting to system
  DisplayLanguage(
    this.sharred, {
    SupportedLanguages initialSetting = SupportedLanguages.system,
  }) : _languageSetting = initialSetting;

  SupportedLanguages getCurrentSetting() => _languageSetting;

  // Method to get the effective locale based on the setting
  Locale getEffectiveLocale() {
    switch (_languageSetting) {
      case SupportedLanguages.en:
        return Locale("en");
      case SupportedLanguages.fr:
        return Locale("fr");
      case SupportedLanguages.system:
        String platformLangCode = Platform.localeName.split('_')[0];
        if (platformLangCode != 'en' && platformLangCode != 'fr') {
          platformLangCode = 'en';
        }
        return Locale(platformLangCode);
    }
  }

  void changeLocaleSetting(
    BuildContext context,
    SupportedLanguages setting,
  ) async {
    if (_languageSetting == setting) return; // No change needed

    _languageSetting = setting;
    await sharred.setInt(key, supportedLanguageToInt(_languageSetting));

    if (context.mounted) EasyLoc.of(context).changeLocale(getEffectiveLocale());
  }

  Future<Locale> getSync() async {
    int? n = await sharred.getInt(key);
    _languageSetting = intToSupportedLanguage(
      n ?? supportedLanguageToInt(SupportedLanguages.system),
    );
    return getEffectiveLocale();
  }

  // Convert int from storage to SupportedLanguages enum
  static SupportedLanguages intToSupportedLanguage(int n) {
    switch (n) {
      case 1:
        return SupportedLanguages.en;
      case 2:
        return SupportedLanguages.fr;
      case 0:
      default:
        return SupportedLanguages.system;
    }
  }

  // Convert SupportedLanguages enum to int for storage
  static int supportedLanguageToInt(SupportedLanguages lang) {
    switch (lang) {
      case SupportedLanguages.system:
        return 0;
      case SupportedLanguages.en:
        return 1;
      case SupportedLanguages.fr:
        return 2;
    }
  }

  // Convert SupportedLanguages enum to display string
  static String supportedLanguagesToString(
    BuildContext context,
    SupportedLanguages lang,
  ) {
    final l10n = AppLocalizations.of(context)!;
    switch (lang) {
      case SupportedLanguages.system:
        return l10n.system;
      case SupportedLanguages.en:
        return l10n.english;
      case SupportedLanguages.fr:
        return l10n.french;
    }
  }
}
