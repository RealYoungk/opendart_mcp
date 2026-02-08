import 'dart:async';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opendart_mcp/opendart_mcp.dart';
import 'package:test/test.dart';

void main() {
  group('OpenDartClient.get()', () {
    test('successfully parses JSON response with status 000', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': '000',
            'message': 'success',
            'data': 'test_data',
          }),
          200,
        );
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      final result = await client.get('test_endpoint');

      expect(result['status'], '000');
      expect(result['message'], 'success');
      expect(result['data'], 'test_data');

      client.close();
    });

    test('injects API key as crtfc_key query parameter', () async {
      String? capturedUrl;

      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(
          jsonEncode({'status': '000'}),
          200,
        );
      });

      final client = OpenDartClient(
        apiKey: 'my_api_key',
        httpClient: mockClient,
      );

      await client.get('test_endpoint');

      expect(capturedUrl, contains('crtfc_key=my_api_key'));

      client.close();
    });

    test('passes additional params', () async {
      String? capturedUrl;

      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(
          jsonEncode({'status': '000'}),
          200,
        );
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      await client.get('test_endpoint', params: {
        'corp_code': '00126380',
        'bgn_de': '20240101',
      });

      expect(capturedUrl, contains('corp_code=00126380'));
      expect(capturedUrl, contains('bgn_de=20240101'));

      client.close();
    });

    test('throws OpenDartException on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      expect(
        () => client.get('test_endpoint'),
        throwsA(isA<OpenDartException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', contains('HTTP 500'))),
      );

      client.close();
    });

    test('throws OpenDartException on OpenDART status error', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'status': '013',
          'message': '조회된 데이터가 없습니다',
        });
        return http.Response(body, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      expect(
        () => client.get('test_endpoint'),
        throwsA(isA<OpenDartException>()
            .having((e) => e.dartStatus, 'dartStatus', '013')
            .having((e) => e.message, 'message', '조회된 데이터가 없습니다')),
      );

      client.close();
    });

    test('uses correct status message from dartStatus field', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'status': '010',
          'message': null,
        });
        return http.Response(body, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      expect(
        () => client.get('test_endpoint'),
        throwsA(isA<OpenDartException>()
            .having((e) => e.dartStatus, 'dartStatus', '010')
            .having((e) => e.message, 'message', '등록되지 않은 키입니다')),
      );

      client.close();
    });
  });

  group('OpenDartClient.getBytes()', () {
    test('successfully returns raw bytes', () async {
      final testBytes = [1, 2, 3, 4, 5];

      final mockClient = MockClient((request) async {
        return http.Response.bytes(testBytes, 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      final result = await client.getBytes('test_endpoint');

      expect(result, equals(testBytes));

      client.close();
    });

    test('throws OpenDartException on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      expect(
        () => client.getBytes('test_endpoint'),
        throwsA(isA<OpenDartException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', contains('HTTP 404'))),
      );

      client.close();
    });
  });

  group('Rate limiting', () {
    test('allows requests under the limit', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
        maxRequestsPerDay: 5,
      );

      // Should succeed for first 5 requests
      for (int i = 0; i < 5; i++) {
        await client.get('test_endpoint');
      }

      expect(client.requestCount, 5);

      client.close();
    });

    test('throws OpenDartException with dartStatus 020 when limit exceeded',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
        maxRequestsPerDay: 3,
      );

      // Make 3 requests
      for (int i = 0; i < 3; i++) {
        await client.get('test_endpoint');
      }

      // 4th request should fail
      expect(
        () => client.get('test_endpoint'),
        throwsA(isA<OpenDartException>()
            .having((e) => e.dartStatus, 'dartStatus', '020')
            .having((e) => e.message, 'message', contains('요청 제한을 초과했습니다'))),
      );

      client.close();
    });

    test('requestCount getter returns correct count', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
        maxRequestsPerDay: 10,
      );

      expect(client.requestCount, 0);

      await client.get('test_endpoint');
      expect(client.requestCount, 1);

      await client.get('test_endpoint');
      expect(client.requestCount, 2);

      await client.get('test_endpoint');
      expect(client.requestCount, 3);

      client.close();
    });
  });

  group('Timeout', () {
    test('throws OpenDartException when request times out', () async {
      final mockClient = MockClient((request) async {
        // Simulate a slow response
        await Future.delayed(const Duration(milliseconds: 200));
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
        timeout: const Duration(milliseconds: 50), // Short timeout
      );

      expect(
        () => client.get('test_endpoint'),
        throwsA(isA<OpenDartException>().having(
          (e) => e.message,
          'message',
          contains('Request timeout'),
        )),
      );

      client.close();
    });
  });

  group('Corp code cache', () {
    List<int> createMockCorpCodeZip() {
      const xmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<result>
  <list>
    <corp_code>00126380</corp_code>
    <corp_name>삼성전자</corp_name>
    <corp_eng_name>SAMSUNG ELECTRONICS CO.,LTD</corp_eng_name>
    <stock_code>005930</stock_code>
    <modify_date>20240101</modify_date>
  </list>
  <list>
    <corp_code>00164779</corp_code>
    <corp_name>SK하이닉스</corp_name>
    <corp_eng_name>SK hynix Inc.</corp_eng_name>
    <stock_code>000660</stock_code>
    <modify_date>20240101</modify_date>
  </list>
  <list>
    <corp_code>00999999</corp_code>
    <corp_name>삼성물산</corp_name>
    <corp_eng_name>Samsung C&amp;T Corporation</corp_eng_name>
    <stock_code>028260</stock_code>
    <modify_date>20240101</modify_date>
  </list>
</result>''';

      final archive = Archive();
      archive.addFile(ArchiveFile(
        'CORPCODE.xml',
        utf8.encode(xmlContent).length,
        utf8.encode(xmlContent),
      ));
      return ZipEncoder().encode(archive);
    }

    test('getCorpCodes() loads and parses correctly', () async {
      final zipBytes = createMockCorpCodeZip();
      int requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (request.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(zipBytes, 200);
        }
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      final corps = await client.getCorpCodes();

      expect(corps.length, 3);
      expect(corps[0].corpCode, '00126380');
      expect(corps[0].corpName, '삼성전자');
      expect(corps[0].corpEngName, 'SAMSUNG ELECTRONICS CO.,LTD');
      expect(corps[0].stockCode, '005930');
      expect(corps[1].corpCode, '00164779');
      expect(corps[1].corpName, 'SK하이닉스');
      expect(corps[2].corpCode, '00999999');
      expect(corps[2].corpName, '삼성물산');
      expect(requestCount, 1);

      client.close();
    });

    test('searchCorpCode() returns matching companies - Korean', () async {
      final zipBytes = createMockCorpCodeZip();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(zipBytes, 200);
        }
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      final results = await client.searchCorpCode('삼성');

      expect(results.length, 2);
      expect(results[0].corpName, '삼성전자');
      expect(results[1].corpName, '삼성물산');

      client.close();
    });

    test('searchCorpCode() searches English name', () async {
      final zipBytes = createMockCorpCodeZip();

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(zipBytes, 200);
        }
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      final results = await client.searchCorpCode('hynix');

      expect(results.length, 1);
      expect(results[0].corpName, 'SK하이닉스');
      expect(results[0].corpEngName, 'SK hynix Inc.');

      client.close();
    });

    test('cache is reused (second call does not make HTTP request)', () async {
      final zipBytes = createMockCorpCodeZip();
      int requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (request.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(zipBytes, 200);
        }
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      // First call - should make HTTP request
      final corps1 = await client.getCorpCodes();
      expect(corps1.length, 3);
      expect(requestCount, 1);

      // Second call - should use cache
      final corps2 = await client.getCorpCodes();
      expect(corps2.length, 3);
      expect(requestCount, 1); // No additional request

      // Verify same instance
      expect(identical(corps1, corps2), true);

      client.close();
    });

    test('clearCorpCodeCache() forces reload', () async {
      final zipBytes = createMockCorpCodeZip();
      int requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (request.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(zipBytes, 200);
        }
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      // First call
      await client.getCorpCodes();
      expect(requestCount, 1);

      // Clear cache
      client.clearCorpCodeCache();

      // Second call - should make new HTTP request
      await client.getCorpCodes();
      expect(requestCount, 2);

      client.close();
    });

    test('searchCorpCode() uses cache', () async {
      final zipBytes = createMockCorpCodeZip();
      int requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (request.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(zipBytes, 200);
        }
        return http.Response(jsonEncode({'status': '000'}), 200);
      });

      final client = OpenDartClient(
        apiKey: 'test_key',
        httpClient: mockClient,
      );

      // First search - should load cache
      await client.searchCorpCode('삼성');
      expect(requestCount, 1);

      // Second search - should use cache
      await client.searchCorpCode('SK');
      expect(requestCount, 1); // No additional request

      client.close();
    });
  });
}
