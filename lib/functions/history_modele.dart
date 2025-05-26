import 'dart:io';
import 'package:easy_loc/components/snack_bar.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../functions/permission.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum HistoryFormat { history, isbn }

class HistoryModele {
  final String _historyKey = "history";

  HistoryModele();

  Future<File> _getFile({String? isbn}) async {
    final directory = await getApplicationDocumentsDirectory();

    File file = File('${directory.path}/data/$_historyKey${isbn ?? ""}.csv');

    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    return file;
  }

  Future<File> _getGeneralFilePath({String? isbn}) async {
    final String dlFolderPath =
        await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOAD,
        );

    debugPrint('Public Downloads Path: $dlFolderPath');

    String baseFileName = 'historyEasyLoc${isbn ?? ""}';
    String extension = '.csv';
    String fileName = baseFileName + extension;
    File dlFile = File('$dlFolderPath/$fileName');
    int counter = 1;

    // Check if file exists and find a unique name
    while (await dlFile.exists()) {
      fileName = '$baseFileName($counter)$extension';
      dlFile = File('$dlFolderPath/$fileName');
      counter++;
    }

    return dlFile;
  }

  Future<Directory> _getDirectory() async {
    Directory directoryDefault = await getApplicationDocumentsDirectory();

    Directory directoryData = Directory('${directoryDefault.path}/data');
    if (!await directoryData.exists()) {
      await directoryData.create();
    }

    return directoryData;
  }

  Future<Map<String, List<String>>?> get({
    required HistoryFormat format,
    String? isbn,
  }) async {
    try {
      switch (format) {
        case HistoryFormat.history:
          final file = await _getFile();

          List<String>? list = await _readAndFormatFile(file);

          return list != null ? {"isbn": list} : null;

        case HistoryFormat.isbn:
          if (isbn == null) {
            throw FormatException("You must provide a ppn for the format isbn");
          }

          final File file = await _getFile(isbn: isbn);

          List<String>? list = await _readAndFormatFile(file);

          return list != null
              ? {
                "isbn": [isbn],
                "ppn": list,
              }
              : null;
      }
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
    return ListToCsvConverter(eol: '\n').convert(data);
  }

  List<List<dynamic>> _csvListToString(String data) {
    return CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(data);
  }

  String _formateData({
    required List<List<dynamic>> dataBody,
    required List<String> headerData,
  }) {
    dataBody.insert(0, headerData);

    return _listToCsv(dataBody);
  }

  Future<List<String>?> _readAndFormatFile(File file) async {
    if (!await file.exists()) {
      return null;
    }

    final csvString = await file.readAsString();

    if (csvString.isEmpty) {
      return null;
    }

    final List<List<dynamic>> rowsAsListOfValues = _csvListToString(csvString);

    return rowsAsListOfValues
        .skip(1)
        .reduce((acc, innerList) => acc = [...acc, ...innerList])
        .cast<String>();
  }

  Future<void> add(String isbn, List<String>? ppn) async {
    Map<String, List<String>>? isbnMap = await get(
      format: HistoryFormat.history,
    );

    isbnMap ??= {'isbn': []};

    List<String> isbnList = isbnMap["isbn"]!.toList();

    List<String> isbnListReversed = isbnList.reversed.toList();
    isbnListReversed.add(isbn);
    List<String> newIsbnList = isbnListReversed.reversed.toList();

    List<List<String>> isbnListRowColumn =
        newIsbnList.map((isbn) => [isbn]).toList();

    await _saveFile(
      dataFormated: _formateData(
        dataBody: isbnListRowColumn,
        headerData: ["ISBN/ISSN"],
      ),
      file: await _getFile(),
    );

    if (ppn == null) {
      return;
    }

    List<List<String>> ppnListRowColumn = ppn.map((ppn) => [ppn]).toList();

    await _saveFile(
      dataFormated: _formateData(
        dataBody: ppnListRowColumn,
        headerData: ['ppn'],
      ),
      file: await _getFile(isbn: isbn),
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

  Future<void> delete({required int index, required String isbn}) async {
    Map<String, List<String>>? list = await get(format: HistoryFormat.history);

    if (list == null ||
        index < 0 ||
        list['isbn'] == null ||
        index >= list['isbn']!.length) {
      return;
    }

    list['isbn']!.removeAt(index);

    List<List<String>> isbnListRowColumn =
        list['isbn']!.map((isbn) => [isbn]).toList();

    await _saveFile(
      dataFormated: _formateData(
        dataBody: isbnListRowColumn,
        headerData: ['isbn'],
      ),
      file: await _getFile(),
    );

    File ppnFile = await _getFile(isbn: isbn);

    if (await ppnFile.exists()) {
      ppnFile.delete();
    }
  }

  Future<void> toDownload(BuildContext context, {String? isbn}) async {
    final l10n = AppLocalizations.of(context)!;

    bool permissionGranted = await grantAccess();

    if (permissionGranted) {
      debugPrint("Storage permission IS GRANTED for the operation.");
      try {
        File dlFile = await _getGeneralFilePath(isbn: isbn);

        final File historyFile = await _getFile(isbn: isbn);

        if (await historyFile.exists()) {
          final csvString = await historyFile.readAsString();
          await dlFile.writeAsString(csvString);
          debugPrint('File saved to: ${dlFile.path}');
          if (context.mounted) showSnackBar(context, Text(l10n.fileSaved));
        } else {
          debugPrint('History file does not exist, nothing to download.');
        }
      } catch (e) {
        debugPrint('Error saving to public downloads: $e');
      }
    } else {
      debugPrint('Storage permission IS DENIED.');
      if (context.mounted) showSnackBar(context, Text(l10n.permissionDenied));
    }
  }
}
