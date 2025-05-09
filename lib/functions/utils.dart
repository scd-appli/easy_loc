import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class IsISBN extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String value = newValue.text;
    final String numbers = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 13 digits maximum (ISBN-13 length)
    if (numbers.length > 13) {
      return oldValue;
    }

    // cannot have more than 4 dashes
    if (value.length - numbers.length > 4) {
      return oldValue;
    }

    // Resolve
    return newValue;
  }
}

final isbn10Regex = RegExp(
  // Match either compact (9 digits + check) or hyphenated (groups + check)
  r'^(?:' // Start non-capturing group for alternatives
  // Alternative 1: Compact ISBN-10. Match 9 digits.
  r'(?<number>\d{9})'
  r'|' // OR
  // Alternative 2: Hyphenated ISBN-10.
  // Use lookahead to assert total length is 13 characters.
  r'(?=[\dX -]{13}$)'
  // Match the hyphenated groups.
  r'(?<registrationGroup>\d{1,5})[ -](?<registrant>\d{1,7})[ -](?<publication>\d{1,6})[ -]'
  r')' // End non-capturing group for alternatives
  // Match the final check digit (must be a digit or 'X').
  r'(?<checkDigit>[\dX])$',
);

final isbn13Regex = RegExp(
  r'^(?<gs1>\d{3})(?:(?<number>\d{9})|(?=[\d -]{14}$)[ -](?<registrationGroup>\d{1,5})[ -](?<registrant>\d{1,7})[ -](?<publication>\d{1,6})[ -])(?<checkDigit>\d)$',
);

final issnRegex = RegExp(r'^\d{4}-\d{3}[\dxX]$');

bool isISBN10(String value) => isbn10Regex.hasMatch(value);

bool isISBN13(String value) => isbn13Regex.hasMatch(value);

bool isISSN(String value) => issnRegex.hasMatch(value);

final RegExp searchISBN13 = RegExp(
  isbn13Regex.pattern.substring(1, isbn13Regex.pattern.length - 1),
);
final RegExp searchISBN10 = RegExp(
  isbn10Regex.pattern.substring(1, isbn10Regex.pattern.length - 1),
);

final RegExp searchISSN = RegExp(
  issnRegex.pattern.substring(1, issnRegex.pattern.length - 1),
);

enum Format { isbn, issn }

List<bool Function(String)> acceptedFormat = [isISBN10, isISBN13, isISSN];
List<List<dynamic>> acceptedSearch = [
  [searchISBN13, isISBN13],
  [searchISBN10, isISBN10],
  [searchISSN, isISSN],
];

bool isValidFormat(String value) {
  for (var func in acceptedFormat) {
    if (func(value)) return true;
  }

  return false;
}

Format? getFormat(String value){
  if (isISBN10(value) || isISBN13(value)) return Format.isbn;
  if (isISSN(value)) return Format.issn;
  return null;
}

Future<dynamic> getAPI(String url) async {
  var response = await http.get(
    Uri.parse(url),
    headers: {'Accept': 'text/json'}, // API negociation to get in json
  );
  if (response.statusCode != 200 && response.statusCode != 404) {
    throw Exception("Failed to fetch, status code : ${response.statusCode}");
  }
  return jsonDecode(response.body);
}

Future<List<Map<String, String>>?> isbn2ppn(String isbn) async {
  try {
    final response = await getAPI(
      "https://www.sudoc.fr/services/isbn2ppn/$isbn",
    );

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

Future<List<Map<String,String>>?> issn2ppn(String issn) async{
    try {
    final response = await getAPI(
      "https://www.sudoc.fr/services/issn2ppn/$issn",
    );

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
  List<Map<String, String>> ppnList,
) async {
  List<Map<String, dynamic>> results = [];

  await Future.wait(
    ppnList.map((ppnMap) async {
      String? ppnValue = ppnMap['ppn'];
      if (ppnValue == null) return;

      try {
        final response = await getAPI(
          "https://www.sudoc.fr/services/multiwhere/$ppnValue",
        );

        final queryResult = response['sudoc']?['query']?['result'];
        final libraryData = queryResult?['library'];

        List<Map<String, String>> libraries = [];
        if (libraryData != null) {
          List<dynamic> rawLibraries = [];
          if (libraryData is List) {
            rawLibraries = libraryData;
          } else if (libraryData is Map) {
            // Handle case where API returns a single map if only one library
            rawLibraries = [libraryData];
          }

          libraries = List<Map<String, String>>.from(
            rawLibraries
                .map((item) {
                  if (item is Map) {
                    return {
                      'location': item['shortname']?.toString() ?? '',
                      'longitude': item['longitude']?.toString() ?? '',
                      'latitude': item['latitude']?.toString() ?? '',
                    };
                  } else {
                    return {};
                  }
                })
                .where((map) => map.isNotEmpty), // Filter out empty maps
          );
        }
        // Add result for this PPN to the list (synchronized access not strictly needed with Future.wait like this)
        results.add({'ppn': ppnValue, 'libraries': libraries});
      } catch (e) {
        debugPrint("Error fetching libraries for PPN $ppnValue: $e");
      }
    }),
  );

  return results;
}

List<Map<String, String>> sortLibraries(List<Map<String, String>> libraries) {
  libraries.sort(
    (a, b) =>
        a['location']!.toLowerCase().compareTo(b['location']!.toLowerCase()),
  );
  return libraries;
}
