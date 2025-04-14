import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'functions/utils.dart';

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
  late TextEditingController _isbnController;

  List<Map<String, String>>? _data;
  String? _noData;
  bool _validInput = true;

  @override
  void initState() {
    super.initState();
    _isbnController = TextEditingController();
  }

  @override
  void dispose() {
    _isbnController.dispose();
    super.dispose();
  }

  Future<String?> isbn2ppn(String isbn) async {
    final response = await getAPI(
      "https://www.sudoc.fr/services/isbn2ppn/$isbn",
    );
    return response['sudoc']?['query']?['result']?['ppn'];
  }

  Future<List<Map<String, String>>> multiwhere(String ppn) async {
    try {
      final response = await getAPI(
        "https://www.sudoc.fr/services/multiwhere/$ppn",
      );

      final libraryData = response['sudoc']?['query']?['result']?['library'];

      if (libraryData == null) {
        return [];
      }

      if (libraryData is List) {
        return List<Map<String, String>>.from(
          libraryData.map((item) => Map<String, String>.from(item)),
        );
      } else if (libraryData is Map) {
        // Handle case when only one library is returned (might be a direct map)
        return [Map<String, String>.from(libraryData)];
      }

      return [];
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  void fetchData(String isbn) async {
    String? ppn = await isbn2ppn(isbn);
    if (ppn == null) {
      setState(() {
        _noData = isbn;
      });
      return null;
    }

    List<Map<String, String>> response = await multiwhere(ppn);
    setState(() {
      _noData = null;
      _data = response;
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
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _isbnController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "ISBN",
                        errorText: _validInput ? null : "Input Invalid",
                        suffixIcon:
                            _isbnController.text.isNotEmpty
                                ? IconButton(
                                  onPressed: () {
                                    send();
                                  },
                                  icon: const Icon(Icons.send),
                                )
                                : null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                        IsISBN(),
                      ],
                      onSubmitted: (value) {
                        send();
                      },
                    ),
                    Text(
                      _noData != null
                          ? "Aucune notice n'est associée à cette valeur: $_noData"
                          : '',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
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
              });
            },
          ),
          body: Expanded(child: Text("test")),
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
