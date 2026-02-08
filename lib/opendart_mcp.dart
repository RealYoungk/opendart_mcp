/// MCP server for OpenDART API (금융감독원 전자공시 시스템).
///
/// Provides LLM-accessible tools for:
/// - 공시검색 (Disclosure search)
/// - 기업개황 (Company overview)
/// - 재무제표 (Financial statements)
/// - 주요계정 비교 (Key account comparison)
/// - 지분공시 (Ownership disclosure)
library opendart_mcp;

export 'src/server.dart' show createServer;
export 'src/client/opendart_client.dart'
    show OpenDartClient, OpenDartException, CorpInfo;
