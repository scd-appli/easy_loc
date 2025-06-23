import 'package:easy_loc/components/custom_app_bar.dart';
import 'package:easy_loc/components/snack_bar.dart';
import 'package:easy_loc/functions/rcr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RCR extends StatefulWidget {
  const RCR({super.key});

  @override
  State<RCR> createState() => _RCRState();
}

class _RCRState extends State<RCR> {
  SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();
  List<String>? rcrList;
  late RCR_storage rcrStorage;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    rcrStorage = RCR_storage(asyncPrefs);
    rcrList = await rcrStorage.get();
    setState(() {
      loading = false;
    });
  }

  _sync() async {
    rcrList = await rcrStorage.get();
    setState(() {});
  }

  _add(AppLocalizations l10n, String rcr) async {
    if (!RCR_storage.isRCR(rcr)) {
      return;
    }

    if (rcrList != null && rcrList!.contains(rcr)) {
      showSnackBar(context, Text(l10n.alreadyRcr));
      return;
    }

    await rcrStorage.add(rcr);
    await _sync();
  }

  _deleteAll() async => await rcrStorage.deleteAll();

  _modalDialog(AppLocalizations l10n) {
    final TextEditingController textController = TextEditingController();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha((255.0 * 0.2).round()),
      builder: (BuildContext context) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom, // Handle keyboard
              ),
              child: Container(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      controller: textController,
                      onSubmitted: (value) async {
                        final trimmed = value.trim();
                        if (RCR_storage.isRCR(trimmed)) {
                          await _add(l10n, trimmed);
                          if (context.mounted) Navigator.pop(context);
                        } else {
                          setModalState(() => errorText = l10n.mustBe9Digit);
                        }
                      },
                      onChanged: (value) {
                        setModalState(() => errorText = null);
                      },
                      decoration: InputDecoration(
                        labelText: l10n.rcr,
                        border: OutlineInputBorder(),
                        helperText: " ",
                        errorText: errorText,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).primaryColor,
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                ),
                          ),
                          onPressed: () async {
                            final text = textController.text.trim();
                            if (text.isEmpty) return;

                            if (RCR_storage.isRCR(text)) {
                              await _add(l10n, text);
                              if (context.mounted) Navigator.pop(context);
                              return;
                            }

                            setModalState(() => errorText = l10n.mustBe9Digit);
                          },
                          child: Text(
                            l10n.add,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    late Widget body;

    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (rcrList == null || rcrList!.isEmpty) {
      body = Center(
        child: Text(l10n.rcrListEmpty, style: TextStyle(fontSize: 20)),
      );
    } else {
      body = Padding(
        padding: EdgeInsets.only(left: 25),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: rcrList!.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: ValueKey<String>(rcrList![index]),
                    onDismissed: (direction) async {
                      final removedIndex = index;

                      setState(() {
                        rcrList!.removeAt(index);
                      });
                      await rcrStorage.delete(removedIndex);
                    },
                    child: ListTile(
                      title: Row(
                        children: [
                          Text(rcrList![index]),
                          Spacer(),
                          IconButton(
                            onPressed: () async {
                              setState(() {
                                rcrList!.removeAt(index);
                              });
                              await rcrStorage.delete(index);
                            },
                            icon: Icon(Icons.delete, color: Colors.red[300]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 120),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: "RCR",
          actions: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      _modalDialog(l10n);
                    },
                    icon: Icon(Icons.add),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: const Offset(
                              1.0,
                              0.0,
                            ), // Slide in from right
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeInOut)),
                        ),
                        child: child,
                      );
                    },
                    child:
                        (rcrList != null && rcrList!.isNotEmpty)
                            ? IconButton(
                              key: const ValueKey('delete_button'),
                              onPressed: () {
                                _deleteAll();
                                _sync();
                              },
                              icon: Icon(Icons.delete, color: Colors.red[500]),
                            )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: ElevatedButton(
          onPressed: () {
            _modalDialog(l10n);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).primaryColor,
            ),
            iconSize: const WidgetStatePropertyAll(30),
            padding: WidgetStateProperty.all(EdgeInsets.all(13)),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.black),
              Text(l10n.add, style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        body: body,
      ),
    );
  }
}
