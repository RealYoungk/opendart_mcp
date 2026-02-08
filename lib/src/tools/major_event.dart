import 'package:mcp_dart/mcp_dart.dart';
import '../client/opendart_client.dart';
import 'helpers.dart';

class _ToolDef {
  final String name;
  final String description;
  final String endpoint;

  const _ToolDef({
    required this.name,
    required this.description,
    required this.endpoint,
  });
}

const _tools = <_ToolDef>[
  _ToolDef(
    name: 'get_asset_transfer',
    description: '자산양수도(기타) 및 풋백옵션 정보를 조회합니다.',
    endpoint: 'astInhtrfEtcPtbkOpt.json',
  ),
  _ToolDef(
    name: 'get_default_occurrence',
    description: '부도발생 정보를 조회합니다.',
    endpoint: 'dfOcr.json',
  ),
  _ToolDef(
    name: 'get_business_suspension',
    description: '영업정지 정보를 조회합니다.',
    endpoint: 'bsnSp.json',
  ),
  _ToolDef(
    name: 'get_rehabilitation_filing',
    description: '회생절차 개시신청 정보를 조회합니다.',
    endpoint: 'ctrcvsBgrq.json',
  ),
  _ToolDef(
    name: 'get_dissolution',
    description: '해산사유 발생 정보를 조회합니다.',
    endpoint: 'dsRsOcr.json',
  ),
  _ToolDef(
    name: 'get_paid_capital_increase',
    description: '유상증자 결정 정보를 조회합니다.',
    endpoint: 'piicDecsn.json',
  ),
  _ToolDef(
    name: 'get_free_capital_increase',
    description: '무상증자 결정 정보를 조회합니다.',
    endpoint: 'fricDecsn.json',
  ),
  _ToolDef(
    name: 'get_mixed_capital_increase',
    description: '유무상증자 결정 정보를 조회합니다.',
    endpoint: 'pifricDecsn.json',
  ),
  _ToolDef(
    name: 'get_capital_reduction_decision',
    description: '감자 결정 정보를 조회합니다.',
    endpoint: 'crDecsn.json',
  ),
  _ToolDef(
    name: 'get_creditor_bank_mgmt_start',
    description: '채권은행 등의 관리절차 개시 정보를 조회합니다.',
    endpoint: 'bnkMngtPcbg.json',
  ),
  _ToolDef(
    name: 'get_lawsuit',
    description: '소송 등의 제기 정보를 조회합니다.',
    endpoint: 'lwstLg.json',
  ),
  _ToolDef(
    name: 'get_overseas_listing_decision',
    description: '해외 증권시장 주권등 상장 결정 정보를 조회합니다.',
    endpoint: 'ovLstDecsn.json',
  ),
  _ToolDef(
    name: 'get_overseas_delisting_decision',
    description: '해외 증권시장 주권등 상장폐지 결정 정보를 조회합니다.',
    endpoint: 'ovDlstDecsn.json',
  ),
  _ToolDef(
    name: 'get_overseas_listing',
    description: '해외 증권시장 주권등 상장 정보를 조회합니다.',
    endpoint: 'ovLst.json',
  ),
  _ToolDef(
    name: 'get_overseas_delisting',
    description: '해외 증권시장 주권등 상장폐지 정보를 조회합니다.',
    endpoint: 'ovDlst.json',
  ),
  _ToolDef(
    name: 'get_convertible_bond_issuance',
    description: '전환사채권 발행결정 정보를 조회합니다.',
    endpoint: 'cvbdIsDecsn.json',
  ),
  _ToolDef(
    name: 'get_bond_with_warrant_issuance',
    description: '신주인수권부사채권 발행결정 정보를 조회합니다.',
    endpoint: 'bdwtIsDecsn.json',
  ),
  _ToolDef(
    name: 'get_exchangeable_bond_issuance',
    description: '교환사채권 발행결정 정보를 조회합니다.',
    endpoint: 'exbdIsDecsn.json',
  ),
  _ToolDef(
    name: 'get_creditor_bank_mgmt_stop',
    description: '채권은행 등의 관리절차 중단 정보를 조회합니다.',
    endpoint: 'bnkMngtPcsp.json',
  ),
  _ToolDef(
    name: 'get_contingent_capital_issuance',
    description: '상각형 조건부자본증권 발행결정 정보를 조회합니다.',
    endpoint: 'wdCocobdIsDecsn.json',
  ),
  _ToolDef(
    name: 'get_treasury_stock_acquisition',
    description: '자기주식 취득 결정 정보를 조회합니다.',
    endpoint: 'tsstkAqDecsn.json',
  ),
  _ToolDef(
    name: 'get_treasury_stock_disposal',
    description: '자기주식 처분 결정 정보를 조회합니다.',
    endpoint: 'tsstkDpDecsn.json',
  ),
  _ToolDef(
    name: 'get_treasury_trust_contract',
    description: '자기주식취득 신탁계약 체결 결정 정보를 조회합니다.',
    endpoint: 'tsstkAqTrctrCnsDecsn.json',
  ),
  _ToolDef(
    name: 'get_treasury_trust_termination',
    description: '자기주식취득 신탁계약 해지 결정 정보를 조회합니다.',
    endpoint: 'tsstkAqTrctrCcDecsn.json',
  ),
  _ToolDef(
    name: 'get_business_acquisition',
    description: '영업양수 결정 정보를 조회합니다.',
    endpoint: 'bsnInhDecsn.json',
  ),
  _ToolDef(
    name: 'get_business_transfer_decision',
    description: '영업양도 결정 정보를 조회합니다.',
    endpoint: 'bsnTrfDecsn.json',
  ),
  _ToolDef(
    name: 'get_tangible_asset_acquisition',
    description: '유형자산 양수 결정 정보를 조회합니다.',
    endpoint: 'tgastInhDecsn.json',
  ),
  _ToolDef(
    name: 'get_tangible_asset_transfer',
    description: '유형자산 양도 결정 정보를 조회합니다.',
    endpoint: 'tgastTrfDecsn.json',
  ),
  _ToolDef(
    name: 'get_other_corp_stock_acquisition',
    description: '타법인 주식 및 출자증권 양수결정 정보를 조회합니다.',
    endpoint: 'otcprStkInvscrInhDecsn.json',
  ),
  _ToolDef(
    name: 'get_other_corp_stock_transfer',
    description: '타법인 주식 및 출자증권 양도결정 정보를 조회합니다.',
    endpoint: 'otcprStkInvscrTrfDecsn.json',
  ),
  _ToolDef(
    name: 'get_equity_bond_acquisition',
    description: '주권 관련 사채권 양수 결정 정보를 조회합니다.',
    endpoint: 'stkrtbdInhDecsn.json',
  ),
  _ToolDef(
    name: 'get_equity_bond_transfer',
    description: '주권 관련 사채권 양도 결정 정보를 조회합니다.',
    endpoint: 'stkrtbdTrfDecsn.json',
  ),
  _ToolDef(
    name: 'get_merger_decision',
    description: '회사합병 결정 정보를 조회합니다.',
    endpoint: 'cmpMgDecsn.json',
  ),
  _ToolDef(
    name: 'get_split_decision',
    description: '회사분할 결정 정보를 조회합니다.',
    endpoint: 'cmpDvDecsn.json',
  ),
  _ToolDef(
    name: 'get_split_merger_decision',
    description: '회사분할합병 결정 정보를 조회합니다.',
    endpoint: 'cmpDvmgDecsn.json',
  ),
  _ToolDef(
    name: 'get_stock_exchange_transfer',
    description: '주식교환·이전 결정 정보를 조회합니다.',
    endpoint: 'stkExtrDecsn.json',
  ),
];

