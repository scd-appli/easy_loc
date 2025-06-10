import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_loc/functions/utils.dart';

void main() {
  group('StringExtensions', () {
    group('numberOf', () {
      test('should return correct count of a character', () {
        expect('hello'.numberOf('l'), 2);
        expect('testing'.numberOf('t'), 2);
        expect('mississippi'.numberOf('s'), 4);
        expect(''.numberOf('a'), 0);
        expect('abc'.numberOf('d'), 0);
      });

      test('should be case sensitive', () {
        expect('Hello'.numberOf('h'), 0);
        expect('Hello'.numberOf('H'), 1);
      });
    });

    group('pushToTheEnd', () {
      test('should push the specified character to the end', () {
        expect('abXcde'.pushToTheEnd('X'), 'abcdeX');
        expect('123x456'.pushToTheEnd('x'), '123456x');
      });

      test(
        'should throw FormatException if character appears more than once',
        () {
          expect(() => 'abXcXde'.pushToTheEnd('X'), throwsFormatException);
        },
      );

      test('should throw FormatException if character does not appear', () {
        expect(() => 'abcde'.pushToTheEnd('X'), throwsFormatException);
      });

      test('should work with character already at the end', () {
        expect('abcdeX'.pushToTheEnd('X'), 'abcdeX');
      });
      test('should handle empty string when char is not present', () {
        expect(() => ''.pushToTheEnd('X'), throwsFormatException);
      });
    });
  });

  group('Csv Extension', () {
    test('getOnlyIndex should return column at specified index', () {
      final csvData = [
        ['Name', 'Age', 'City'],
        ['Alice', '25', 'Paris'],
        ['Bob', '30', 'London'],
        ['Charlie', '35', 'Berlin'],
      ];

      // Test getting first column (index 0)
      expect(csvData.getOnlyIndex(0), ['Name', 'Alice', 'Bob', 'Charlie']);

      // Test getting second column (index 1)
      expect(csvData.getOnlyIndex(1), ['Age', '25', '30', '35']);

      // Test getting third column (index 2)
      expect(csvData.getOnlyIndex(2), ['City', 'Paris', 'London', 'Berlin']);
    });

    test('getOnlyIndex should handle empty list', () {
      final List<List> emptyData = [];
      expect(emptyData.getOnlyIndex(0), isEmpty);
    });

    test('getOnlyIndex should handle mixed data types', () {
      final mixedData = [
        [1, 'text', true],
        [2, 'more text', false],
        [3, 'another', null],
      ];

      expect(mixedData.getOnlyIndex(0), [1, 2, 3]);
      expect(mixedData.getOnlyIndex(1), ['text', 'more text', 'another']);
      expect(mixedData.getOnlyIndex(2), [true, false, null]);
    });

    test('getOnlyIndex should handle single row', () {
      final singleRow = [
        ['single', 'row', 'data'],
      ];

      expect(singleRow.getOnlyIndex(0), ['single']);
      expect(singleRow.getOnlyIndex(1), ['row']);
      expect(singleRow.getOnlyIndex(2), ['data']);
    });
  });

  group('IsISBN TextInputFormatter', () {
    final formatter = IsISBN();
    const oldValue = TextEditingValue.empty;

    test('should allow valid input that meets criteria', () {
      final newValue = TextEditingValue(
        text: '123-456-7890-12-1',
      ); // 13 digits, 4 dashes
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, newValue.text);
    });

    test(
      'should allow input with fewer than 13 digits and fewer than 4 non-digits',
      () {
        final newValue = TextEditingValue(text: '123-45'); // 5 digits, 1 dash
        final result = formatter.formatEditUpdate(oldValue, newValue);
        expect(result.text, newValue.text);
      },
    );

    test('should return oldValue if numbers length exceeds 13', () {
      final newValue = TextEditingValue(text: '12345678901234'); // 14 digits
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result, oldValue);
    });

    test('should return oldValue if non-digit characters count exceeds 4', () {
      final newValue = TextEditingValue(
        text: '1-2-3-4-5-6',
      ); // 6 digits, 5 dashes (5 non-digits)
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result, oldValue);
    });

    test('should return oldValue if more than one X or x is present', () {
      final newValue1 = TextEditingValue(text: '123X456X789');
      expect(formatter.formatEditUpdate(oldValue, newValue1), oldValue);

      final newValue2 = TextEditingValue(text: '123x456x789');
      expect(formatter.formatEditUpdate(oldValue, newValue2), oldValue);

      final newValue3 = TextEditingValue(text: '123X456x789');
      expect(formatter.formatEditUpdate(oldValue, newValue3), oldValue);
    });

    test(
      'should convert x to X and push X to the end if it exists and is not at the end',
      () {
        final newValue = TextEditingValue(text: '123x456');
        final result = formatter.formatEditUpdate(oldValue, newValue);
        expect(result.text, '123456X');
      },
    );

    test('should push X to the end if it exists and is not at the end', () {
      final newValue = TextEditingValue(text: '123X456');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123456X');
    });

    test('should allow a single X at the end', () {
      final newValue = TextEditingValue(text: '123456X');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123456X');
    });

    test('should convert a single x at the end to X', () {
      final newValue = TextEditingValue(text: '123456x');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123456X');
    });

    test('should handle x conversion and push to end correctly', () {
      final newValue = TextEditingValue(text: '1x23');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123X');
    });

    test(
      'should maintain original text if no formatting rules for X/x apply',
      () {
        final newValue = TextEditingValue(text: '12345');
        final result = formatter.formatEditUpdate(oldValue, newValue);
        expect(result.text, '12345');
      },
    );

    test(
      'should correctly place cursor after x to X conversion when X is already at end',
      () {
        final initialText = '123x';
        final newValue = TextEditingValue(
          text: initialText,
          selection: TextSelection.collapsed(offset: initialText.length),
        );
        final result = formatter.formatEditUpdate(oldValue, newValue);
        expect(result.text, '123X');
      },
    );

    test('should correctly place cursor after pushing X to end', () {
      final initialText = '1X23';
      final newValue = TextEditingValue(
        text: initialText,
        selection: TextSelection.collapsed(offset: 2), // cursor after X
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123X');
    });
  });

  group('Format Validators from utils.dart', () {
    test('isISBN10 validates correctly', () {
      expect(isISBN10('0306406152'), isTrue);
      expect(isISBN10('0-306-40615-2'), isTrue);
      expect(isISBN10('030640615X'), isTrue);
      expect(isISBN10('0-306-40615-X'), isTrue);
      expect(isISBN10('030640615'), isFalse);
      expect(isISBN10('03064061521'), isFalse);
      expect(isISBN10('0-306-40615-Y'), isFalse);
    });

    test('isISBN13 validates correctly', () {
      expect(isISBN13('9780306406157'), isTrue);
      expect(isISBN13('978-0-306-40615-7'), isTrue);
      expect(isISBN13('978030640615'), isFalse);
      expect(isISBN13('97803064061577'), isFalse);
      expect(isISBN13('978-0-306-40615-X'), isFalse);
    });

    test('isISSN validates correctly', () {
      expect(isISSN('1234-5678'), isTrue);
      expect(isISSN('12345678'), isTrue);
      expect(isISSN('1234-567X'), isTrue);
      expect(isISSN('1234567X'), isTrue);
      expect(isISSN('1234-567'), isFalse);
      expect(isISSN('1234-56789'), isFalse);
    });
  });

  group('Regular Expression Validators from utils.dart', () {
    test('isbn10Regex validates ISBN-10 strings correctly', () {
      expect(
        isbn10Regex.hasMatch('0306406152'),
        isTrue,
        reason: "Compact 10-digit",
      );
      expect(
        isbn10Regex.hasMatch('0-306-40615-2'),
        isTrue,
        reason: "Hyphenated 10-digit",
      );
      expect(
        isbn10Regex.hasMatch('030640615X'),
        isTrue,
        reason: "Compact with X",
      );
      expect(
        isbn10Regex.hasMatch('0-306-40615-X'),
        isTrue,
        reason: "Hyphenated with X",
      );
      expect(
        isbn10Regex.hasMatch('12345-123-1X'),
        isTrue,
        reason: "Alternative hyphenation with X",
      );
      expect(
        isbn10Regex.hasMatch('0-123-45678-X'),
        isTrue,
        reason: "Full hyphenation example",
      );

      expect(
        isbn10Regex.hasMatch('030640615'),
        isFalse,
        reason: "Too short (9 digits)",
      );
      expect(
        isbn10Regex.hasMatch('03064061521'),
        isFalse,
        reason: "Too long (11 digits)",
      );
      expect(
        isbn10Regex.hasMatch('0-306-40615-Y'),
        isFalse,
        reason: "Invalid check digit 'Y'",
      );
      expect(
        isbn10Regex.hasMatch('0-306-40615-22'),
        isFalse,
        reason: "Too long, hyphenated",
      );
      expect(
        isbn10Regex.hasMatch('ABCDEFGHIJ'),
        isFalse,
        reason: "Non-numeric",
      );
      expect(
        isbn10Regex.hasMatch('1-2-3-4-5'),
        isFalse,
        reason: "Incorrect hyphenation pattern for 13-char rule",
      );
      expect(
        isbn10Regex.hasMatch('0-123-45678-99'),
        isFalse,
        reason: "Too long, last group too long",
      );
      expect(
        isbn10Regex.hasMatch('01234567890'),
        isFalse,
        reason: "Too many digits before check digit for compact form",
      );
    });

    test('isbn13Regex validates ISBN-13 strings correctly', () {
      expect(
        isbn13Regex.hasMatch('9780306406157'),
        isTrue,
        reason: "Compact 13-digit",
      );
      expect(
        isbn13Regex.hasMatch('978-0-306-40615-7'),
        isTrue,
        reason: "Hyphenated 13-digit",
      );
      expect(
        isbn13Regex.hasMatch('979-10-90639-1-3'),
        isTrue,
        reason: "979 prefix, hyphenated",
      );
      expect(
        isbn13Regex.hasMatch('978-123456789-0'),
        isFalse,
        reason: "Invalid hyphenation (2 hyphens, expected 0 or 4)",
      );

      expect(
        isbn13Regex.hasMatch('978030640615'),
        isFalse,
        reason: "Too short (12 digits)",
      );
      expect(
        isbn13Regex.hasMatch('97803064061577'),
        isFalse,
        reason: "Too long (14 digits)",
      );
      expect(
        isbn13Regex.hasMatch('978-0-306-40615-X'),
        isFalse,
        reason: "Invalid check digit 'X' for ISBN-13",
      );
      expect(
        isbn13Regex.hasMatch('123-030640615-7'),
        isFalse,
        reason: "Invalid prefix (not 978 or 979)",
      );
      expect(
        isbn13Regex.hasMatch('978030640615X'),
        isFalse,
        reason: "Compact with 'X' (invalid for ISBN-13)",
      );
      expect(
        isbn13Regex.hasMatch('ABCDEFGHJKLMN'),
        isFalse,
        reason: "Non-numeric",
      );
    });

    test('issnRegex validates ISSN strings correctly', () {
      expect(
        issnRegex.hasMatch('1234-5678'),
        isTrue,
        reason: "Hyphenated 8-digit",
      );
      expect(issnRegex.hasMatch('12345678'), isTrue, reason: "Compact 8-digit");
      expect(
        issnRegex.hasMatch('1234-567X'),
        isTrue,
        reason: "Hyphenated with X",
      );
      expect(issnRegex.hasMatch('1234567X'), isTrue, reason: "Compact with X");
      expect(
        issnRegex.hasMatch('1234-567x'),
        isTrue,
        reason: "Hyphenated with lowercase x",
      );
      expect(
        issnRegex.hasMatch('1234567x'),
        isTrue,
        reason: "Compact with lowercase x",
      );

      expect(
        issnRegex.hasMatch('1234-567'),
        isFalse,
        reason: "Too short, hyphenated (7 chars + hyphen)",
      );
      expect(
        issnRegex.hasMatch('1234567'),
        isFalse,
        reason: "Too short, compact (7 digits)",
      );
      expect(
        issnRegex.hasMatch('1234-56789'),
        isFalse,
        reason: "Too long, hyphenated",
      );
      expect(
        issnRegex.hasMatch('123456789'),
        isFalse,
        reason: "Too long, compact",
      );
      expect(
        issnRegex.hasMatch('1234-567Y'),
        isFalse,
        reason: "Invalid check digit 'Y'",
      );
      expect(
        issnRegex.hasMatch('ABCD-EFGH'),
        isFalse,
        reason: "Non-numeric with hyphen",
      );
      expect(
        issnRegex.hasMatch('1234567Z'),
        isFalse,
        reason: "Invalid check digit 'Z' compact",
      );
    });
  });

  // Add the following test groups:
  group('sortLibraries', () {
    test('should sort libraries by location alphabetically', () {
      final libraries = <Map<String, String>>[
        {'location': 'Library C', 'longitude': '0', 'latitude': '0'},
        {'location': 'Library A', 'longitude': '0', 'latitude': '0'},
        {'location': 'Library B', 'longitude': '0', 'latitude': '0'},
      ];
      // sortLibraries is now from utils.dart (imported at the top of the file)
      final sortedLibraries = sortLibraries(libraries);
      expect(
        sortedLibraries.map((lib) => lib['location']),
        orderedEquals(['Library A', 'Library B', 'Library C']),
      );
    });
  });

  group('Format Utilities', () {
    test('isValidFormat correctly identifies valid and invalid formats', () {
      // isValidFormat is now from utils.dart
      expect(isValidFormat('9781234567890'), isTrue, reason: 'Valid ISBN-13');
      expect(isValidFormat('123456789X'), isTrue, reason: 'Valid ISBN-10');
      expect(isValidFormat('1234-5678'), isTrue, reason: 'Valid ISSN');
      expect(
        isValidFormat('invalid-string'),
        isFalse,
        reason: 'Invalid format',
      );
      expect(isValidFormat(''), isFalse, reason: 'Empty string');
    });

    test('getFormat correctly identifies format type', () {
      // getFormat and Format enum are now from utils.dart
      expect(
        getFormat('9781234567890'),
        Format.isbn,
        reason: 'ISBN-13 should return Format.isbn',
      );
      expect(
        getFormat('123456789X'),
        Format.isbn,
        reason: 'ISBN-10 should return Format.isbn',
      );
      expect(
        getFormat('1234-5678'),
        Format.issn,
        reason: 'ISSN should return Format.issn',
      );
      expect(
        getFormat('invalid-string'),
        isNull,
        reason: 'Invalid string should return null',
      );
      expect(getFormat(''), isNull, reason: 'Empty string should return null');
    });

    test(
      'acceptedSearch contains correct validation functions from utils.dart',
      () {
        expect(acceptedSearch[0][1]('9780306406157'), isTrue); // isISBN13
        expect(
          acceptedSearch[0][1]('123456789'),
          isFalse,
        ); // isISBN13 with invalid input

        expect(acceptedSearch[1][1]('0306406152'), isTrue); // isISBN10
        expect(
          acceptedSearch[1][1]('12345678901'),
          isFalse,
        ); // isISBN10 with invalid input

        expect(acceptedSearch[2][1]('1234-5678'), isTrue); // isISSN
        expect(
          acceptedSearch[2][1]('1234-567A'),
          isFalse,
        ); // isISSN with invalid input
      },
    );

    test(
      'acceptedFormatFunction returns a list of correct validation functions',
      () {
        final functions = acceptedFormatFunction();

        // ISBN13
        expect(functions[0]('9780306406157'), isTrue);
        expect(functions[0]('12345'), isFalse);

        // ISBN10
        expect(functions[1]('0306406152'), isTrue);
        expect(functions[1]('12345'), isFalse);

        // ISSN
        expect(functions[2]('1234-5678'), isTrue);
        expect(functions[2]('1234-567A'), isFalse);
      },
    );
  });
}
