#!/bin/bash
# devops/scripts/run_tests.sh
# Qrono — test automation script
# Usage:
#   Local:  bash devops/scripts/run_tests.sh
#   Docker: bash devops/scripts/run_tests.sh --docker

set -e

USE_DOCKER=false
for arg in "$@"; do
  [ "$arg" = "--docker" ] && USE_DOCKER=true
done

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo ""
echo "══════════════════════════════════════"
echo "  Qrono Test Runner"
echo "══════════════════════════════════════"
echo ""

# ── Docker mode ───────────────────────────────────────────────────────
if [ "$USE_DOCKER" = true ]; then
  echo "▶ Starting database container..."
  docker-compose up -d db

  echo "▶ Waiting for PostgreSQL..."
  until docker-compose exec -T db pg_isready -U qrono -d qrono &>/dev/null; do
    sleep 2
  done
  echo -e "${GREEN}✓ Database ready${NC}"

  echo "▶ Running tests inside Docker..."
  docker-compose exec -T backend npm test

  EXIT=$?
  [ $EXIT -eq 0 ] && echo -e "\n${GREEN}✅ All tests passed${NC}" \
                  || echo -e "\n${RED}❌ Tests failed${NC}"
  exit $EXIT
fi

# ── Local mode ────────────────────────────────────────────────────────
[ -f "backend/.env.ci" ] && export $(grep -v '^#' backend/.env.ci | xargs) \
  || { echo -e "${RED}❌ backend/.env.ci not found${NC}"; exit 1; }

echo "▶ Installing dependencies..."
cd backend && npm ci --silent

echo "▶ Running ESLint..."
npm run lint && echo -e "${GREEN}✓ Lint passed${NC}"

echo "▶ Running tests..."
npm test -- --forceExit

EXIT=$?
[ $EXIT -eq 0 ] && echo -e "\n${GREEN}✅ All tests passed${NC}" \
                || echo -e "\n${RED}❌ Tests failed${NC}"
exit $EXIT