/// Registers major event report tools (주요사항보고서, DS005).
void registerMajorEventTools(McpServer server, OpenDartClient client) {
  for (final def in _tools) {
    server.registerTool(
      def.name,
      description: def.description,
      inputSchema: ToolInputSchema.fromJson({
        'properties': {
          'corp_code': {
            'type': 'string',
            'description': '고유번호 (8자리)',
          },
          'bgn_de': {
            'type': 'string',
            'description': '시작일 (YYYYMMDD)',
          },
          'end_de': {
            'type': 'string',
            'description': '종료일 (YYYYMMDD)',
          },
        },
        'required': ['corp_code'],
      }),
      annotations: ToolAnnotations(readOnlyHint: true),
      callback: (args, extra) async {
        try {
          final params = <String, String>{
            'corp_code': args['corp_code'] as String,
          };
          addIfPresent(params, 'bgn_de', args['bgn_de']);
          addIfPresent(params, 'end_de', args['end_de']);

          final result = await client.get(def.endpoint, params: params);

          final list = result['list'] as List<dynamic>? ?? [];
          if (list.isEmpty) {
            return CallToolResult(
              content: [TextContent(text: '조회된 데이터가 없습니다.')],
            );
          }

          final text = formatGenericList(
            title: '${list.first['corp_name'] ?? ''} - ${def.description}',
            emoji: '📌',
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
}
