import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:easy_loc/components/snack_bar.dart';
import 'package:easy_loc/functions/api.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../functions/permission.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserHistory {
  final String _historyKey = "EasyLocHistory";
  final List<String> header = [
    "ISBN/ISSN",
    "Count",
    "PPN",
    "200/a",
    "200/c",
    "200/d",
    "200/e",
    "200/f",
    "200/g",
    "200/h",
    "200/i",
    "200/r",
    "200/z",
    "214/a",
    "214/b",
    "214/c",
    "214/d",
    "214/r",
    "214/s",
  ];

  UserHistory();

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();

    File file = File('${directory.path}/data/$_historyKey.csv');

    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    return file;
  }

  Future<String?> _saveUserFileLocation({
    String? defaultFileName,
    required Uint8List bytes,
  }) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: "Choose a location",
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: bytes,
    );

    if (outputFile == null) {
      return null;
    }

    return outputFile;
  }

  Future<Directory> _getDirectory() async {
    Directory directoryDefault = await getApplicationDocumentsDirectory();

    Directory directoryData = Directory('${directoryDefault.path}/data');
    if (!await directoryData.exists()) {
      await directoryData.create();
    }

    return directoryData;
  }

  Future<Map<String, List<List<String>>>?> get() async {
    try {
      final file = await _getFile();

      List<List<String>>? list = await _readAndFormatFile(file);

      return list != null ? {"isbn": list} : null;
    } catch (e) {
      debugPrint("Error reading history CSV: $e");
      return null;
    }
  }

  Future<void> _saveFile({
    required String dataFormated,
    required File file,
  }) async {
    if (dataFormated.trim() == "") {
      throw FormatException("The string cannot be empty");
    }
    await file.writeAsString(dataFormated);
  }

  String _listToCsv(List<List<dynamic>> data) {
    return ListToCsvConverter().convert(data);
  }

  List<List<String>> _csvListToString(String data) {
    return CsvToListConverter(shouldParseNumbers: false).convert(data);
  }

  String _formateData({
    required List<List<dynamic>> dataBody,
    required List<String> headerData,
  }) {
    dataBody.insert(0, headerData);

    return _listToCsv(dataBody);
  }

  Future<List<List<String>>?> _readAndFormatFile(File file) async {
    if (!await file.exists()) {
      return null;
    }

    final csvString = await file.readAsString();

    if (csvString.isEmpty) {
      return null;
    }

    final List<List<String>> rowsAsListOfValues = _csvListToString(csvString);

    return rowsAsListOfValues.skip(1).toList();
  }

  Future<void> add(String isbn, List<String> ppn, int count) async {
    Map<String, List<List<String>>>? isbnMap = await get();

    isbnMap ??= {'isbn': []};

    List<List<String>> isbnListReversed = isbnMap["isbn"]!.reversed.toList();
    List<String> listMergedWithPPN = [isbn];
    listMergedWithPPN.add(count.toString());
    listMergedWithPPN.add(ppn.join('; '));

    Map<String, List<String>>? unimarcResult = await unimarc(ppn[0]);
    debugPrint(unimarcResult.toString());

    List<String> unimarcFieldDescriptors = header.sublist(3);

    if (unimarcResult != null) {
      for (String descriptor in unimarcFieldDescriptors) {
        if (unimarcResult.containsKey(descriptor)) {
          listMergedWithPPN.add(unimarcResult[descriptor]!.join("; "));
        } else {
          listMergedWithPPN.add("");
        }
      }
    } else {
      listMergedWithPPN.addAll(List.filled(unimarcFieldDescriptors.length, ""));
    }

    isbnListReversed.add(listMergedWithPPN);
    List<List<String>> newIsbnList = isbnListReversed.reversed.toList();

    await _saveFile(
      dataFormated: _formateData(dataBody: newIsbnList, headerData: header),
      file: await _getFile(),
    );
  }

  Future<void> deleteAll() async {
    try {
      final Directory directory = await _getDirectory();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      debugPrint("Error deleting history CSV: $e");
    }
  }

  Future<void> delete({required int index}) async {
    Map<String, List<List<String>>>? list = await get();

    if (list == null ||
        index < 0 ||
        list['isbn'] == null ||
        index >= list['isbn']!.length) {
      return;
    }

    list['isbn']!.removeAt(index);

    await _saveFile(
      dataFormated: _formateData(dataBody: list['isbn']!, headerData: header),
      file: await _getFile(),
    );
  }

  Future<void> toDownload(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    bool permissionGranted = await grantAccess();

    if (permissionGranted) {
      debugPrint("Storage permission IS GRANTED for the operation.");
      try {
        final File historyFile = await _getFile();
        final csvString = await historyFile.readAsString();

        if (!await historyFile.exists()) {
          debugPrint('History file does not exist, nothing to download.');
          return;
        }

        final bytes = utf8.encode(csvString);

        String? dlFilePath = await _saveUserFileLocation(
          defaultFileName: "EasyLocHistory.csv",
          bytes: Uint8List.fromList(bytes),
        );

        if (context.mounted) {
          if (dlFilePath == null) {
            showSnackBar(context, Text(l10n.saveCancelledUser));
            return;
          }
          showSnackBar(context, Text(l10n.fileSaved));
        }
      } catch (e) {
        debugPrint('Error saving to public downloads: $e');
      }
    } else {
      debugPrint('Storage permission IS DENIED.');
      if (context.mounted) showSnackBar(context, Text(l10n.permissionDenied));
    }
  }

  Future<void> toShare(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final File historyFile = await _getFile();

      final params = ShareParams(files: [XFile(historyFile.path)]);

      final result = await SharePlus.instance.share(params);

      if (result.status == ShareResultStatus.success) {
        if (context.mounted) showSnackBar(context, Text(l10n.fileShared));
        return;
      }

      if (result.status == ShareResultStatus.dismissed) {
        if (context.mounted) {
          showSnackBar(context, Text(l10n.shareCancelledUser));
        }
        return;
      }
    } catch (e) {
      debugPrint("error sharing the history: $e");
    }
  }
}
