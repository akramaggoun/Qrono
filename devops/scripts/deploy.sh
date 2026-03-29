#!/bin/bash
# devops/scripts/deploy.sh
# Qrono — production deployment script
# Called by GitHub Actions after CI passes
# Manual run: bash devops/scripts/deploy.sh

set -e

APP_DIR="/var/www/qrono"
cd "$APP_DIR"

echo ""
echo "════════════════════════════════════════"
echo "  Qrono Deployment"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════"
echo ""

echo "▶ Pulling latest code from main..."
git pull origin main
echo "✓ $(git log --oneline -1)"
echo ""

echo "▶ Rebuilding containers..."
docker-compose pull
docker-compose up -d --build
echo "✓ Containers updated"
echo ""

echo "▶ Waiting for API to be healthy..."
sleep 5
for i in {1..10}; do
  HEALTH=$(curl -sf http://localhost:3000/api/health 2>/dev/null || echo "FAIL")
  if echo "$HEALTH" | grep -q "healthy"; then
    echo "✓ Health check passed"
    break
  fi
  [ $i -eq 10 ] && { echo "❌ Health check failed"; echo "Run: docker-compose logs backend"; exit 1; }
  echo "  attempt $i/10..."; sleep 3
done

echo ""
echo "════════════════════════════════════════"
echo "  ✅ Deployment complete"
echo "  Commit: $(git log --oneline -1)"
echo "════════════════════════════════════════"
