import 'package:flutter/services.dart';

extension StringExtensions on String {
  /// Counts the number of occurrences of a specific character [l] within the string.
  ///
  /// Example:
  /// ```dart
  /// 'hello'.numberOf('l'); // returns 2
  /// 'banana'.numberOf('a'); // returns 3
  /// ```
  int numberOf(String l) {
    int count = 0;
    for (var i in split('')) {
      if (i == l) count++;
    }
    return count;
  }

  /// Moves the single occurrence of a character [l] to the end of the string.
  ///
  /// Throws a [FormatException] if the character [l] does not appear exactly
  /// once in the string.
  ///
  /// Example:
  /// ```dart
  /// 'he.llo'.pushToTheEnd('.'); // returns 'hello.'
  /// 'abc.def'.pushToTheEnd('.'); // returns 'abcdef.'
  /// ```
  ///
  /// Throws [FormatException] if [l] is not found or found more than once:
  /// ```dart
  /// 'hello'.pushToTheEnd('.'); // throws FormatException
  /// 'he.l.lo'.pushToTheEnd('.'); // throws FormatException
  /// ```
  String pushToTheEnd(String l) {
    if (numberOf(l) != 1) {
      throw FormatException(
        "The parameter must have exactly one occurence in the string",
      );
    }

    return replaceFirst(RegExp(l), "") + l;
  }
}

extension Csv on List<List> {
  List getOnlyIndex(int index) {
    List list = [];
    for (var row in this) {
      list.add(row[index]);
    }
    return list;
  }
}

class IsISBN extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String value = newValue.text;
    final String numbers = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 13 digits maximum (ISBN-13 length)
    if (numbers.length > 13) {
      return oldValue;
    }

    // cannot have more than 4 dashes
    if (value.numberOf("-") > 4) {
      return oldValue;
    }

    // Only one X or x
    if (value.numberOf("X") + value.numberOf("x") > 1) {
      return oldValue;
    }

    // Replace x by X
    if (value.contains("x")) {
      value = value.replaceFirst("x", "X");
    }

    // if X exist and not at the end, pushed to the end
    if (value.contains("X") && !value.endsWith("X")) {
      return TextEditingValue(text: value.pushToTheEnd("X"));
    }

    // Resolve
    return TextEditingValue(text: value);
  }
}

// Regular expression for validating ISBN-10.
// Supports optional hyphens.
// Matches: "0306406152", "0-306-40615-2", "030640615X", "0-306-40615-X", "12345-123-1X"
final RegExp isbn10Regex = RegExp(
  // 1. Anchor for the start of the string.
  // ignore: prefer_adjacent_string_concatenation
  r'^' +
      // 2. Positive lookahead (?=...) to enforce overall structural rules for the ISBN data.
      //    This ensures the string is either:
      //    - Exactly 10 characters (digits or 'X') if no hyphens are used, OR
      //    - 10-13 characters (digits, 'X', or hyphens) if hyphens are used,
      //      with a sub-lookahead to check for 1 to 3 hyphen-separated groups of digits.
      r'(?=' +
      r'[0-9X]{10}$' + // Case A: Exactly 10 chars (digits 0-9 or 'X'), followed by end of string (no hyphens).
      r'|' + // OR
      // Case B (with hyphens):
      // Inner lookahead: asserts 1 to 3 groups of digits followed by a hyphen.
      // An ISBN-10 has 4 parts, so up to 3 hyphens.
      r'(?=(?:[0-9]+[-]){1,3})' +
      // If inner lookahead passes, the ISBN data (digits, 'X', hyphens) must be 10-13 chars long.
      r'[-0-9X]{10,13}$' +
      r')' + // End of positive lookahead.
      // 3. The main pattern for ISBN-10 parts, allowing optional hyphens:
      r'[0-9]{1,5}' + // Part 1: Group identifier (1-5 digits).
      r'[-]?' + // Optional hyphen.
      r'[0-9]+' + // Part 2: Publisher identifier (1+ digits).
      r'[-]?' + // Optional hyphen.
      r'[0-9]+' + // Part 3: Title identifier (1+ digits).
      r'[-]?' + // Optional hyphen.
      r'[0-9X]' + // Part 4: Check digit (digit or 'X').
      // 4. Anchor for the end of the string.
      r'$',
  caseSensitive: false,
);

