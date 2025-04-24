import 'package:flutter/material.dart';
import '../components/custom_app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import "../functions/history_modele.dart";
import '../components/card.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final _history = HistoryModele();
  late List<String>? list;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    await _sync();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _sync() async {
    list = await _history.get();
    list ??= [];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: l10n.historyTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (list!.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: l10n.historyTitle),
        body: Center(child: Text(l10n.emptyHistory)),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.historyTitle,
        actions: [
          IconButton(
            onPressed: () async {
              await _history.deleteAll();
              await _sync();
            },
            icon: Icon(Icons.delete, color: Colors.red[500]),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children:
            list!
                .asMap()
                .entries
                .map((element) {
                  return CustomCard(
                    title: element.value,
                    onTap: () => Navigator.pop(context, element.value),
                    actions: IconButton(
                      onPressed: () async {
                        await _history.delete(element.key);
                        await _sync();
                      },
                      icon: Icon(Icons.delete, color: Colors.red[300]),
                    ),
                  );
                })
                .toList()
                .reversed
                .toList(),
      ),
    );
  }
}
