import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import '../client/opendart_client.dart';
import 'helpers.dart';

/// Registers financial-related tools (재무정보).
void registerFinancialTools(McpServer server, OpenDartClient client) {
  // ─── 단일회사 전체 재무제표 ───────────────────────────────
  server.registerTool(
    'get_financial_statements',
    description: '단일 회사의 전체 재무제표를 조회합니다. '
        '재무상태표, 손익계산서, 포괄손익계산서, 현금흐름표 등.',
    inputSchema: ToolInputSchema.fromJson({
      'properties': {
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
      'required': ['corp_code', 'bsns_year', 'reprt_code'],
    }),
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) async {
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
            '${reprtLabel(args['reprt_code'] as String)} ($fsDiv)');
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
          final current = formatAmount(item['thstrm_amount']);
          final previous = formatAmount(item['frmtrm_amount']);

          buffer.writeln('  $name');
          buffer.writeln('    당기: $current  |  전기: $previous');
        }

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } on OpenDartException catch (e) {
        return errorResult(e);
      }
    },
  );

  // ─── 단일회사 주요계정 ────────────────────────────────────
  server.registerTool(
    'get_key_accounts',
    description: '단일 회사의 주요 계정과목(매출액, 영업이익, 당기순이익, '
        '자산총계, 부채총계, 자본총계 등)을 조회합니다.',
    inputSchema: ToolInputSchema.fromJson({
      'properties': {
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
      'required': ['corp_code', 'bsns_year', 'reprt_code'],
    }),
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) async {
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
            '${reprtLabel(args['reprt_code'] as String)} 주요계정');
        buffer.writeln('═══════════════════════════════════════');

        for (final item in list) {
          final fsDiv = item['fs_div'] == 'CFS' ? '[연결]' : '[개별]';
          final name = item['account_nm'] ?? '';
          final current = formatAmount(item['thstrm_amount']);
          final previous = formatAmount(item['frmtrm_amount']);
          final beforePrev = formatAmount(item['bfefrmtrm_amount']);

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
        return errorResult(e);
      }
    },
  );

  // ─── 다중회사 주요계정 비교 ───────────────────────────────
  server.registerTool(
    'compare_accounts',
    description: '여러 회사의 주요계정을 한번에 비교합니다. '
        '최대 동시에 여러 기업의 재무 데이터를 비교 분석할 수 있습니다.',
    inputSchema: ToolInputSchema.fromJson({
      'properties': {
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
      'required': ['corp_code', 'bsns_year', 'reprt_code'],
    }),
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) async {
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
            '${reprtLabel(args['reprt_code'] as String)})');
        buffer.writeln('═══════════════════════════════════════');

        for (final entry in byCompany.entries) {
          buffer.writeln();
          buffer.writeln('▸ ${entry.key}');
          buffer.writeln('───────────────────────');
          for (final item in entry.value) {
            if (item['fs_div'] != 'CFS') continue; // 연결 기준만 표시
            buffer.writeln('  ${item['account_nm']}: '
                '${formatAmount(item['thstrm_amount'])}');
          }
        }

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } on OpenDartException catch (e) {
        return errorResult(e);
      }
    },
  );

  // ─── 재무제표 원본파일(XBRL) ────────────────────────────────
  server.registerTool(
    'download_xbrl',
    description: '재무제표 원본파일(XBRL)을 다운로드합니다.',
    inputSchema: ToolInputSchema.fromJson({
      'properties': {
        'rcept_no': {
          'type': 'string',
          'description': '접수번호 (14자리)',
        },
        'reprt_code': {
          'type': 'string',
          'description': '보고서 코드: 11013=1분기, 11012=반기, 11014=3분기, 11011=사업보고서',
          'enum': ['11013', '11012', '11014', '11011'],
        },
      },
      'required': ['rcept_no', 'reprt_code'],
    }),
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) async {
      try {
        final rceptNo = args['rcept_no'] as String;
        final bytes = await client.getBytes('fnlttXbrl.xml', params: {
          'rcept_no': rceptNo,
          'reprt_code': args['reprt_code'] as String,
        });

        final buffer = StringBuffer();
        buffer.writeln('📥 XBRL 재무제표 원본파일 다운로드 완료');
        buffer.writeln('═══════════════════════════════════════');
        buffer.writeln('접수번호: $rceptNo');
        buffer.writeln('파일크기: ${bytes.length} bytes');

        return CallToolResult(
          content: [
            TextContent(text: buffer.toString()),
            EmbeddedResource(
              resource: BlobResourceContents(
                uri: 'opendart://xbrl/$rceptNo',
                mimeType: 'application/zip',
                blob: base64Encode(bytes),
              ),
            ),
          ],
        );
      } on OpenDartException catch (e) {
        return errorResult(e);
      }
    },
  );

  // ─── XBRL택사노미재무제표양식 ──────────────────────────────
  server.registerTool(
    'get_xbrl_taxonomy',
    description: 'XBRL택사노미 재무제표양식(표준계정과목체계)을 조회합니다.',
    inputSchema: ToolInputSchema.fromJson({
      'properties': {
        'sj_div': {
          'type': 'string',
          'description': '재무제표구분: BS=재무상태표, IS=손익계산서, '
              'CIS=포괄손익계산서, CF=현금흐름표, SCE=자본변동표',
          'enum': ['BS', 'IS', 'CIS', 'CF', 'SCE'],
        },
      },
      'required': ['sj_div'],
    }),
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) async {
      try {
        final result = await client.get('xbrlTaxonomy.json', params: {
          'sj_div': args['sj_div'] as String,
        });

        final list = result['list'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          return CallToolResult(
            content: [TextContent(text: '조회된 데이터가 없습니다.')],
          );
        }

        final text = formatGenericList(
          title: 'XBRL 택사노미 재무제표양식 (${args['sj_div']})',
          emoji: '📋',
          list: list,
        );

        return CallToolResult(
          content: [TextContent(text: text)],
        );
      } on OpenDartException catch (e) {
        return errorResult(e);
      }
    },
  );

  // ─── 단일회사 주요 재무지표 ────────────────────────────────
  server.registerTool(
    'get_financial_indicators',
    description: '단일 회사의 주요 재무지표를 조회합니다.',
    inputSchema: ToolInputSchema.fromJson({
      'properties': {
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
          'description': '보고서 코드: 11013=1분기, 11012=반기, 11014=3분기, 11011=사업보고서',
          'enum': ['11013', '11012', '11014', '11011'],
        },
        'idx_cl_code': {
          'type': 'string',
          'description': '지표분류코드: M210000=수익성지표, M220000=안정성지표, '
              'M230000=성장성지표, M240000=활동성지표',
          'enum': ['M210000', 'M220000', 'M230000', 'M240000'],
        },
      },
      'required': ['corp_code', 'bsns_year', 'reprt_code', 'idx_cl_code'],
    }),
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) async {
      try {
        final result = await client.get('fnlttSinglIndx.json', params: {
          'corp_code': args['corp_code'] as String,
          'bsns_year': args['bsns_year'] as String,
          'reprt_code': args['reprt_code'] as String,
          'idx_cl_code': args['idx_cl_code'] as String,
        });

        final list = result['list'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          return CallToolResult(
            content: [TextContent(text: '조회된 데이터가 없습니다.')],
          );
        }

        final text = formatGenericList(
          title: '${list.first['corp_name'] ?? ''} ${args['bsns_year']} ${reprtLabel(args['reprt_code'] as String)} 주요 재무지표',
          emoji: '📊',
          list: list,
        );

        return CallToolResult(
          content: [TextContent(text: text)],
        );
      } on OpenDartException catch (e) {
        return errorResult(e);
      }
    },
  );

  // ─── 다중회사 주요 재무지표 ────────────────────────────────
  server.registerTool(
    'compare_financial_indicators',
    description: '여러 회사의 주요 재무지표를 비교합니다.',
    inputSchema: ToolInputSchema.fromJson({
      'properties': {
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
          'description': '보고서 코드: 11013=1분기, 11012=반기, 11014=3분기, 11011=사업보고서',
          'enum': ['11013', '11012', '11014', '11011'],
        },
        'idx_cl_code': {
          'type': 'string',
          'description': '지표분류코드: M210000=수익성지표, M220000=안정성지표, '
              'M230000=성장성지표, M240000=활동성지표',
          'enum': ['M210000', 'M220000', 'M230000', 'M240000'],
        },
      },
      'required': ['corp_code', 'bsns_year', 'reprt_code', 'idx_cl_code'],
    }),
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) async {
      try {
        final result = await client.get('fnlttCmpnyIndx.json', params: {
          'corp_code': args['corp_code'] as String,
          'bsns_year': args['bsns_year'] as String,
          'reprt_code': args['reprt_code'] as String,
          'idx_cl_code': args['idx_cl_code'] as String,
        });

        final list = result['list'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          return CallToolResult(
            content: [TextContent(text: '조회된 데이터가 없습니다.')],
          );
        }

        final text = formatGenericList(
          title: '기업간 주요 재무지표 비교 (${args['bsns_year']} ${reprtLabel(args['reprt_code'] as String)})',
          emoji: '📊',
          list: list,
        );

        return CallToolResult(
          content: [TextContent(text: text)],
        );
      } on OpenDartException catch (e) {
        return errorResult(e);
      }
    },
  );
}
