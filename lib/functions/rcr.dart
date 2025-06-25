import 'package:shared_preferences/shared_preferences.dart';

// ignore: camel_case_types
class RCR_storage {
  final String key = "rcr";
  static final RegExp rcrRegex = RegExp(r'[0-9]{9}');
  final SharedPreferencesAsync sharred;

  RCR_storage(this.sharred);

  Future<List<String>?> get() async => await sharred.getStringList(key);

  Future<void> add(String rcr) async {
    List<String>? list = await get();

    list ??= [];

    list.add(rcr);

    await sharred.setStringList(key, list);
  }

  Future<void> deleteAll() async {
    await sharred.remove(key);
  }

  Future<void> delete(int index) async {
    List<String>? list = await get();

    if (list == null || list.length - 1 < index) return;

    list.removeAt(index);

    await sharred.setStringList(key, list);
  }

  static bool isRCR(String value) => rcrRegex.hasMatch(value);
}
