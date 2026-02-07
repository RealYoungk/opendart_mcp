#!/bin/bash
set -e

echo "🚀 OpenDART MCP Server 배포 스크립트"
echo "======================================="
echo ""

# 0. 기존 .git 정리 (Cowork에서 생성된 불완전한 것)
if [ -d ".git" ]; then
  echo "🧹 기존 .git 폴더 정리..."
  rm -rf .git
fi

# 1. Git 초기화 & 커밋
echo "📦 Step 1: Git 초기화..."
git init
git branch -m main
git add .
git commit -m "feat: initial OpenDART MCP server

Dart MCP server for Korea FSS OpenDART API with 8 tools:
- Disclosure: search_disclosure, get_company, search_corp_code
- Financial: get_financial_statements, get_key_accounts, compare_accounts
- Ownership: get_major_shareholders, get_executive_shareholding

Built with mcp_dart package, stdio transport."

echo ""
echo "✅ Git 커밋 완료"

# 2. GitHub 레포 생성 & 푸시
echo ""
echo "📤 Step 2: GitHub 레포 생성 및 푸시..."
gh repo create opendart_mcp --public --source=. --push \
  --description "MCP server for OpenDART API (Korea FSS electronic disclosure system)"

echo ""
echo "✅ GitHub 푸시 완료: https://github.com/realyoungk/opendart_mcp"

# 3. Dart 의존성 설치
echo ""
echo "📥 Step 3: Dart 의존성 설치..."
dart pub get

echo ""
echo "✅ 의존성 설치 완료"

# 4. 분석 & 테스트
echo ""
echo "🔍 Step 4: 코드 분석..."
dart analyze

echo ""
echo "🧪 Step 5: 테스트..."
dart test

# 5. pub.dev 배포 (dry-run)
echo ""
echo "📋 Step 6: pub.dev 배포 미리보기..."
dart pub publish --dry-run

echo ""
echo "======================================="
echo "🎉 준비 완료!"
echo ""
echo "pub.dev에 실제 배포하려면:"
echo "  dart pub publish"
echo ""
echo "이 스크립트는 배포 후 삭제해도 됩니다:"
echo "  rm setup.sh"
