import 'package:shared_preferences/shared_preferences.dart';

class HistoryModele {
  final String key = "history";
  final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();

  HistoryModele();

  Future<List<String>?> get() async => _asyncPrefs.getStringList(key);

  Future<void> add(String isbn) async {
    List<String>? list = await get();

    if (list == null) {
      list = [isbn];
    } else {
      list.add(isbn);
    }

    _asyncPrefs.setStringList(key, list);
  }

  Future<void> deleteAll() async {
    _asyncPrefs.remove(key);
  }

  Future<void> delete(int index) async {
    List<String>? list = await get();

    if (list == null || list.length < index + 1) return;

    list.removeAt(index);

    _asyncPrefs.setStringList(key, list);
  }
}
