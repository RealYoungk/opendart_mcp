# opendart_mcp

[![pub package](https://img.shields.io/pub/v/opendart_mcp.svg)](https://pub.dev/packages/opendart_mcp)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[MCP (Model Context Protocol)](https://modelcontextprotocol.io/) server for
[OpenDART API](https://opendart.fss.or.kr/) — Korea's Financial Supervisory
Service electronic disclosure system.

Enables LLMs (Claude, GPT, etc.) to directly access Korean corporate disclosure
data, financial statements, and ownership information.

## Features

| Tool | Description |
|------|-------------|
| `search_disclosure` | 공시 목록 검색 (기업명, 기간, 유형별 필터) |
| `get_company` | 기업개황 조회 (대표자, 업종, 주소, 결산월 등) |
| `search_corp_code` | 회사명 → 고유번호(corp_code) 변환 |
| `get_financial_statements` | 단일회사 전체 재무제표 |
| `get_key_accounts` | 단일회사 주요계정 (매출, 영업이익, 순이익 등) |
| `compare_accounts` | 다중회사 주요계정 비교 |
| `get_major_shareholders` | 대량보유(5%+) 상황보고 |
| `get_executive_shareholding` | 임원·주요주주 소유 현황 |

## Getting Started

### 1. Get an API Key

[OpenDART](https://opendart.fss.or.kr/)에서 회원가입 후 인증키를 발급받으세요.

### 2. Install

```bash
dart pub global activate opendart_mcp
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  opendart_mcp: ^0.1.0
```

### 3. Run

```bash
export OPENDART_API_KEY=your_api_key_here
opendart_mcp
```

### 4. Configure MCP Client

#### Claude Desktop (`claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "opendart": {
      "command": "dart",
      "args": ["run", "opendart_mcp"],
      "env": {
        "OPENDART_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

#### Claude Code

```bash
claude mcp add opendart -- dart run opendart_mcp
```

## Usage Examples

Once connected, you can ask your LLM things like:

- "삼성전자의 최근 공시를 검색해줘"
- "SK하이닉스의 2024년 사업보고서 재무제표를 보여줘"
- "삼성전자와 SK하이닉스의 주요 재무지표를 비교해줘"
- "네이버의 대량보유 주주 현황은?"

## Development

```bash
# Get dependencies
dart pub get

# Run in development
OPENDART_API_KEY=your_key dart run bin/opendart_mcp.dart

# Run tests
dart test

# Analyze
dart analyze
```

## License

MIT License — see [LICENSE](LICENSE) for details.
