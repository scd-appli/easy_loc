import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/custom_app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../components/custom_drop_down_menu.dart';
import '../functions/display_mode.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

  late Mode _mode = Mode(DisplayMode.system, asyncPrefs);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    _loadMode();
  }

  void _loadMode() async {
    int? n = await asyncPrefs.getInt("mode");

    if (n == null) {
      _mode = Mode(DisplayMode.system, asyncPrefs);
      return;
    }

    setState(() {
      _mode = Mode(Mode.intToDisplayMode(n), asyncPrefs);
    });
  }

  void onChangedMode(DisplayMode value) {
    if (_mode.get() == value) return;

    _mode.changeMode(context, value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CustomAppBar(title: l10n.settingsTitle),
        body: Padding(
          padding: EdgeInsets.only(top: 20, right: 40, left: 40),
          child: Center(
            child: Column(
              children: [
                Row(
                  children: [
                    Text("display mode", style: TextStyle(fontSize: 17)),
                    Spacer(),
                    CustomDropDownMenu(
                      dropdownMenuEntries:
                          DisplayMode.values.map((element) {
                            return DropdownMenuEntry<DisplayMode>(
                              value: element,
                              label: Mode.displayModeToString[element]!,
                            );
                          }).toList(),
                      onSelected: (value) {
                        if (value != null) {
                          onChangedMode(value);
                        }
                      },
                      initialSelection: _mode.get(),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Text("language", style: TextStyle(fontSize: 17)),
                    Spacer(),
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
