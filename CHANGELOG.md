## 0.2.0

- `search_corp_code`를 `corpCode.xml` 전용 엔드포인트로 전환 (lazy-loaded 인메모리 캐시)
- 다운로드 도구(`download_document`, `download_xbrl`)에서 base64 바이너리 데이터 반환
- HTTP 타임아웃 설정 (기본 30초)
- API 호출 제한 (일 10,000건) rate limiting 구현
- MockClient 기반 통합 테스트 34개 추가

## 0.1.0

- Initial release
- 공시정보: `search_disclosure`, `get_company`, `search_corp_code`
- 재무정보: `get_financial_statements`, `get_key_accounts`, `compare_accounts`
- 지분공시: `get_major_shareholders`, `get_executive_shareholding`
- OpenDART API error handling with Korean status messages
- Stdio transport support via `mcp_dart`
