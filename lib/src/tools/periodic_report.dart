import 'package:mcp_dart/mcp_dart.dart';
import '../client/opendart_client.dart';
import 'helpers.dart';

/// DS002 정기보고서 주요정보 도구 정의
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
    name: 'get_capital_change',
    description: '증자(감자) 현황을 조회합니다.',
    endpoint: 'irdsSttus.json',
  ),
  _ToolDef(
    name: 'get_dividend_info',
    description: '배당에 관한 사항을 조회합니다.',
    endpoint: 'alotMatter.json',
  ),
  _ToolDef(
    name: 'get_treasury_stock',
    description: '자기주식 취득 및 처분 현황을 조회합니다.',
    endpoint: 'tesstkAcqsDspsSttus.json',
  ),
  _ToolDef(
    name: 'get_largest_shareholder',
    description: '최대주주 현황을 조회합니다.',
    endpoint: 'hyslrSttus.json',
  ),
  _ToolDef(
    name: 'get_largest_shareholder_change',
    description: '최대주주 변동현황을 조회합니다.',
    endpoint: 'hyslrChgSttus.json',
  ),
  _ToolDef(
    name: 'get_minority_shareholders',
    description: '소액주주 현황을 조회합니다.',
    endpoint: 'mrhlSttus.json',
  ),
  _ToolDef(
    name: 'get_executives',
    description: '임원 현황을 조회합니다.',
    endpoint: 'exctvSttus.json',
  ),
  _ToolDef(
    name: 'get_employees',
    description: '직원 현황을 조회합니다.',
    endpoint: 'empSttus.json',
  ),
  _ToolDef(
    name: 'get_director_individual_compensation',
    description: '이사·감사의 개인별 보수현황을 조회합니다. (5억원 이상)',
    endpoint: 'hmvAuditIndvdlBySttus.json',
  ),
  _ToolDef(
    name: 'get_director_total_compensation',
    description: '이사·감사 전체의 보수현황(보수지급금액)을 조회합니다.',
    endpoint: 'hmvAuditAllSttus.json',
  ),
  _ToolDef(
    name: 'get_top5_individual_compensation',
    description: '개인별 보수지급 금액을 조회합니다. (5억이상 상위5인)',
    endpoint: 'indvdlByPay.json',
  ),
  _ToolDef(
    name: 'get_outside_investment',
    description: '타법인 출자현황을 조회합니다.',
    endpoint: 'otrCprInvstmntSttus.json',
  ),
  _ToolDef(
    name: 'get_total_stock',
    description: '주식의 총수 현황을 조회합니다.',
    endpoint: 'stockTotqySttus.json',
  ),
  _ToolDef(
    name: 'get_debt_securities_issuance',
    description: '채무증권 발행실적을 조회합니다.',
    endpoint: 'detScritsIsuAcmslt.json',
  ),
  _ToolDef(
    name: 'get_commercial_paper_balance',
    description: '기업어음증권 미상환 잔액을 조회합니다.',
    endpoint: 'entrprsBilScritsNrdmpBlce.json',
  ),
  _ToolDef(
    name: 'get_short_term_bond_balance',
    description: '단기사채 미상환 잔액을 조회합니다.',
    endpoint: 'srtpdPsndbtNrdmpBlce.json',
  ),
  _ToolDef(
    name: 'get_corporate_bond_balance',
    description: '회사채 미상환 잔액을 조회합니다.',
    endpoint: 'cprndNrdmpBlce.json',
  ),
  _ToolDef(
    name: 'get_hybrid_securities_balance',
    description: '신종자본증권 미상환 잔액을 조회합니다.',
    endpoint: 'newCaplScritsNrdmpBlce.json',
  ),
  _ToolDef(
    name: 'get_contingent_capital_balance',
    description: '조건부 자본증권 미상환 잔액을 조회합니다.',
    endpoint: 'cndlCaplScritsNrdmpBlce.json',
  ),
  _ToolDef(
    name: 'get_auditor_opinion',
    description: '회계감사인의 명칭 및 감사의견을 조회합니다.',
    endpoint: 'accnutAdtorNmNdAdtOpinion.json',
  ),
  _ToolDef(
    name: 'get_audit_service_contract',
    description: '감사용역 체결현황을 조회합니다.',
    endpoint: 'adtServcCnclsSttus.json',
  ),
  _ToolDef(
    name: 'get_non_audit_service_contract',
    description: '회계감사인과의 비감사용역 계약체결 현황을 조회합니다.',
    endpoint: 'accnutAdtorNonAdtServcCnclsSttus.json',
  ),
  _ToolDef(
    name: 'get_outside_directors',
    description: '사외이사 및 그 변동현황을 조회합니다.',
    endpoint: 'outcmpnyDrctrNdChangeSttus.json',
  ),
  _ToolDef(
    name: 'get_unregistered_exec_compensation',
    description: '미등기임원 보수현황을 조회합니다.',
    endpoint: 'unrstExctvMendngSttus.json',
  ),
  _ToolDef(
    name: 'get_director_approved_compensation',
    description: '이사·감사 전체의 보수현황(주주총회 승인금액)을 조회합니다.',
    endpoint: 'drctrAdtAllMendngSttusGmtsckConfmAmount.json',
  ),
  _ToolDef(
    name: 'get_director_compensation_by_type',
    description: '이사·감사 전체의 보수현황(보수지급금액 - 유형별)을 조회합니다.',
    endpoint: 'drctrAdtAllMendngSttusMendngPymntamtTyCl.json',
  ),
  _ToolDef(
    name: 'get_public_offering_usage',
    description: '공모자금의 사용내역을 조회합니다.',
    endpoint: 'pssrpCptalUseDtls.json',
  ),
  _ToolDef(
    name: 'get_private_placement_usage',
    description: '사모자금의 사용내역을 조회합니다.',
    endpoint: 'prvsrpCptalUseDtls.json',
  ),
];

/// Registers periodic report tools (정기보고서 주요정보, DS002).
void registerPeriodicReportTools(McpServer server, OpenDartClient client) {
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
          'bsns_year': {
            'type': 'string',
            'description': '사업연도 (YYYY)',
          },
          'reprt_code': {
            'type': 'string',
            'description': '보고서 코드: 11013=1분기, 11012=반기, 11014=3분기, 11011=사업보고서',
            'enum': ['11013', '11012', '11014', '11011'],
          },
        },
        'required': ['corp_code', 'bsns_year', 'reprt_code'],
      }),
      annotations: ToolAnnotations(readOnlyHint: true),
      callback: (args, extra) async {
        try {
          final result = await client.get(def.endpoint, params: {
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

          final text = formatGenericList(
            title: '${list.first['corp_name'] ?? ''} ${args['bsns_year']} ${reprtLabel(args['reprt_code'] as String)} - ${def.description}',
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
  }
}
