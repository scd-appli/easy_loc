import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../functions/utils.dart';
import '../component/card.dart';
import '../component/custom_app_bar.dart';
import '../component/isbn_input_form.dart';
import '../component/scan_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _isbnController = TextEditingController();

  List<Map<String, dynamic>>? _data;
  String? _noData;
  bool _validInput = true;
  int _count = 0;

  void fetchData(String isbn) async {
    setState(() {
      _noData = null;
    });

    List<Map<String, String>>? ppnList = await isbn2ppn(isbn);
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

  void send() {
    String isbn = _isbnController.text;
    // if the isbn is correct
    if (isISBN10(isbn) || isISBN13(isbn)) {
      setState(() {
        fetchData(isbn);
        _validInput = true;
      });
    } else {
      setState(() {
        _validInput = false;
        _noData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return GestureDetector(
        onTap: () {
          // Unfocus when tapped outside the TextField
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: CustomAppBar(title: AppLocalizations.of(context)!.appName),
          body: Center(
            child: IsbnInputForm(
              controller: _isbnController,
              isValid: _validInput,
              noDataMessage:
                  _noData != null
                      ? "${AppLocalizations.of(context)!.noPPNAssociated}: $_noData"
                      : null,
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
      // if research
    } else {
      return GestureDetector(
        onTap: () {
          // Unfocus when tapped outside the TextField
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: CustomAppBar(
            title: AppLocalizations.of(context)!.appName,
            onTitleTap: () {
              setState(() {
                _data = null;
                _isbnController.clear();
                _validInput = true;
                _noData = null;
              });
            },
          ),
          body: Column(
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
                        ? "${AppLocalizations.of(context)!.noPPNAssociated}: $_noData"
                        : null,
                onSend: send,
                padding: 17,
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  _count == 0
                      ? AppLocalizations.of(context)!.noLibraryGotThis
                      : "${AppLocalizations.of(context)!.foundIn} $_count ${_count == 1 ? AppLocalizations.of(context)!.library : AppLocalizations.of(context)!.libraries}",
                ),
              ),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  interactive: true,
                  child: ListView(
                    padding: const EdgeInsets.all(15.0),
                    children:
                        _data!
                            .map(
                              (element) => CustomCard(
                                location: element['location'],
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
          floatingActionButton: ScanButton(
            onSend: send,
            isbnController: _isbnController,
          ),
        ),
      );
    }
  }
}
