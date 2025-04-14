import 'dart:convert';

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

    // Cannot be more than 17 characters (ISBN-13 + 4 dashes)
    if (value.length > 17) {
      return oldValue;
    }

    // Cannot have more than 4 dashes
    if (value.length - numbers.length > 4) {
      return oldValue;
    }

    // Resolve
    return newValue;
  }
}

bool isISBN10(String value) {
  // Pattern for ISBN-10 without dashes
  RegExp patternWithoutDashes = RegExp(r'^\d{10}$');

  // Pattern for ISBN-10 with dashes
  RegExp patternWithDashes = RegExp(r'^\D{1}-\d{2}-\d{6}-\d{1}$');

  // Check if value matches either pattern
  return patternWithoutDashes.hasMatch(value) ||
      patternWithDashes.hasMatch(value);
}

bool isISBN13(String value) {
  // Pattern for ISBN-13 without dashes
  RegExp patternWithoutDashes = RegExp(r'^\d{13}$');

  // Pattern for ISBN-13 with dashes
  RegExp patternWithDashes = RegExp(r'^\d{3}-\d{1}-\d{2}-\d{6}-\d{1}$');

  return patternWithoutDashes.hasMatch(value) ||
      patternWithDashes.hasMatch(value);
}

bool isPPN(String value) {
  // Pattern for format
  RegExp patternPPN = RegExp(r'^\d{9}$');

  return patternPPN.hasMatch(value);
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
