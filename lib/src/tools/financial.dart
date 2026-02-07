import 'package:mcp_dart/mcp_dart.dart';
import '../client/opendart_client.dart';

/// Registers financial-related tools (재무정보).
void registerFinancialTools(McpServer server, OpenDartClient client) {
  // ─── 단일회사 전체 재무제표 ───────────────────────────────
  server.tool(
    'get_financial_statements',
    description: '단일 회사의 전체 재무제표를 조회합니다. '
        '재무상태표, 손익계산서, 포괄손익계산서, 현금흐름표 등.',
    inputSchemaProperties: {
      'corp_code': {
        'type': 'string',
        'description': '고유번호 (8자리)',
      },
      'bsns_year': {
        'type': 'string',
        'description': '사업연도 (YYYY)',
      },
      'reprt_code': {
        'type': 'string',
        'description': '보고서 코드: 11013=1분기, 11012=반기, '
            '11014=3분기, 11011=사업보고서',
        'enum': ['11013', '11012', '11014', '11011'],
      },
      'fs_div': {
        'type': 'string',
        'description': '개별/연결 구분: OFS=재무제표(개별), CFS=연결재무제표. '
            '기본값: CFS',
        'enum': ['OFS', 'CFS'],
      },
    },
    inputSchemaRequired: ['corp_code', 'bsns_year', 'reprt_code'],
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args) async {
      try {
        final result = await client.get('fnlttSinglAll.json', params: {
          'corp_code': args['corp_code'] as String,
          'bsns_year': args['bsns_year'] as String,
          'reprt_code': args['reprt_code'] as String,
          'fs_div': (args['fs_div'] as String?) ?? 'CFS',
        });

        final list = result['list'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          return CallToolResult(
            content: [TextContent(text: '조회된 재무제표 데이터가 없습니다.')],
          );
        }

        final buffer = StringBuffer();
        final first = list.first;
        final fsDiv = first['fs_div'] == 'CFS' ? '연결' : '개별';
        buffer.writeln('📊 ${first['corp_name']} ${args['bsns_year']} '
            '${_reprtLabel(args['reprt_code'] as String)} ($fsDiv)');
        buffer.writeln('═══════════════════════════════════════');

        String? currentSj;
        for (final item in list) {
          final sjNm = item['sj_nm'] as String?;
          if (sjNm != currentSj) {
            currentSj = sjNm;
            buffer.writeln();
            buffer.writeln('▸ $sjNm');
            buffer.writeln('───────────────────────');
          }

          final name = item['account_nm'] ?? '';
          final current = _formatAmount(item['thstrm_amount']);
          final previous = _formatAmount(item['frmtrm_amount']);

          buffer.writeln('  $name');
          buffer.writeln('    당기: $current  |  전기: $previous');
        }

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } on OpenDartException catch (e) {
        return _errorResult(e);
      }
    },
  );

  // ─── 단일회사 주요계정 ────────────────────────────────────
  server.tool(
    'get_key_accounts',
    description: '단일 회사의 주요 계정과목(매출액, 영업이익, 당기순이익, '
        '자산총계, 부채총계, 자본총계 등)을 조회합니다.',
    inputSchemaProperties: {
      'corp_code': {
        'type': 'string',
        'description': '고유번호 (8자리)',
      },
      'bsns_year': {
        'type': 'string',
        'description': '사업연도 (YYYY)',
      },
      'reprt_code': {
        'type': 'string',
        'description': '보고서 코드: 11013=1분기, 11012=반기, '
            '11014=3분기, 11011=사업보고서',
        'enum': ['11013', '11012', '11014', '11011'],
      },
    },
    inputSchemaRequired: ['corp_code', 'bsns_year', 'reprt_code'],
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args) async {
      try {
        final result = await client.get('fnlttSinglAcnt.json', params: {
          'corp_code': args['corp_code'] as String,
          'bsns_year': args['bsns_year'] as String,
          'reprt_code': args['reprt_code'] as String,
        });

        final list = result['list'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          return CallToolResult(
            content: [TextContent(text: '조회된 주요계정 데이터가 없습니다.')],
          );
        }

        final buffer = StringBuffer();
        final first = list.first;
        buffer.writeln('📈 ${first['corp_name']} ${args['bsns_year']} '
            '${_reprtLabel(args['reprt_code'] as String)} 주요계정');
        buffer.writeln('═══════════════════════════════════════');

        for (final item in list) {
          final fsDiv = item['fs_div'] == 'CFS' ? '[연결]' : '[개별]';
          final name = item['account_nm'] ?? '';
          final current = _formatAmount(item['thstrm_amount']);
          final previous = _formatAmount(item['frmtrm_amount']);
          final beforePrev = _formatAmount(item['bfefrmtrm_amount']);

          buffer.writeln();
          buffer.writeln('$fsDiv $name');
          buffer.writeln('  당기: $current');
          buffer.writeln('  전기: $previous');
          buffer.writeln('  전전기: $beforePrev');
        }

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } on OpenDartException catch (e) {
        return _errorResult(e);
      }
    },
  );

  // ─── 다중회사 주요계정 비교 ───────────────────────────────
  server.tool(
    'compare_accounts',
    description: '여러 회사의 주요계정을 한번에 비교합니다. '
        '최대 동시에 여러 기업의 재무 데이터를 비교 분석할 수 있습니다.',
    inputSchemaProperties: {
      'corp_code': {
        'type': 'string',
        'description': '고유번호 (쉼표로 구분, 예: "00126380,00164779")',
      },
      'bsns_year': {
        'type': 'string',
        'description': '사업연도 (YYYY)',
      },
      'reprt_code': {
        'type': 'string',
        'description': '보고서 코드: 11013=1분기, 11012=반기, '
            '11014=3분기, 11011=사업보고서',
        'enum': ['11013', '11012', '11014', '11011'],
      },
    },
    inputSchemaRequired: ['corp_code', 'bsns_year', 'reprt_code'],
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args) async {
      try {
        final result = await client.get('fnlttMultiAcnt.json', params: {
          'corp_code': args['corp_code'] as String,
          'bsns_year': args['bsns_year'] as String,
          'reprt_code': args['reprt_code'] as String,
        });

        final list = result['list'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          return CallToolResult(
            content: [TextContent(text: '조회된 데이터가 없습니다.')],
          );
        }

        // Group by company
        final byCompany = <String, List<dynamic>>{};
        for (final item in list) {
          final name = item['corp_name'] as String? ?? '?';
          byCompany.putIfAbsent(name, () => []).add(item);
        }

        final buffer = StringBuffer();
        buffer.writeln('📊 기업간 주요계정 비교 (${args['bsns_year']} '
            '${_reprtLabel(args['reprt_code'] as String)})');
        buffer.writeln('═══════════════════════════════════════');

        for (final entry in byCompany.entries) {
          buffer.writeln();
          buffer.writeln('▸ ${entry.key}');
          buffer.writeln('───────────────────────');
          for (final item in entry.value) {
            if (item['fs_div'] != 'CFS') continue; // 연결 기준만 표시
            buffer.writeln('  ${item['account_nm']}: '
                '${_formatAmount(item['thstrm_amount'])}');
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

String _reprtLabel(String code) {
  switch (code) {
    case '11013':
      return '1분기';
    case '11012':
      return '반기';
    case '11014':
      return '3분기';
    case '11011':
      return '사업보고서';
    default:
      return code;
  }
}

String _formatAmount(dynamic amount) {
  if (amount == null || amount.toString().isEmpty || amount == '-') {
    return '-';
  }
  final str = amount.toString().replaceAll(',', '');
  final num = int.tryParse(str);
  if (num == null) return amount.toString();

  // Format with commas
  final formatted = num.abs().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );

  return num < 0 ? '-$formatted' : formatted;
}

CallToolResult _errorResult(OpenDartException e) {
  return CallToolResult(
    content: [TextContent(text: '❌ 오류: ${e.message}')],
    isError: true,
  );
}
