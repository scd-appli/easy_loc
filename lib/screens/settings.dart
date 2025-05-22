import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/custom_app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../components/custom_drop_down_menu.dart';
import '../functions/display_mode.dart';
import '../functions/display_language.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
  PackageInfo? packageInfo;

  late Mode _mode;
  late DisplayLanguage _lang;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _mode = Mode(ThemeMode.system, asyncPrefs);
    _lang = DisplayLanguage(asyncPrefs);
    _load();
  }

  void _load() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([_loadMode(), _loadLang(), _loadInfo()]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMode() async {
    await _mode.getSync();
  }

  Future<void> _loadLang() async {
    await _lang.loadSavedSetting();
  }

  Future<void> _loadInfo() async {
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (e, s) {
      debugPrint("Error loading settings data: $e\n$s");
    }
  }
  void changeMode(ThemeMode value) {
    if (_mode.get() == value) return;

    _mode.changeMode(context, value);
    if (mounted) {
      setState(() {});
    }
  }

  void changeLanguageSetting(SupportedLanguages value) {
    if (_lang.getCurrentSetting() == value) return;

    _lang.changeLocaleSetting(context, value);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);

    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: l10n.settingsTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determine if the 'System' option should be available
    final String systemLangCode = Platform.localeName.split('_')[0];
    final List<String> supportedLangCodes =
        AppLocalizations.supportedLocales
            .map((locale) => locale.languageCode)
            .toList();
    final bool showSystemOption = supportedLangCodes.contains(systemLangCode);

    // Filter the language options based on whether the system language is supported
    final List<SupportedLanguages> availableLanguageOptions =
        showSystemOption
            ? SupportedLanguages.values.toList()
            : SupportedLanguages.values
                .where((lang) => lang != SupportedLanguages.system)
                .toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CustomAppBar(title: l10n.settingsTitle),
        body: Padding(
          padding: EdgeInsets.only(top: 20, right: 30, left: 30, bottom: 30),
          child: Center(
            child: Column(
              children: [
                Row(
                  children: [
                    Text(l10n.displayMode, style: TextStyle(fontSize: 17)),
                    Spacer(),                    CustomDropDownMenu(
                      key: ValueKey(
                        'displayMode_${currentLocale.languageCode}',
                      ), // trigger the rebuild
                      dropdownMenuEntries:
                          ThemeMode.values.map((element) {
                            return DropdownMenuEntry<ThemeMode>(
                              value: element,
                              label: Mode.themeModeToString(context, element),
                            );
                          }).toList(),
                      onSelected: (value) {
                        if (value != null) {
                          changeMode(value);
                        }
                      },
                      initialSelection: _mode.get(),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Text(l10n.language, style: TextStyle(fontSize: 17)),
                    Spacer(),
                    CustomDropDownMenu(
                      key: ValueKey(
                        'language_${currentLocale.languageCode}_$showSystemOption', // Update key
                      ), // trigger the rebuild
                      dropdownMenuEntries:
                          availableLanguageOptions.map((element) {
                            // Use filtered list
                            return DropdownMenuEntry<SupportedLanguages>(
                              value: element,
                              label: DisplayLanguage.supportedLanguagesToString(
                                context,
                                element,
                              ),
                            );
                          }).toList(),
                      onSelected: (value) {
                        if (value != null) {
                          changeLanguageSetting(value);
                        }
                      },
                      // Ensure initial selection is valid if 'System' was filtered out
                      initialSelection:
                          availableLanguageOptions.contains(
                                _lang.getCurrentSetting(),
                              )
                              ? _lang.getCurrentSetting()
                              : SupportedLanguages.en,
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Text(l10n.appName, style: TextStyle(fontSize: 25)),
                          Text("Version: ${packageInfo?.version ?? "Unknow"}"),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(AntDesign.github_outline, size: 60),
                      onPressed:
                          () => launchUrl(
                            Uri(scheme: "https", host: "www.github.com", path: "scd-appli/easy_loc"),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
