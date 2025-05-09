// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:easy_loc/main.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

base class MockSharedPreferencesAsyncPlatform
    extends SharedPreferencesAsyncPlatform
    with MockPlatformInterfaceMixin {
  final Map<String, Object?> _store = {};

  @override
  Future<bool?> getBool(
    String key, [
    SharedPreferencesOptions? options,
  ]) async => _store[key] as bool?;

  @override
  Future<int?> getInt(String key, [SharedPreferencesOptions? options]) async =>
      _store[key] as int?;

  @override
  Future<double?> getDouble(
    String key, [
    SharedPreferencesOptions? options,
  ]) async => _store[key] as double?;

  @override
  Future<String?> getString(
    String key, [
    SharedPreferencesOptions? options,
  ]) async => _store[key] as String?;

  @override
  Future<List<String>?> getStringList(
    String key, [
    SharedPreferencesOptions? options,
  ]) async => _store[key] as List<String>?;

  @override
  Future<void> setBool(
    String key,
    bool value, [
    SharedPreferencesOptions? options,
  ]) async => _store[key] = value;

  @override
  Future<void> setInt(
    String key,
    int value, [
    SharedPreferencesOptions? options,
  ]) async => _store[key] = value;

  @override
  Future<void> setDouble(
    String key,
    double value, [
    SharedPreferencesOptions? options,
  ]) async => _store[key] = value;

  @override
  Future<void> setString(
    String key,
    String value, [
    SharedPreferencesOptions? options,
  ]) async => _store[key] = value;

  @override
  Future<void> setStringList(
    String key,
    List<String> value, [
    SharedPreferencesOptions? options,
  ]) async => _store[key] = value;

  @override
  Future<void> clear(
    ClearPreferencesParameters parameters, [
    SharedPreferencesOptions? options,
  ]) async => _store.clear();

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters, [
    SharedPreferencesOptions? options,
  ]) async => _store.keys.toSet();
  
  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters, [
    SharedPreferencesOptions? options,
  ]) async => Map.fromEntries(
    _store.entries
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value!)),
  );
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        MockSharedPreferencesAsyncPlatform();
  });
  testWidgets('Trigger a frame', (WidgetTester tester) async {
    await tester.pumpWidget(const EasyLoc());
  });
}
