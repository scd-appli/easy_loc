import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../functions/utils.dart';
import '../components/card.dart';
import '../components/custom_app_bar.dart';
import '../components/isbn_input_form.dart';
import '../components/scan_button.dart';
import '../functions/user_history.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../functions/api.dart';
import '../functions/rcr.dart';

Future<void> _addHistoryEntryIsolate(Map<String, dynamic> params) async {
  // Extract the token and initialize BackgroundIsolateBinaryMessenger
  final RootIsolateToken token = params['token'] as RootIsolateToken;
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final String isbn = params['isbn'] as String;
  final List<String> ppnValue =
      (params['ppnValue'] as List<dynamic>).cast<String>();
  final int count = params['count'] as int;

  final UserHistory history = UserHistory();
  await history.add(isbn, ppnValue, count);
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

// Wrapper function for compute
List<Map<String, String>> _sortLibrariesWrapper(Map<String, dynamic> params) {
  final List<Map<String, String>> libraries =
      (params['libraries'] as List<dynamic>).cast<Map<String, String>>();
  final List<String>? priorityRcrList =
      (params['priorityRcrList'] as List<dynamic>?)?.cast<String>();

  return sortLibraries(
    libraries,
    priorityRcrList: priorityRcrList,
    addPriorityFlag: true,
  );
}

class _HomeState extends State<Home> {
  final TextEditingController _isbnController = TextEditingController();

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

    List<Map<String, dynamic>> response = await multiwhere(ppnList);

    List<Map<String, String>> allLibraries =
        response
            .expand(
              (result) =>
                  (result['libraries'] as List<dynamic>)
                      .cast<Map<String, String>>(),
            )
            .toList();

    // Get RCR priority list
    final rcrStorage = RCR_storage(SharedPreferencesAsync());
    final priorityRcrList = await rcrStorage.get();

    List<Map<String, String>> sortedLibraries = await compute(
      _sortLibrariesWrapper,
      {'libraries': allLibraries, 'priorityRcrList': priorityRcrList},
    );

    List<String> ppnValue =
        ppnList.map((ppn) => ppn['ppn']).cast<String>().toList();

    if (fromHistory != null && !fromHistory) {
      final RootIsolateToken? token = RootIsolateToken.instance;
      if (token != null) {
        compute(_addHistoryEntryIsolate, {
          'token': token,
          'isbn': isbn,
          'ppnValue': ppnValue,
          'count': sortedLibraries.length,
        });
      } else {
        debugPrint("the token for the isolate is null is null");
      }
    }

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
    final Color primaryColor = Theme.of(context).primaryColor;

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
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 180.0),
                    itemCount: _data!.length,
                    itemBuilder: (context, index) {
                      debugPrint("$index: ${_data![index]}\nconditions: ${_data![index]["priority"] == true}");
                      if (_data![index]["priority"] == "true") {
                        return CustomCard(
                          title: _data![index]['location'],
                          longitude: _data![index]['longitude'],
                          latitude: _data![index]['latitude'],
                          backgroundColor: primaryColor,
                        );
                      }
                      return CustomCard(
                        title: _data![index]['location'],
                        longitude: _data![index]['longitude'],
                        latitude: _data![index]['latitude'],
                      );
                    },
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
