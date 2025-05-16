import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class HistoryModele {
  final String key = "history";

  HistoryModele();

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$key.csv';
  }

  Future<List<String>?> get() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      final csvString = await file.readAsString();
      if (csvString.isEmpty) {
        return [];
      }

      final List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(csvString);

      if (rowsAsListOfValues.isEmpty) {
        return [];
      }

      return rowsAsListOfValues
          .where((row) => row.isNotEmpty && row[0].toString().isNotEmpty)
          .map((row) => row[0].toString())
          .toList();
    } catch (e) {
      debugPrint("Error reading history CSV: $e");
      return null;
    }
  }

  Future<void> _saveList(List<String> list) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (list.isEmpty) {
        await file.delete();
        return;
      }

      // Convert List<String> to List<List<dynamic>> for the CSV converter
      final List<List<dynamic>> csvData = list.map((isbn) => [isbn]).toList();
      final csvString = const ListToCsvConverter(eol: '\n').convert(csvData);

      await file.writeAsString(csvString);
    } catch (e) {
      debugPrint("Error writing history CSV: $e");
    }
  }

  Future<void> add(String isbn) async {
    List<String> list = await get() ?? [];

    list.add(isbn);
    await _saveList(list);
  }

  Future<void> deleteAll() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Error deleting history CSV: $e");
    }
  }

  Future<void> delete(int index) async {
    List<String>? list = await get();

    if (list == null || list.isEmpty || index < 0 || index >= list.length) {
      return;
    }

    list.removeAt(index);
    await _saveList(list);
  }

  Future<void> toDownload() async {
    bool permissionGranted = false;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 30) { // Android 11 (API 30) or higher
        var status = await Permission.manageExternalStorage.status;
        debugPrint("Android 11+: Initial manageExternalStorage status: $status");
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          debugPrint("Android 11+: Status after manageExternalStorage request: $status");
        }
        if (status.isGranted) {
          permissionGranted = true;
        }
      } else { // Android 10 (API 29) or older (down to your minSdk)
        var status = await Permission.storage.status;
        debugPrint("Android 10 or older: Initial storage status: $status");
        if (!status.isGranted) {
          status = await Permission.storage.request();
          debugPrint("Android 10 or older: Status after storage request: $status");
        }
        if (status.isGranted) {
          permissionGranted = true;
        }
      }
    } else {
      // For non-Android platforms, you might not need special file permissions
      // or they are handled differently.
      permissionGranted = true;
    }

    if (permissionGranted) {
      debugPrint("Storage permission IS GRANTED for the operation.");
      try {
        final String dlFolderPath = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);
        debugPrint('Public Downloads Path: $dlFolderPath');

        if (dlFolderPath.isNotEmpty) {
          final dlFile = File('$dlFolderPath/historyEasyLoc.csv');
          final historyFilePath = await _getFilePath();
          final historyFile = File(historyFilePath);

          if (await historyFile.exists()) {
            final csvString = await historyFile.readAsString();
            await dlFile.writeAsString(csvString);
            debugPrint('File saved to: ${dlFile.path}');
            // Consider showing a success message to the user (e.g., SnackBar)
          } else {
            debugPrint('History file does not exist, nothing to download.');
          }
        } else {
          debugPrint('Could not get the public downloads directory path.');
        }
      } catch (e) {
        debugPrint('Error saving to public downloads: $e');
        // Consider showing an error message to the user
      }
    } else {
      debugPrint('Storage permission IS DENIED.');
      // You should inform the user that the permission is necessary
      // and guide them on how to grant it (especially for manageExternalStorage
      // which requires going to system settings).
    }
  }
}
