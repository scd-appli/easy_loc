import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../functions/utils.dart';
import '../components/card.dart';
import '../components/custom_app_bar.dart';
import '../components/isbn_input_form.dart';
import '../components/scan_button.dart';
import '../functions/history_modele.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../functions/api.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _isbnController = TextEditingController();
  final HistoryModele _history = HistoryModele();

  List<Map<String, dynamic>>? _data;
  String? _noData;
  bool _validInput = true;
  int _count = 0;

  Future<void> _fetchData(String isbn, Format format, bool? fromHistory) async {
    setState(() {
      _noData = null;
    });

    late List<Map<String, String>>? ppnList;

    switch (format) {
      case Format.isbn:
        ppnList = await isbn2ppn(isbn);
        break;
      case Format.issn:
        ppnList = await issn2ppn(isbn);
        break;
    }

    if (ppnList == null || ppnList.isEmpty) {
      setState(() {
        _noData = isbn;
      });
      return;
    }

    List<String> ppnValue =
        ppnList.map((ppn) => ppn['ppn']).cast<String>().toList();

    if (fromHistory != null && !fromHistory) {
      _history.add(isbn, ppnValue);
    }

    List<Map<String, dynamic>> response = await multiwhere(ppnList);

    List<Map<String, String>> allLibraries =
        response
            .expand(
              (result) =>
                  (result['libraries'] as List<dynamic>)
                      .cast<Map<String, String>>(),
            )
            .toList();

    List<Map<String, String>> sortedLibraries = await compute(
      sortLibraries,
      allLibraries,
    );

    setState(() {
      _noData = null;
      _data = sortedLibraries;
      _count = sortedLibraries.length;
    });
  }

  Future<void> send({bool? fromHistory}) async {
    String value = _isbnController.text;
    setState(() {
      _data = null;
    });

    if (isValidFormat(value)) {
      setState(() {
        _fetchData(value, getFormat(value)!, fromHistory);
        _validInput = true;
      });
    } else {
      setState(() {
        _validInput = false;
        _noData = null;
      });
    }
  }

  // AppBar for the HomeScreen
  PreferredSizeWidget? appBar({VoidCallback? onTitleTap}) {
    final l10n = AppLocalizations.of(context)!;
    return CustomAppBar(
      title: l10n.appName,
      onTitleTap: onTitleTap ?? () {},
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: IconButton(
            icon: Icon(Icons.settings_outlined),
            iconSize: 30,
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              if (mounted) FocusScope.of(context).unfocus();
            },
          ),
        ),
      ],
      leading: IconButton(
        icon: Icon(Icons.history),
        iconSize: 30,
        onPressed: () async {
          dynamic isbn = await Navigator.pushNamed(context, '/history');
          if (isbn != null) {
            _isbnController.text = isbn;
            await send(fromHistory: true);
          }
          if (mounted) FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_data == null) {
      // Initial state or after reset
      return GestureDetector(
        onTap: () {
          // Unfocus when tapped outside the TextField
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: appBar(),
          body: Center(
            child: IsbnInputForm(
              controller: _isbnController,
              isValid: _validInput,
              noDataMessage:
                  _noData != null ? "${l10n.noPPNAssociated}: $_noData" : null,
              onChanged: (value) {
                if (!_validInput) {
                  setState(() {
                    _validInput = true;
                  });
                }
              },
              onSend: send,
            ),
          ),
          floatingActionButton: ScanButton(
            onSend: send,
            isbnController: _isbnController,
          ),
        ),
      );
    }

    // State when data is loaded (research results shown)
    return GestureDetector(
      onTap: () {
        // Unfocus when tapped outside the TextField
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: appBar(
          onTitleTap: () {
            setState(() {
              _data = null;
              _isbnController.clear();
              _validInput = true;
              _noData = null;
            });
          },
        ),
        floatingActionButton: ScanButton(
          onSend: send,
          isbnController: _isbnController,
        ),
        body: RefreshIndicator(
          onRefresh: () => send(fromHistory: true),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IsbnInputForm(
                controller: _isbnController,
                isValid: _validInput,
                onChanged: (value) {
                  if (!_validInput) {
                    setState(() {
                      _validInput = true;
                    });
                  }
                },
                noDataMessage:
                    _noData != null
                        ? "${l10n.noPPNAssociated}: $_noData"
                        : null,
                onSend: ({bool? fromHistory}) => send(fromHistory: fromHistory),
                padding: 17,
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  _count == 0
                      ? l10n.noLibraryGotThis
                      : "${l10n.foundIn} $_count ${_count == 1 ? l10n.library : l10n.libraries}",
                ),
              ),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  interactive: true,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 180.0),
                    children:
                        _data!
                            .map(
                              (element) => CustomCard(
                                title: element['location'],
                                longitude: element['longitude'],
                                latitude: element['latitude'],
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
