import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:easy_loc/components/snack_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../functions/permission.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum HistoryFormat { history, isbn }

extension Csv on List<List>{
  List getOnlyIndex(int index){
    List list = [];
    for (var row in this){
      list.add(row[index]);
    }
    return list;
  }
}

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

  Future<Map<String, List<List<String>>>?> get({
    required HistoryFormat format,
    String? isbn,
  }) async {
    try {
      switch (format) {
        case HistoryFormat.history:
          final file = await _getFile();

          List<List<String>>? list = await _readAndFormatFile(file);

          return list != null ? {"isbn": list} : null;

        case HistoryFormat.isbn:
          if (isbn == null) {
            throw FormatException("You must provide an isbn for the format isbn");
          }

          final File file = await _getFile(isbn: isbn);

          List<List<String>>? list = await _readAndFormatFile(file);

          return list != null
              ? {
                "isbn": [[isbn]],
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

  List<List<String>> _csvListToString(String data) {
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

  Future<List<List<String>>?> _readAndFormatFile(File file) async {
    if (!await file.exists()) {
      return null;
    }

    final csvString = await file.readAsString();

    if (csvString.isEmpty) {
      return null;
    }
  
    final List<List<String>> rowsAsListOfValues = _csvListToString(csvString);

    return rowsAsListOfValues
        .skip(1)
        .toList();
  }

  Future<void> add(String isbn, List<String> ppn, int count) async {
    Map<String, List<List<String>>>? isbnMap = await get(
      format: HistoryFormat.history,
    );

    isbnMap ??= {'isbn': []};


    List<List<String>> isbnListReversed = isbnMap["isbn"]!.reversed.toList();
    List<String> listMergedWithPNN = [isbn];
    listMergedWithPNN.add(count.toString());
    listMergedWithPNN.add(ppn.join('; '));
    isbnListReversed.add(listMergedWithPNN);
    List<List<String>> newIsbnList = isbnListReversed.reversed.toList();

    await _saveFile(
      dataFormated: _formateData(
        dataBody: newIsbnList,
        headerData: ["ISBN/ISSN","Count","PPN"],
      ),
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

  Future<void> delete({required int index, required String isbn}) async {
    Map<String, List<List<String>>>? list = await get(format: HistoryFormat.history);

    if (list == null ||
        index < 0 ||
        list['isbn'] == null ||
        index >= list['isbn']!.length) {
      return;
    }

    list['isbn']!.removeAt(index);

    await _saveFile(
      dataFormated: _formateData(
        dataBody: list['isbn']!,
        headerData: ['ISBN/ISSN',"Count","PPN"],
      ),
      file: await _getFile(),
    );

    File ppnFile = await _getFile(isbn: isbn);

    if (await ppnFile.exists()) {
      ppnFile.delete();
    }
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
}
