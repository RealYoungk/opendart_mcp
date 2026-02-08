import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:opendart_mcp/opendart_mcp.dart';
import 'package:opendart_mcp/src/tools/disclosure.dart';
import 'package:opendart_mcp/src/tools/financial.dart';
import 'package:test/test.dart';

void main() {
  group('Tool registration', () {
    test('registerDisclosureTools registers without error', () {
      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: MockClient((req) async => http.Response('{}', 200)),
      );
      final server = McpServer(
        Implementation(name: 'test', version: '0.0.1'),
        options: ServerOptions(
          capabilities: ServerCapabilities(tools: ServerCapabilitiesTools()),
        ),
      );
      registerDisclosureTools(server, client);
      // Should not throw
      expect(server, isNotNull);
    });

    test('registerFinancialTools registers without error', () {
      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: MockClient((req) async => http.Response('{}', 200)),
      );
      final server = McpServer(
        Implementation(name: 'test', version: '0.0.1'),
        options: ServerOptions(
          capabilities: ServerCapabilities(tools: ServerCapabilitiesTools()),
        ),
      );
      registerFinancialTools(server, client);
      // Should not throw
      expect(server, isNotNull);
    });
  });

  group('search_corp_code (corpCode.xml)', () {
    test('finds companies by Korean name', () async {
      final mockClient = MockClient((req) async {
        if (req.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(createMockCorpCodeZip(), 200);
        }
        return http.Response('{}', 200);
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final results = await client.searchCorpCode('삼성');
      expect(results.length, greaterThanOrEqualTo(2)); // 삼성전자, 삼성물산
      expect(results.any((c) => c.corpName == '삼성전자'), isTrue);
      expect(results.any((c) => c.corpName == '삼성물산'), isTrue);
    });

    test('finds companies by English name', () async {
      final mockClient = MockClient((req) async {
        if (req.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(createMockCorpCodeZip(), 200);
        }
        return http.Response('{}', 200);
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final results = await client.searchCorpCode('samsung');
      expect(results.length, greaterThanOrEqualTo(2));
      expect(results.any((c) => c.corpEngName?.contains('SAMSUNG') ?? false),
          isTrue);
    });

    test('returns empty list for unknown company', () async {
      final mockClient = MockClient((req) async {
        if (req.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(createMockCorpCodeZip(), 200);
        }
        return http.Response('{}', 200);
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final results = await client.searchCorpCode('존재하지않는회사12345');
      expect(results, isEmpty);
    });

    test('validates stock code presence', () async {
      final mockClient = MockClient((req) async {
        if (req.url.path.contains('corpCode.xml')) {
          return http.Response.bytes(createMockCorpCodeZip(), 200);
        }
        return http.Response('{}', 200);
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final results = await client.searchCorpCode('삼성전자');
      expect(results, isNotEmpty);
      final samsung = results.first;
      expect(samsung.isListed, isTrue);
      expect(samsung.stockCode, '005930');
    });
  });

  group('download tools', () {
    test('download_document returns correct metadata', () async {
      final mockBytes = utf8.encode('mock document content');
      final mockClient = MockClient((req) async {
        if (req.url.path.contains('document.xml')) {
          return http.Response.bytes(mockBytes, 200);
        }
        return http.Response('{}', 200);
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final bytes = await client.getBytes('document.xml', params: {
        'rcept_no': '20240001',
      });

      expect(bytes, equals(mockBytes));
      expect(bytes.length, greaterThan(0));
    });

    test('download_xbrl returns correct metadata', () async {
      final mockBytes = utf8.encode('mock xbrl content');
      final mockClient = MockClient((req) async {
        if (req.url.path.contains('fnlttXbrl.xml')) {
          return http.Response.bytes(mockBytes, 200);
        }
        return http.Response('{}', 200);
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final bytes = await client.getBytes('fnlttXbrl.xml', params: {
        'rcept_no': '20240001',
        'reprt_code': '11011',
      });

      expect(bytes, equals(mockBytes));
      expect(bytes.length, greaterThan(0));
    });
  });

  group('financial tools', () {
    test('get() parses financial statement response', () async {
      final mockResponse = jsonEncode({
        'status': '000',
        'message': '정상',
        'list': [
          {
            'rcept_no': '20240001',
            'corp_code': '00126380',
            'corp_name': '삼성전자',
            'sj_nm': '재무상태표',
            'account_nm': '자산총계',
            'thstrm_amount': '1000000',
            'frmtrm_amount': '900000',
            'fs_div': 'CFS',
          },
          {
            'rcept_no': '20240001',
            'corp_code': '00126380',
            'corp_name': '삼성전자',
            'sj_nm': '손익계산서',
            'account_nm': '매출액',
            'thstrm_amount': '500000',
            'frmtrm_amount': '450000',
            'fs_div': 'CFS',
          }
        ],
      });

      final mockClient = MockClient((req) async {
        if (req.url.path.contains('fnlttSinglAll.json')) {
          return http.Response.bytes(
            utf8.encode(mockResponse),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response.bytes(
          utf8.encode('{"status":"000","list":[]}'),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final result = await client.get('fnlttSinglAll.json', params: {
        'corp_code': '00126380',
        'bsns_year': '2024',
        'reprt_code': '11011',
        'fs_div': 'CFS',
      });

      expect(result['status'], '000');
      expect(result['list'], isList);
      final list = result['list'] as List;
      expect(list.length, 2);
      expect(list[0]['corp_name'], '삼성전자');
      expect(list[0]['account_nm'], '자산총계');
      expect(list[0]['thstrm_amount'], '1000000');
    });

    test('get() parses key accounts response', () async {
      final mockResponse = jsonEncode({
        'status': '000',
        'message': '정상',
        'list': [
          {
            'corp_code': '00126380',
            'corp_name': '삼성전자',
            'account_nm': '매출액',
            'thstrm_amount': '500000',
            'frmtrm_amount': '450000',
            'bfefrmtrm_amount': '400000',
            'fs_div': 'CFS',
          }
        ],
      });

      final mockClient = MockClient((req) async {
        if (req.url.path.contains('fnlttSinglAcnt.json')) {
          return http.Response.bytes(
            utf8.encode(mockResponse),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response.bytes(
          utf8.encode('{"status":"000","list":[]}'),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final result = await client.get('fnlttSinglAcnt.json', params: {
        'corp_code': '00126380',
        'bsns_year': '2024',
        'reprt_code': '11011',
      });

      expect(result['status'], '000');
      expect(result['list'], isList);
      final list = result['list'] as List;
      expect(list.length, 1);
      expect(list[0]['account_nm'], '매출액');
      expect(list[0]['thstrm_amount'], '500000');
      expect(list[0]['bfefrmtrm_amount'], '400000');
    });

    test('get() parses comparison response', () async {
      final mockResponse = jsonEncode({
        'status': '000',
        'message': '정상',
        'list': [
          {
            'corp_code': '00126380',
            'corp_name': '삼성전자',
            'account_nm': '매출액',
            'thstrm_amount': '500000',
            'fs_div': 'CFS',
          },
          {
            'corp_code': '00164779',
            'corp_name': 'SK하이닉스',
            'account_nm': '매출액',
            'thstrm_amount': '300000',
            'fs_div': 'CFS',
          }
        ],
      });

      final mockClient = MockClient((req) async {
        if (req.url.path.contains('fnlttMultiAcnt.json')) {
          return http.Response.bytes(
            utf8.encode(mockResponse),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response.bytes(
          utf8.encode('{"status":"000","list":[]}'),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final result = await client.get('fnlttMultiAcnt.json', params: {
        'corp_code': '00126380,00164779',
        'bsns_year': '2024',
        'reprt_code': '11011',
      });

      expect(result['status'], '000');
      expect(result['list'], isList);
      final list = result['list'] as List;
      expect(list.length, 2);
      expect(list[0]['corp_name'], '삼성전자');
      expect(list[1]['corp_name'], 'SK하이닉스');
    });

    test('get() handles API error status', () async {
      final mockResponse = jsonEncode({
        'status': '013',
        'message': '조회된 데이터가 없습니다',
      });

      final mockClient = MockClient((req) async {
        return http.Response.bytes(
          utf8.encode(mockResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      expect(
        () => client.get('fnlttSinglAll.json', params: {
          'corp_code': '99999999',
          'bsns_year': '2024',
          'reprt_code': '11011',
        }),
        throwsA(isA<OpenDartException>()),
      );
    });
  });

  group('disclosure tools', () {
    test('get() parses disclosure list response', () async {
      final mockResponse = jsonEncode({
        'status': '000',
        'message': '정상',
        'total_count': 2,
        'page_no': 1,
        'page_count': 10,
        'list': [
          {
            'corp_code': '00126380',
            'corp_name': '삼성전자',
            'rcept_no': '20240001',
            'rcept_dt': '20240101',
            'report_nm': '사업보고서',
            'flr_nm': '삼성전자',
          },
          {
            'corp_code': '00126380',
            'corp_name': '삼성전자',
            'rcept_no': '20240002',
            'rcept_dt': '20240102',
            'report_nm': '반기보고서',
            'flr_nm': '삼성전자',
          }
        ],
      });

      final mockClient = MockClient((req) async {
        if (req.url.path.contains('list.json')) {
          return http.Response.bytes(
            utf8.encode(mockResponse),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response.bytes(
          utf8.encode('{"status":"000","list":[]}'),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final result = await client.get('list.json', params: {
        'corp_code': '00126380',
        'bgn_de': '20240101',
        'end_de': '20240131',
      });

      expect(result['status'], '000');
      expect(result['total_count'], 2);
      expect(result['list'], isList);
      final list = result['list'] as List;
      expect(list.length, 2);
      expect(list[0]['corp_name'], '삼성전자');
      expect(list[0]['rcept_no'], '20240001');
    });

    test('get() parses company info response', () async {
      final mockResponse = jsonEncode({
        'status': '000',
        'message': '정상',
        'corp_code': '00126380',
        'corp_name': '삼성전자',
        'corp_name_eng': 'SAMSUNG ELECTRONICS CO.,LTD',
        'stock_code': '005930',
        'ceo_nm': '김철수',
        'corp_cls': 'Y',
        'jurir_no': '1234567890123',
        'bizr_no': '1234567890',
        'induty_code': '12345',
        'est_dt': '19690113',
        'acc_mt': '12',
        'adres': '서울특별시 강남구',
        'hm_url': 'https://www.samsung.com',
        'phn_no': '02-1234-5678',
        'ir_url': 'https://ir.samsung.com',
      });

      final mockClient = MockClient((req) async {
        if (req.url.path.contains('company.json')) {
          return http.Response.bytes(
            utf8.encode(mockResponse),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response.bytes(
          utf8.encode('{"status":"000"}'),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final client = OpenDartClient(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final result = await client.get('company.json', params: {
        'corp_code': '00126380',
      });

      expect(result['status'], '000');
      expect(result['corp_name'], '삼성전자');
      expect(result['stock_code'], '005930');
      expect(result['ceo_nm'], '김철수');
      expect(result['hm_url'], 'https://www.samsung.com');
    });
  });
}

/// Creates a mock ZIP file containing CORPCODE.xml with sample data.
List<int> createMockCorpCodeZip() {
  final xmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
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
  final data = utf8.encode(xmlContent);
  archive.addFile(ArchiveFile('CORPCODE.xml', data.length, data));
  return ZipEncoder().encode(archive);
}
