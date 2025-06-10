import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:easy_loc/functions/api.dart';

void main() {
  group('API Utility Functions from api.dart', () {
    late MockClient mockClient;

    group('getAPI', () {
      test('returns decoded JSON for successful response (200)', () async {
        mockClient = MockClient((request) async {
          expect(request.url.toString(), 'http://example.com/data');
          expect(request.headers['Accept'], 'text/json');
          return http.Response(jsonEncode({'key': 'value'}), 200);
        });

        final response = await getAPI(
          'http://example.com/data',
          client: mockClient,
        );
        expect(response, {'key': 'value'});
      });

      test('returns decoded JSON for 404 response with JSON body', () async {
        mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'error': 'not found'}), 404);
        });
        final response = await getAPI(
          'http://example.com/notfound',
          client: mockClient,
        );
        expect(response, {'error': 'not found'});
      });

      test(
        'throws FormatException for 404 response with non-JSON body',
        () async {
          mockClient = MockClient((request) async {
            return http.Response('Not Found Text', 404);
          });
          expect(
            () => getAPI('http://example.com/notfoundtext', client: mockClient),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test(
        'throws exception for other error status codes (e.g., 500)',
        () async {
          mockClient = MockClient((request) async {
            return http.Response('Server Error', 500);
          });
          expect(
            () => getAPI('http://example.com/error', client: mockClient),
            throwsException,
          );
        },
      );
    });

    group('isbn2ppn', () {
      test(
        'returns list of PPNs for valid ISBN with multiple results',
        () async {
          mockClient = MockClient((request) async {
            expect(
              request.url.toString(),
              '${isbn2ppnEndpoint}valid-isbn-multi',
            );
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': [
                      {'ppn': '123'},
                      {'ppn': '456'},
                    ],
                  },
                },
              }),
              200,
            );
          });
          final result = await isbn2ppn('valid-isbn-multi', client: mockClient);
          expect(result, [
            {'ppn': '123'},
            {'ppn': '456'},
          ]);
        },
      );

      test(
        'returns list with single PPN for valid ISBN with single result (map)',
        () async {
          mockClient = MockClient((request) async {
            expect(
              request.url.toString(),
              '${isbn2ppnEndpoint}valid-isbn-single',
            );
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': {'ppn': '789'},
                  },
                },
              }),
              200,
            );
          });
          final result = await isbn2ppn(
            'valid-isbn-single',
            client: mockClient,
          );
          expect(result, [
            {'ppn': '789'},
          ]);
        },
      );

      test(
        'returns empty list if API response indicates no PPN found (empty result list)',
        () async {
          mockClient = MockClient((request) async {
            expect(request.url.toString(), '${isbn2ppnEndpoint}isbn-no-result');
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {'result': []},
                },
              }),
              200,
            );
          });
          final result = await isbn2ppn('isbn-no-result', client: mockClient);
          expect(result, isEmpty);
        },
      );

      test('returns null if API response result field is missing', () async {
        mockClient = MockClient((request) async {
          expect(
            request.url.toString(),
            '${isbn2ppnEndpoint}isbn-null-result-field',
          );
          return http.Response(
            jsonEncode({
              'sudoc': {'query': {}},
            }),
            200,
          );
        });
        final result = await isbn2ppn(
          'isbn-null-result-field',
          client: mockClient,
        );
        expect(result, isNull);
      });

      test('returns null on API error (getAPI throws)', () async {
        mockClient = MockClient((request) async {
          expect(request.url.toString(), '${isbn2ppnEndpoint}isbn-api-error');
          return http.Response('Server Error', 500);
        });
        final result = await isbn2ppn('isbn-api-error', client: mockClient);
        expect(result, isNull);
      });
    });

    group('issn2ppn', () {
      test(
        'returns list of PPNs for valid ISSN with multiple results',
        () async {
          mockClient = MockClient((request) async {
            expect(
              request.url.toString(),
              '${issn2ppnEndpoint}valid-issn-multi',
            );
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': [
                      {'ppn': 'issn123'},
                      {'ppn': 'issn456'},
                    ],
                  },
                },
              }),
              200,
            );
          });
          final result = await issn2ppn('valid-issn-multi', client: mockClient);
          expect(result, [
            {'ppn': 'issn123'},
            {'ppn': 'issn456'},
          ]);
        },
      );

      test(
        'returns list with single PPN for valid ISSN with single result (map)',
        () async {
          mockClient = MockClient((request) async {
            expect(
              request.url.toString(),
              '${issn2ppnEndpoint}valid-issn-single',
            );
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': {'ppn': 'issn789'},
                  },
                },
              }),
              200,
            );
          });
          final result = await issn2ppn(
            'valid-issn-single',
            client: mockClient,
          );
          expect(result, [
            {'ppn': 'issn789'},
          ]);
        },
      );

      test('returns null on API error', () async {
        mockClient = MockClient((request) async {
          expect(request.url.toString(), '${issn2ppnEndpoint}issn-api-error');
          return http.Response('Server Error', 500);
        });
        final result = await issn2ppn('issn-api-error', client: mockClient);
        expect(result, isNull);
      });
    });

    group('multiwhere', () {
      test('fetches and processes libraries for multiple PPNs', () async {
        mockClient = MockClient((request) async {
          if (request.url.toString() == '${multiwhereEndpoint}ppn1') {
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': {
                      'library': [
                        {
                          'shortname': 'Lib A',
                          'longitude': '1.0',
                          'latitude': '2.0',
                        },
                        {
                          'shortname': 'Lib B',
                          'longitude': '3.0',
                          'latitude': '4.0',
                        },
                      ],
                    },
                  },
                },
              }),
              200,
            );
          } else if (request.url.toString() == '${multiwhereEndpoint}ppn2') {
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': {
                      'library': {
                        'shortname': 'Lib C',
                        'longitude': '5.0',
                        'latitude': '6.0',
                      },
                    },
                  },
                },
              }),
              200,
            );
          } else if (request.url.toString() == '${multiwhereEndpoint}ppn3') {
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {'result': {}},
                },
              }),
              200,
            );
          } else if (request.url.toString() == '${multiwhereEndpoint}ppn4') {
            return http.Response('Error for PPN4', 500);
          }
          return http.Response('Not Found for ${request.url}', 404);
        });

        final ppnList = [
          {'ppn': 'ppn1'},
          {'ppn': 'ppn2'},
          {'ppn': 'ppn3'},
          {'ppn': 'ppn4'},
          {'ppn': null},
        ];
        final results = await multiwhere(
          ppnList
              .where((p) => p['ppn'] != null)
              .cast<Map<String, String>>()
              .toList(),
          client: mockClient,
        );

        expect(results.length, 3);

        final resPpn1 = results.firstWhere((r) => r['ppn'] == 'ppn1');
        expect(resPpn1['libraries'], [
          {'location': 'Lib A', 'longitude': '1.0', 'latitude': '2.0'},
          {'location': 'Lib B', 'longitude': '3.0', 'latitude': '4.0'},
        ]);

        final resPpn2 = results.firstWhere((r) => r['ppn'] == 'ppn2');
        expect(resPpn2['libraries'], [
          {'location': 'Lib C', 'longitude': '5.0', 'latitude': '6.0'},
        ]);

        final resPpn3 = results.firstWhere((r) => r['ppn'] == 'ppn3');
        expect(resPpn3['libraries'], isEmpty);
      });

      test('handles empty PPN list input', () async {
        mockClient = MockClient(
          (request) async => fail("Should not be called"),
        );
        final results = await multiwhere([], client: mockClient);
        expect(results, isEmpty);
      });

      test(
        'handles library items not being maps and filters them out',
        () async {
          mockClient = MockClient((request) async {
            if (request.url.toString() ==
                '${multiwhereEndpoint}ppn-mixed-libs') {
              return http.Response(
                jsonEncode({
                  'sudoc': {
                    'query': {
                      'result': {
                        'library': [
                          {
                            'shortname': 'Lib Valid1',
                            'longitude': '1.0',
                            'latitude': '2.0',
                          },
                          "a string instead of a map",
                          {
                            'shortname': 'Lib Valid2',
                            'longitude': '3.0',
                            'latitude': '4.0',
                          },
                          null,
                        ],
                      },
                    },
                  },
                }),
                200,
              );
            }
            return http.Response('Not Found', 404);
          });
          final results = await multiwhere(
            [
              {'ppn': 'ppn-mixed-libs'},
            ].cast<Map<String, String>>(),
            client: mockClient,
          );
          expect(results.length, 1);
          expect(results[0]['libraries'], [
            {'location': 'Lib Valid1', 'longitude': '1.0', 'latitude': '2.0'},
            {'location': 'Lib Valid2', 'longitude': '3.0', 'latitude': '4.0'},
          ]);
        },
      );

      test('handles API error for one PPN among many', () async {
        mockClient = MockClient((request) async {
          if (request.url.toString() == '${multiwhereEndpoint}ppn-good1') {
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': {
                      'library': [
                        {
                          'shortname': 'Lib A',
                          'longitude': '1.0',
                          'latitude': '2.0',
                        },
                      ],
                    },
                  },
                },
              }),
              200,
            );
          } else if (request.url.toString() == '${multiwhereEndpoint}ppn-bad') {
            return http.Response('Simulated Error', 500);
          } else if (request.url.toString() ==
              '${multiwhereEndpoint}ppn-good2') {
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': {
                      'library': [
                        {
                          'shortname': 'Lib C',
                          'longitude': '5.0',
                          'latitude': '6.0',
                        },
                      ],
                    },
                  },
                },
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final ppnList = [
          {'ppn': 'ppn-good1'},
          {'ppn': 'ppn-bad'},
          {'ppn': 'ppn-good2'},
        ];
        final results = await multiwhere(
          ppnList
              .where((p) => p['ppn'] != null)
              .cast<Map<String, String>>()
              .toList(),
          client: mockClient,
        );

        expect(results.length, 2);

        final resPpn1 = results.firstWhere((r) => r['ppn'] == 'ppn-good1');
        expect(resPpn1['libraries'], [
          {'location': 'Lib A', 'longitude': '1.0', 'latitude': '2.0'},
        ]);

        final resPpn2 = results.firstWhere((r) => r['ppn'] == 'ppn-good2');
        expect(resPpn2['libraries'], [
          {'location': 'Lib C', 'longitude': '5.0', 'latitude': '6.0'},
        ]);
      });

      test('handles empty library list from API', () async {
        mockClient = MockClient((request) async {
          if (request.url.toString() == '${multiwhereEndpoint}ppn-empty-libs') {
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': {'library': []},
                  },
                },
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final ppnList = [
          {'ppn': 'ppn-empty-libs'},
        ];
        final results = await multiwhere(
          ppnList
              .where((p) => p['ppn'] != null)
              .cast<Map<String, String>>()
              .toList(),
          client: mockClient,
        );

        expect(results.length, 1);
        expect(results[0]['libraries'], isEmpty);
      });

      test('handles library data not being a list or map', () async {
        mockClient = MockClient((request) async {
          if (request.url.toString() ==
              '${multiwhereEndpoint}ppn-invalid-lib-type') {
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': {'library': "string instead of list or map"},
                  },
                },
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final ppnList = [
          {'ppn': 'ppn-invalid-lib-type'},
        ];
        final results = await multiwhere(
          ppnList
              .where((p) => p['ppn'] != null)
              .cast<Map<String, String>>()
              .toList(),
          client: mockClient,
        );

        expect(results.length, 1);
        expect(results[0]['libraries'], isEmpty);
      });

      test('handles missing fields in library data', () async {
        mockClient = MockClient((request) async {
          if (request.url.toString() ==
              '${multiwhereEndpoint}ppn-missing-fields') {
            return http.Response(
              jsonEncode({
                'sudoc': {
                  'query': {
                    'result': {
                      'library': [
                        {'shortname': 'Lib A'},
                        {'longitude': '3.0', 'latitude': '4.0'},
                      ],
                    },
                  },
                },
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final ppnList = [
          {'ppn': 'ppn-missing-fields'},
        ];
        final results = await multiwhere(
          ppnList
              .where((p) => p['ppn'] != null)
              .cast<Map<String, String>>()
              .toList(),
          client: mockClient,
        );

        expect(results.length, 1);
        expect(results[0]['libraries'], isEmpty);
      });
    });

    group('unimarc', () {
      test(
        'parses XML response and extracts datafield 200 subfields',
        () async {
          mockClient = MockClient((request) async {
            expect(request.url.toString(), '${unimarcEndpoint}test-ppn.xml');
            return http.Response('''<?xml version="1.0" encoding="UTF-8"?>
<record>
  <datafield tag="200" ind1=" " ind2=" ">
    <subfield code="a">Title A</subfield>
    <subfield code="c">Author A</subfield>
    <subfield code="d">Publisher A</subfield>
  </datafield>
  <datafield tag="200" ind1=" " ind2=" ">
    <subfield code="a">Title B</subfield>
    <subfield code="e">Edition B</subfield>
  </datafield>
  <datafield tag="300" ind1=" " ind2=" ">
    <subfield code="a">This should be ignored</subfield>
  </datafield>
</record>''', 200);
          });

          final result = await unimarc('test-ppn', client: mockClient);

          expect(result, {
            'a': ['Title A', 'Title B'],
            'c': ['Author A'],
            'd': ['Publisher A'],
            'e': ['Edition B'],
          });
        },
      );

      test('handles empty XML response', () async {
        mockClient = MockClient((request) async {
          expect(request.url.toString(), '${unimarcEndpoint}empty-ppn.xml');
          return http.Response('''<?xml version="1.0" encoding="UTF-8"?>
<record>
</record>''', 200);
        });

        final result = await unimarc('empty-ppn', client: mockClient);
        expect(result, {});
      });

      test('handles XML with no datafield 200', () async {
        mockClient = MockClient((request) async {
          expect(request.url.toString(), '${unimarcEndpoint}no-200-ppn.xml');
          return http.Response('''<?xml version="1.0" encoding="UTF-8"?>
<record>
  <datafield tag="300" ind1=" " ind2=" ">
    <subfield code="a">Other field</subfield>
  </datafield>
</record>''', 200);
        });

        final result = await unimarc('no-200-ppn', client: mockClient);
        expect(result, {});
      });

      test('filters out empty subfield text', () async {
        mockClient = MockClient((request) async {
          expect(
            request.url.toString(),
            '${unimarcEndpoint}empty-text-ppn.xml',
          );
          return http.Response('''<?xml version="1.0" encoding="UTF-8"?>
<record>
  <datafield tag="200" ind1=" " ind2=" ">
    <subfield code="a">Valid Text</subfield>
    <subfield code="b"></subfield>
    <subfield code="c">Another Valid Text</subfield>
  </datafield>
</record>''', 200);
        });

        final result = await unimarc('empty-text-ppn', client: mockClient);
        expect(result, {
          'a': ['Valid Text'],
          'c': ['Another Valid Text'],
        });
      });

      test('returns null on API error', () async {
        mockClient = MockClient((request) async {
          expect(request.url.toString(), '${unimarcEndpoint}error-ppn.xml');
          return http.Response('Server Error', 500);
        });

        final result = await unimarc('error-ppn', client: mockClient);
        expect(result, isNull);
      });

      test('returns null on XML parsing error', () async {
        mockClient = MockClient((request) async {
          expect(
            request.url.toString(),
            '${unimarcEndpoint}invalid-xml-ppn.xml',
          );
          return http.Response('Invalid XML content', 200);
        });

        final result = await unimarc('invalid-xml-ppn', client: mockClient);
        expect(result, isNull);
      });
    });
  });
}
