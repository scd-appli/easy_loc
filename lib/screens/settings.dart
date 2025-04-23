import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/custom_app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../components/custom_drop_down_menu.dart';
import '../functions/display_mode.dart';
import '../functions/display_language.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

  late Mode _mode;
  late DisplayLanguage _lang;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mode = Mode(DisplayMode.system, asyncPrefs);
    _lang = DisplayLanguage(asyncPrefs);
    _load();
  }

  void _load() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([_loadMode(), _loadLang()]);
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

  void changeMode(DisplayMode value) {
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CustomAppBar(title: l10n.settingsTitle),
        body: Padding(
          padding: EdgeInsets.only(top: 20, right: 30, left: 30),
          child: Center(
            child: Column(
              children: [
                Row(
                  children: [
                    Text(l10n.displayMode, style: TextStyle(fontSize: 17)),
                    Spacer(),
                    CustomDropDownMenu(
                      key: ValueKey(
                        'displayMode_${currentLocale.languageCode}',
                      ), // trigger the rebuild
                      dropdownMenuEntries:
                          DisplayMode.values.map((element) {
                            return DropdownMenuEntry<DisplayMode>(
                              value: element,
                              label: Mode.displayModeToString(context, element),
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
                        'language_${currentLocale.languageCode}',
                      ), // trigger the rebuild
                      dropdownMenuEntries:
                          SupportedLanguages.values.map((element) {
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
                      initialSelection: _lang.getCurrentSetting(),
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
