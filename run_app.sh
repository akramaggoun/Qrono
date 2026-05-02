#!/bin/bash

# ==========================================
# Qrono Full Stack Launcher (Linux/macOS)
# Launch Backend, Frontend, and Cloudflare Tunnel
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
MOBILE_DIR="$SCRIPT_DIR/mobile/flutter_app"
TUNNEL_DIR="$SCRIPT_DIR/devops/tunnel"
BACKEND_PORT=3000
TUNNEL_LOG="$TUNNEL_DIR/tunnel_output.log"

echo "🚀 Starting Qrono Ecosystem..."
echo "------------------------------------------"

# 0. Database Maintenance (Optional)
read -rp "Nuke and Seed database before starting? (y/n): " clean_db
if [[ "$clean_db" =~ ^[Yy]$ ]]; then
    echo "🧹 Nuking and Seeding Database..."
    cd "$BACKEND_DIR"
    node nuke_db.js
    node nuke_history.js
    node prisma/seed.js
    echo "✅ Database reset complete."
fi

# 1. Start Tunnel (Background)
echo "📡 [1/3] Starting Cloudflare Quick Tunnel..."
cd "$TUNNEL_DIR"

# Kill any leftover cloudflared process
pkill -f "cloudflared" 2>/dev/null

# Clean up previous log
rm -f "$TUNNEL_LOG"

# Launch quick tunnel in background
cloudflared tunnel --url "http://localhost:$BACKEND_PORT" > "$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!

echo "⏳ Waiting for tunnel URL (up to 30 seconds)..."
tunnel_url=""
counter=0

while [[ $counter -lt 30 ]]; do
    sleep 1
    if [[ -f "$TUNNEL_LOG" ]]; then
        tunnel_url=$(grep -oP 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' "$TUNNEL_LOG" | head -1)
    fi
    if [[ -n "$tunnel_url" ]]; then
        break
    fi
    ((counter++))
done

if [[ -n "$tunnel_url" ]]; then
    echo ""
    echo "✅ Tunnel is live!"
    echo "🔗 Quick Tunnel URL: $tunnel_url"
    echo "   Use this URL in your Flutter app settings for wireless testing."
    echo "------------------------------------------"
else
    echo "⚠️  Tunnel started but URL could not be detected after 30 seconds."
    echo "   Check $TUNNEL_LOG for the link."
fi

# 2. Start Backend (Background)
echo "⚙️  [2/3] Starting Backend Server..."
cd "$BACKEND_DIR"
npm run dev &
BACKEND_PID=$!

# 3. Wait for backend to warm up
sleep 3

# 4. Start Frontend
echo "📱 [3/3] Starting Flutter App..."
echo "Choose target environment:"
echo "[1] Browser (Chrome) - Local Testing"
echo "[2] Android Device - Wireless Debugging"
echo "[3] All Targets"
echo "------------------------------------------"
read -rp "Selection (1-3): " target

cd "$MOBILE_DIR"

case "$target" in
    1)
        echo "🌐 Launching Chrome..."
        flutter run -d chrome
        ;;
    2)
        echo "📲 Launching on Android Device..."
        flutter run -d android
        ;;
    3)
        echo "🌎 Launching on All Devices..."
        flutter run -d all
        ;;
    *)
        echo "❌ Invalid selection. Exiting."
        ;;
esac

# Wait for user before exit
read -rp "Press Enter to exit..."