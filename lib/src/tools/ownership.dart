import 'package:mcp_dart/mcp_dart.dart';
import '../client/opendart_client.dart';
import 'helpers.dart';

/// Registers ownership-related tools (지분공시).
void registerOwnershipTools(McpServer server, OpenDartClient client) {
  // ─── 대량보유 상황보고 ────────────────────────────────────
  server.registerTool(
    'get_major_shareholders',
    description: '대량보유 상황보고 내역을 조회합니다. '
        '5% 이상 지분 보유자 정보.',
    inputSchema: ToolInputSchema.fromJson({
      'properties': {
        'corp_code': {
          'type': 'string',
          'description': '고유번호 (8자리)',
        },
      },
      'required': ['corp_code'],
    }),
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) async {
      try {
        final result = await client.get('majorstock.json', params: {
          'corp_code': args['corp_code'] as String,
        });

        final list = result['list'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          return CallToolResult(
            content: [TextContent(text: '대량보유 상황보고 내역이 없습니다.')],
          );
        }

        final buffer = StringBuffer();
        buffer.writeln('👥 대량보유 상황보고');
        buffer.writeln('═══════════════════════════════════════');

        for (final item in list) {
          buffer.writeln();
          buffer.writeln('보고자: ${item['repror']}');
          buffer.writeln('  보유주식수: ${item['stkqy']}');
          buffer.writeln('  보유비율: ${item['stkrt']}%');
          buffer.writeln('  보유목적: ${item['hold_purps']}');
          buffer.writeln('  보고일: ${item['rcept_dt']}');
        }

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } on OpenDartException catch (e) {
        return errorResult(e);
      }
    },
  );

  // ─── 임원·주요주주 소유보고 ───────────────────────────────
  server.registerTool(
    'get_executive_shareholding',
    description: '임원 및 주요주주의 주식 소유 현황을 조회합니다.',
    inputSchema: ToolInputSchema.fromJson({
      'properties': {
        'corp_code': {
          'type': 'string',
          'description': '고유번호 (8자리)',
        },
      },
      'required': ['corp_code'],
    }),
    annotations: ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) async {
      try {
        final result = await client.get('elestock.json', params: {
          'corp_code': args['corp_code'] as String,
        });

        final list = result['list'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          return CallToolResult(
            content: [TextContent(text: '임원 소유 보고 내역이 없습니다.')],
          );
        }

        final buffer = StringBuffer();
        buffer.writeln('👔 임원·주요주주 소유보고');
        buffer.writeln('═══════════════════════════════════════');

        for (final item in list) {
          buffer.writeln();
          buffer.writeln('${item['repror']} (${item['isu_exctv_rgist_at']})');
          buffer.writeln('  변동일: ${item['chg_dt']}');
          buffer.writeln('  변동사유: ${item['chg_rsn']}');
          buffer.writeln('  변동 전: ${item['bfst_stkqy']}주 (${item['bfst_stkrt']}%)');
          buffer.writeln('  변동 후: ${item['afst_stkqy']}주 (${item['afst_stkrt']}%)');
        }

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } on OpenDartException catch (e) {
        return errorResult(e);
      }
    },
  );
}
