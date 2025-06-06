import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

const String sudocApiBaseUrl = "https://www.sudoc.fr/services";
const String isbn2ppnEndpoint = "$sudocApiBaseUrl/isbn2ppn/";
const String issn2ppnEndpoint = "$sudocApiBaseUrl/issn2ppn/";
const String multiwhereEndpoint = "$sudocApiBaseUrl/multiwhere/";
const String unimarcEndpoint = "https://www.sudoc.fr/";

enum FileFormat { json, xml }

Future<dynamic> getAPI(
  String url, {
  http.Client? client,
  FileFormat? format = FileFormat.json,
}) async {
  final httpClient = client ?? http.Client();
  try {
    var response = await httpClient.get(
      Uri.parse(url),
      headers: {'Accept': 'text/json'}, // API negociation to get in json
    );
    if (response.statusCode != 200 && response.statusCode != 404) {
      throw Exception("Failed to fetch, status code : ${response.statusCode}");
    }

    if (format == FileFormat.xml) {
      return response.body;
    }
    return jsonDecode(response.body);
  } finally {
    if (client == null) {
      // Close the client only if it was created internally by this function
      httpClient.close();
    }
  }
}

Future<List<Map<String, String>>?> isbn2ppn(
  String isbn, {
  http.Client? client,
}) async {
  try {
    final response = await getAPI(isbn2ppnEndpoint + isbn, client: client);

    final result = response['sudoc']?['query']?['result'];
    if (result is List) {
      return List<Map<String, String>>.from(
        result.map((item) => Map<String, String>.from(item)),
      );
    } else if (result is Map) {
      return [Map<String, String>.from(result)];
    }
    return null;
  } catch (e) {
    debugPrint("Error in isbn2ppn: $e");
    return null;
  }
}

Future<List<Map<String, String>>?> issn2ppn(
  String issn, {
  http.Client? client,
}) async {
  try {
    final response = await getAPI(issn2ppnEndpoint + issn, client: client);

    final result = response['sudoc']?['query']?['result'];
    if (result is List) {
      return List<Map<String, String>>.from(
        result.map((item) => Map<String, String>.from(item)),
      );
    } else if (result is Map) {
      return [Map<String, String>.from(result)];
    }
    return null;
  } catch (e) {
    debugPrint("Error in issn2ppn: $e");
    return null;
  }
}

Future<List<Map<String, dynamic>>> multiwhere(
  List<Map<String, String>> ppnList, {
  http.Client? client,
}) async {
  List<Map<String, dynamic>> results = [];

  await Future.wait(
    ppnList.map((ppnMap) async {
      String? ppnValue = ppnMap['ppn'];
      if (ppnValue == null) return;

      try {
        final response = await getAPI(
          multiwhereEndpoint + ppnValue,
          client: client,
        );

        final libraryData = response['sudoc']?['query']?['result']?['library'];

        List<Map<String, String>> libraries = [];
        if (libraryData != null) {
          List<dynamic> rawLibraries = [];
          if (libraryData is List) {
            rawLibraries = libraryData;
          } else if (libraryData is Map) {
            rawLibraries = [libraryData];
          }

          libraries =
              rawLibraries
                  .map((item) {
                    if (item is Map) {
                      final String shortname =
                          item['shortname']?.toString() ?? '';
                      final String longitude =
                          item['longitude']?.toString() ?? '';
                      final String latitude =
                          item['latitude']?.toString() ?? '';

                      if (shortname.isNotEmpty &&
                          longitude.isNotEmpty &&
                          latitude.isNotEmpty) {
                        return {
                          'location': shortname,
                          'longitude': longitude,
                          'latitude': latitude,
                        };
                      }
                    }
                    return null; // Return null for invalid or incomplete items
                  })
                  .whereType<Map<String, String>>()
                  .toList(); // Filter out nulls and ensure correct type
        }
        results.add({'ppn': ppnValue, 'libraries': libraries});
      } catch (e) {
        debugPrint("Error fetching libraries for PPN $ppnValue: $e");
      }
    }),
  );

  return results;
}

Future<Map<String, List<String>>?> unimarc(
  String ppn, {
  http.Client? client,
}) async {
  try {
    final response = await getAPI(
      "$unimarcEndpoint$ppn.xml",
      client: client,
      format: FileFormat.xml,
    );
    final XmlDocument document = XmlDocument.parse(response);
    final Iterable<XmlElement> datafields = document.descendantElements.where(
      (element) =>
          element.localName == 'datafield' &&
          element.getAttribute('tag') == '200',
    );

    Map<String, List<String>> result = {};

    for (var datafieldElement in datafields) {
      for (var subfieldElement in datafieldElement.findElements('subfield')) {
        var code = subfieldElement.getAttribute("code");
        var text = subfieldElement.innerText;
        if (code != null && text.isNotEmpty) {
          if (!result.containsKey(code)) {
            result[code] = [];
          }
          result[code]!.add(text);
        }
      }
    }

    return result;
  } catch (e) {
    debugPrint("Error fetching for unimarc, ppn: $ppn, error: $e");
    return null;
  }
}
