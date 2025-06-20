import 'package:flutter/material.dart';
import '../components/custom_app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import "../functions/user_history.dart";
import '../components/card.dart';
import '../functions/utils.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final _history = UserHistory();
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
    Map<String, List<List<String>>>? mapList = await _history.get();

    if (mapList == null || mapList['isbn'] == null) {
      list = [];
      setState(() {});
      return;
    }

    list = mapList['isbn']!.getOnlyIndex(0).cast<String>();

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
        body: Center(
          child: Text(l10n.emptyHistory, style: TextStyle(fontSize: 20)),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.historyTitle,
        actions: [
          IconButton(
            onPressed: () async {
              await _history.toShare(context);
            },
            icon: Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: () async {
              await _history.toDownload(context);
            },
            icon: Icon(Icons.save),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(l10n.deleteHistory),
                      content: Text(l10n.deleteConfirmation),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _history.deleteAll();
                            await _sync();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(
                            l10n.delete,
                            style: TextStyle(color: Colors.red[500]),
                          ),
                        ),
                      ],
                    ),
              );
            },
            icon: Icon(Icons.delete, color: Colors.red[500]),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _sync(),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children:
              list!.asMap().entries.map((element) {
                return CustomCard(
                  title: element.value,
                  onTap: () => Navigator.pop(context, element.value),
                  actions: [
                    IconButton(
                      onPressed: () async {
                        await _history.delete(
                          index: element.key,
                          isbn: element.value,
                        );
                        await _sync();
                      },
                      icon: Icon(Icons.delete, color: Colors.red[300]),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
