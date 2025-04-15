import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'functions/utils.dart';
import 'component/card.dart';

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
      home: const HomeScreen(),
    );
  }
}

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
        _count = 0;
      });
      return;
    }

    List<Map<String, dynamic>> response = await multiwhere(ppnList);

    int count = 0;
    for (var ppnEntry in response) {
      final librariesList = ppnEntry['libraries'] as List?;
      if (librariesList != null) {
        count += librariesList.length;
      }
    }

    setState(() {
      _noData = null;
      _data = response;
      _count = count;
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
          appBar: CustomAppBar(title: 'EasyLoc'),
          body: Center(
            child: IsbnInputForm(
              controller: _isbnController,
              isValid: _validInput,
              noDataMessage:
                  _noData != null
                      ? "No record is associated with this value: $_noData"
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
          floatingActionButton: ScanButton(onPressed: () {}),
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
            title: 'EasyLoc',
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
                        ? "No record is associated with this value: $_noData"
                        : null,
                onSend: send,
                padding: 17,
              ),
              Text(
                _count == 0
                    ? "No library has this item."
                    : "Found in $_count ${_count == 1 ? 'library' : 'libraries'}",
              ),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  interactive: true,
                  child: ListView(
                    padding: const EdgeInsets.all(15.0),
                    children:
                        _data!
                            .expand(
                              (entry) => (entry['libraries'] as List? ?? [])
                                  .map((library) {
                                    return CustomCard(
                                      location: library['location'],
                                      longitude: library['longitude'],
                                      latitude: library['latitude'],
                                    );
                                  }),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: ScanButton(onPressed: () {}),
        ),
      );
    }
  }
}

class ScanButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ScanButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          Theme.of(context).primaryColor,
        ),
        iconSize: const WidgetStatePropertyAll(30),
        fixedSize: WidgetStateProperty.all(const Size(60, 60)),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        ),
      ),
      child: const Icon(Icons.qr_code_scanner, color: Colors.black),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onTitleTap;

  const CustomAppBar({super.key, required this.title, this.onTitleTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(onTap: onTitleTap, child: Text(title)),
      centerTitle: true,
      leading: const Icon(Icons.history, size: 30),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Icon(Icons.settings_outlined, size: 30),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class IsbnInputForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isValid;
  final String? noDataMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final double? padding;

  const IsbnInputForm({
    super.key,
    required this.controller,
    required this.isValid,
    this.noDataMessage,
    required this.onChanged,
    required this.onSend,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Use ValueListenableBuilder to rebuild suffixIcon when controller text changes
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Padding(
          padding:
              padding != null
                  ? EdgeInsets.only(top: padding!, bottom: padding!)
                  : EdgeInsets.zero,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: controller,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "ISBN",
                      errorText: isValid ? null : "Input invalid",
                      suffixIcon:
                          value.text.isNotEmpty
                              ? IconButton(
                                onPressed: onSend,
                                icon: const Icon(Icons.send),
                              )
                              : null,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-X]')),
                      IsISBN(),
                    ],
                    onSubmitted: (_) => onSend(),
                  ),
                  if (noDataMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        noDataMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
