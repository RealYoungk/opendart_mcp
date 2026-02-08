import 'package:mcp_dart/mcp_dart.dart';
import '../client/opendart_client.dart';

/// 파라미터가 null이 아니고 비어있지 않으면 맵에 추가
void addIfPresent(Map<String, String> params, String key, dynamic value) {
  if (value != null && value.toString().isNotEmpty) {
    params[key] = value.toString();
  }
}

/// corp_cls 코드를 한국어 라벨로 변환
String corpClsLabel(String? cls) {
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

/// reprt_code를 한국어 보고서 유형으로 변환
String reprtLabel(String code) {
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

/// 금액을 콤마 포맷으로 변환
String formatAmount(dynamic amount) {
  if (amount == null || amount.toString().isEmpty || amount == '-') {
    return '-';
  }
  final str = amount.toString().replaceAll(',', '');
  final num = int.tryParse(str);
  if (num == null) return amount.toString();

  final formatted = num.abs().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );

  return num < 0 ? '-$formatted' : formatted;
}

/// OpenDartException을 MCP 에러 결과로 변환
CallToolResult errorResult(OpenDartException e) {
  return CallToolResult(
    content: [TextContent(text: '❌ 오류: ${e.message}')],
    isError: true,
  );
}

/// API 응답 리스트를 범용 key-value 텍스트로 포맷
/// [title]: 출력 헤더
/// [list]: API 응답의 list 배열
/// [skipKeys]: 출력에서 제외할 키 (예: status, message 등 메타데이터)
String formatGenericList({
  required String title,
  required String emoji,
  required List<dynamic> list,
  Set<String> skipKeys = const {'rcept_no', 'corp_cls', 'corp_code', 'corp_name', 'status', 'message'},
}) {
  final buffer = StringBuffer();
  buffer.writeln('$emoji $title');
  buffer.writeln('═══════════════════════════════════════');

  if (list.isEmpty) {
    buffer.writeln('조회된 데이터가 없습니다.');
    return buffer.toString();
  }

  for (var i = 0; i < list.length; i++) {
    final item = list[i] as Map<String, dynamic>;
    if (i > 0) buffer.writeln('───────────────────────');
    for (final entry in item.entries) {
      if (skipKeys.contains(entry.key)) continue;
      final value = entry.value?.toString() ?? '-';
      if (value.isEmpty || value == '-') continue;
      buffer.writeln('  ${entry.key}: $value');
    }
  }

  return buffer.toString();
}