// Regular expression for validating ISBN-13.
// Supports optional hyphens.
// Matches: "9780306406157", "978-0-306-40615-7", "979-10-90639-1-3"
final RegExp isbn13Regex = RegExp(
  // 1. Anchor for the start of the string.
  // ignore: prefer_adjacent_string_concatenation
  r'^' +
      // 2. Positive lookahead (?=...) to enforce overall structural rules for the ISBN data.
      //    This ensures the string is either:
      //    - Exactly 13 digits if no hyphens are used, OR
      //    - 13-17 characters (digits or hyphens) if hyphens are used,
      //      with a sub-lookahead to check for 3 to 4 hyphen-separated groups of digits.
      r'(?=' +
      r'[0-9]{13}$' + // Case A: Exactly 13 digits, followed by end of string (no hyphens).
      r'|' + // OR
      // Case B (with hyphens):
      // Inner lookahead: asserts 3 to 4 groups of digits followed by a hyphen.
      // An ISBN-13 has 5 parts, so up to 4 hyphens.
      r'(?=(?:[0-9]+[-]){3,4})' +
      // If inner lookahead passes, the ISBN data (digits, hyphens) must be 13-17 chars long.
      r'[-0-9]{13,17}$' +
      r')' + // End of positive lookahead.
      // 3. The main pattern for ISBN-13 parts, allowing optional hyphens:
      r'97[89]' + // Part 1: Prefix (must be "978" or "979").
      r'[-]?' + // Optional hyphen.
      r'[0-9]{1,5}' + // Part 2: Registration group element (1-5 digits).
      r'[-]?' + // Optional hyphen.
      r'[0-9]+' + // Part 3: Registrant element (1+ digits).
      r'[-]?' + // Optional hyphen.
      r'[0-9]+' + // Part 4: Publication element (1+ digits).
      r'[-]?' + // Optional hyphen.
      r'[0-9]' + // Part 5: Check digit (must be a digit for ISBN-13).
      // 4. Anchor for the end of the string.
      r'$',
  caseSensitive: false,
);

// Regular expression for validating ISSN.
// Supports an optional hyphen.
// Matches: "12345678", "1234-5678", "1234567X", "1234-567X"
final RegExp issnRegex = RegExp(
  // 1. Anchor for the start of the string.
  // ignore: prefer_adjacent_string_concatenation
  r'^' +
      // 2. Positive lookahead (?=...) to enforce overall structural rules for the ISSN data.
      //    This ensures the string is either:
      //    - Exactly 8 characters (digits or 'X') if no hyphen is used, OR
      //    - Exactly 9 characters (digits, 'X', or hyphen) if a hyphen is used.
      r'(?=' +
      r'[0-9X]{8}$' + // Case A: Exactly 8 chars (digits 0-9 or 'X'), followed by end of string (no hyphen).
      r'|' + // OR
      // Case B (with hyphen):
      // Exactly 9 chars (digits, 'X', hyphen), with a hyphen at the 5th position.
      r'[0-9]{4}-[0-9X]{4}$' +
      r')' + // End of positive lookahead.
      // 3. The main pattern for ISSN parts:
      r'\d{4}' + // Part 1: First four digits.
      r'-?' + // Optional hyphen.
      r'\d{3}' + // Part 2: Next three digits.
      r'[\dxX]' + // Part 3: Check digit (digit, 'x', or 'X').
      // 4. Anchor for the end of the string.
      r'$',
  caseSensitive: false,
);

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

List<bool Function(String)> acceptedFormatFunction() {
  List<bool Function(String)> list = [];
  // acceptedSearch will use isISBN13, isISBN10, isISSN etc. from this file (utils.dart)
  for (var type in acceptedSearch) {
    list.add(type[1] as bool Function(String));
  }
  return list;
}

// searchISBN13, isISBN13, searchISBN10, isISBN10, searchISSN, isISSN
// are assumed to be defined earlier in this file (utils.dart).
List<List<dynamic>> acceptedSearch = [
  [searchISBN13, isISBN13],
  [searchISBN10, isISBN10],
  [searchISSN, isISSN],
];

bool isValidFormat(String value) {
  for (var func in acceptedFormatFunction()) {
    if (func(value)) return true;
  }
  return false;
}

Format? getFormat(String value) {
  // isISBN10, isISBN13, isISSN are from this file (utils.dart)
  if (isISBN10(value) || isISBN13(value)) return Format.isbn;
  if (isISSN(value)) return Format.issn;
  return null;
}

List<Map<String, String>> sortLibraries(List<Map<String, String>> libraries) {
  libraries.sort(
    (a, b) =>
        a['location']!.toLowerCase().compareTo(b['location']!.toLowerCase()),
  );
  return libraries;
}
