import 'package:mcp_dart/mcp_dart.dart';
import '../client/opendart_client.dart';
import 'helpers.dart';

class _ToolDef {
  final String name;
  final String description;
  final String endpoint;
  const _ToolDef({required this.name, required this.description, required this.endpoint});
}

const _tools = <_ToolDef>[
  _ToolDef(name: 'get_equity_registration', description: '증권신고서(지분증권) 요약 정보를 조회합니다.', endpoint: 'estkRs.json'),
  _ToolDef(name: 'get_debt_registration', description: '증권신고서(채무증권) 요약 정보를 조회합니다.', endpoint: 'bdRs.json'),
  _ToolDef(name: 'get_depositary_receipt_registration', description: '증권신고서(증권예탁증권) 요약 정보를 조회합니다.', endpoint: 'stkdpRs.json'),
  _ToolDef(name: 'get_merger_registration', description: '증권신고서(합병) 요약 정보를 조회합니다.', endpoint: 'mgRs.json'),
  _ToolDef(name: 'get_stock_exchange_registration', description: '증권신고서(주식의포괄적교환·이전) 요약 정보를 조회합니다.', endpoint: 'extrRs.json'),
  _ToolDef(name: 'get_split_registration', description: '증권신고서(분할) 요약 정보를 조회합니다.', endpoint: 'dvRs.json'),
];

/// Registers securities registration statement tools (증권신고서, DS006).
void registerSecuritiesRegTools(McpServer server, OpenDartClient client) {
  for (final def in _tools) {
    server.registerTool(
      def.name,
      description: def.description,
      inputSchema: ToolInputSchema.fromJson({
        'properties': {
          'corp_code': { 'type': 'string', 'description': '고유번호 (8자리)' },
          'bgn_de': { 'type': 'string', 'description': '시작일 (YYYYMMDD)' },
          'end_de': { 'type': 'string', 'description': '종료일 (YYYYMMDD)' },
        },
        'required': ['corp_code'],
      }),
      annotations: ToolAnnotations(readOnlyHint: true),
      callback: (args, extra) async {
        try {
          final params = <String, String>{ 'corp_code': args['corp_code'] as String };
          addIfPresent(params, 'bgn_de', args['bgn_de']);
          addIfPresent(params, 'end_de', args['end_de']);
          final result = await client.get(def.endpoint, params: params);
          final list = result['list'] as List<dynamic>? ?? [];
          if (list.isEmpty) {
            return CallToolResult(content: [TextContent(text: '조회된 데이터가 없습니다.')]);
          }
          final text = formatGenericList(
            title: '${list.first['corp_name'] ?? ''} - ${def.description}',
            emoji: '📑',
            list: list,
          );
          return CallToolResult(content: [TextContent(text: text)]);
        } on OpenDartException catch (e) {
          return errorResult(e);
        }
      },
    );
  }
}
