import 'package:mcp_dart/mcp_dart.dart';
import '../client/opendart_client.dart';

/// Registers disclosure-related tools (공시정보).
void registerDisclosureTools(McpServer server, OpenDartClient client) {
  // ─── 공시검색 ─────────────────────────────────────────────
  server.tool(
    'search_disclosure',
    description: '공시 목록을 검색합니다. '
        '기업명, 기간, 공시유형 등으로 필터링할 수 있습니다.',
    inputSchemaProperties: {
      'corp_code': {
        'type': 'string',
        'description': '고유번호 (8자리). corp_code 또는 corp_name 중 하나 입력',
      },
      'corp_name': {
        'type': 'string',
        'description': '회사명 (부분 검색 가능)',
      },
      'bgn_de': {
        'type': 'string',
        'description': '시작일 (YYYYMMDD). 기본값: 오늘 기준 1주일 전',
      },
      'end_de': {
        'type': 'string',
        'description': '종료일 (YYYYMMDD). 기본값: 오늘',
      },
      'last_reprt_at': {
        'type': 'string',
        'description': '최종보고서만 검색 (Y/N). 기본값: N',
        'enum': ['Y', 'N'],
      },
      'pblntf_ty': {
        'type': 'string',
        'description': '공시유형: A=정기공시, B=주요사항보고, '
            'C=발행공시, D=지분공시, E=기타공시, '
            'F=외부감사관련, G=펀드공시, H=자산유동화, '
            'I=거래소공시, J=공정위공시',
      },
      'page_no': {
        'type': 'string',
        'description': '페이지 번호 (기본값: 1)',
      },
      'page_count': {
        'type': 'string',
        'description': '페이지당 건수 (기본값: 10, 최대: 100)',
      },
    },
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args) async {
      try {
        final params = <String, String>{};
        _addIfPresent(params, 'corp_code', args['corp_code']);
        _addIfPresent(params, 'corp_name', args['corp_name']);
        _addIfPresent(params, 'bgn_de', args['bgn_de']);
        _addIfPresent(params, 'end_de', args['end_de']);
        _addIfPresent(params, 'last_reprt_at', args['last_reprt_at']);
        _addIfPresent(params, 'pblntf_ty', args['pblntf_ty']);
        _addIfPresent(params, 'page_no', args['page_no']);
        _addIfPresent(params, 'page_count', args['page_count']);

        final result = await client.get('list.json', params: params);

        final list = result['list'] as List<dynamic>? ?? [];
        final total = result['total_count'] ?? 0;
        final page = result['page_no'] ?? 1;
        final pageCount = result['page_count'] ?? 10;

        final buffer = StringBuffer();
        buffer.writeln('총 ${total}건 (페이지 $page, ${pageCount}건씩)');
        buffer.writeln('---');

        for (final item in list) {
          buffer.writeln('📄 ${item['corp_name']} | ${item['report_nm']}');
          buffer.writeln('   접수번호: ${item['rcept_no']}');
          buffer.writeln('   접수일: ${item['rcept_dt']}');
          buffer.writeln('   공시제출인: ${item['flr_nm']}');
          buffer.writeln();
        }

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } on OpenDartException catch (e) {
        return _errorResult(e);
      }
    },
  );

  // ─── 기업개황 ─────────────────────────────────────────────
  server.tool(
    'get_company',
    description: '기업 기본정보(기업개황)를 조회합니다. '
        '대표자명, 업종, 주소, 홈페이지, 결산월 등.',
    inputSchemaProperties: {
      'corp_code': {
        'type': 'string',
        'description': '고유번호 (8자리)',
      },
    },
    inputSchemaRequired: ['corp_code'],
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args) async {
      try {
        final result = await client.get('company.json', params: {
          'corp_code': args['corp_code'] as String,
        });

        final buffer = StringBuffer();
        buffer.writeln('🏢 ${result['corp_name']} (${result['stock_code'] ?? "비상장"})');
        buffer.writeln('─────────────────────');
        buffer.writeln('고유번호: ${result['corp_code']}');
        buffer.writeln('영문명: ${result['corp_name_eng']}');
        buffer.writeln('대표자: ${result['ceo_nm']}');
        buffer.writeln('법인구분: ${result['corp_cls']}');
        buffer.writeln('법인등록번호: ${result['jurir_no']}');
        buffer.writeln('사업자등록번호: ${result['bizr_no']}');
        buffer.writeln('업종코드: ${result['induty_code']}');
        buffer.writeln('설립일: ${result['est_dt']}');
        buffer.writeln('결산월: ${result['acc_mt']}');
        buffer.writeln('주소: ${result['adres']}');
        buffer.writeln('홈페이지: ${result['hm_url']}');
        buffer.writeln('전화번호: ${result['phn_no']}');
        buffer.writeln('IR: ${result['ir_url']}');

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } on OpenDartException catch (e) {
        return _errorResult(e);
      }
    },
  );

  // ─── 고유번호 조회 (회사명 → corp_code 변환) ─────────────
  server.tool(
    'search_corp_code',
    description: '회사명으로 고유번호(corp_code)를 검색합니다. '
        '다른 도구에서 corp_code가 필요할 때 먼저 이 도구를 사용하세요.',
    inputSchemaProperties: {
      'corp_name': {
        'type': 'string',
        'description': '검색할 회사명 (예: 삼성전자, SK하이닉스)',
      },
    },
    inputSchemaRequired: ['corp_name'],
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args) async {
      try {
        // Use disclosure search with corp_name to find corp_code
        final result = await client.get('list.json', params: {
          'corp_name': args['corp_name'] as String,
          'page_count': '5',
        });

        final list = result['list'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          return CallToolResult(
            content: [
              TextContent(text: '"${args['corp_name']}"에 해당하는 기업을 찾을 수 없습니다.')
            ],
          );
        }

        // Deduplicate by corp_code
        final seen = <String>{};
        final buffer = StringBuffer();
        buffer.writeln('🔍 "${args['corp_name']}" 검색 결과:');
        buffer.writeln();

        for (final item in list) {
          final code = item['corp_code'] as String;
          if (seen.add(code)) {
            final cls = _corpClsLabel(item['corp_cls'] as String?);
            buffer.writeln('  ${item['corp_name']} [$cls]');
            buffer.writeln('    corp_code: $code');
            buffer.writeln();
          }
        }

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } on OpenDartException catch (e) {
        return _errorResult(e);
      }
    },
  );
}

void _addIfPresent(Map<String, String> params, String key, dynamic value) {
  if (value != null && value.toString().isNotEmpty) {
    params[key] = value.toString();
  }
}

String _corpClsLabel(String? cls) {
  switch (cls) {
    case 'Y':
      return '유가증권';
    case 'K':
      return '코스닥';
    case 'N':
      return '코넥스';
    case 'E':
      return '기타';
    default:
      return cls ?? '?';
  }
}

CallToolResult _errorResult(OpenDartException e) {
  return CallToolResult(
    content: [TextContent(text: '❌ 오류: ${e.message}')],
    isError: true,
  );
}
