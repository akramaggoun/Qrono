#!/bin/bash

# Check Cloudflare Tunnel Status for Qrono

echo "📊 Qrono Cloudflare Tunnel Status"
echo "=================================="

# Check if cloudflared is running
if pgrep -f "cloudflared tunnel run qrono-tunnel" > /dev/null; then
    echo "✅ Tunnel Status: RUNNING"
    echo "🌐 Backend accessible at: https://qrono-api.yourdomain.com"
    echo "📱 Students can scan QR codes wirelessly"
else
    echo "❌ Tunnel Status: STOPPED"
    echo "💡 Run './start-tunnel.sh' to start wireless access"
fi

echo ""
echo "📋 Tunnel Configuration:"
if [ -f "config.yaml" ]; then
    echo "✅ config.yaml: Present"
else
    echo "❌ config.yaml: Missing"
fi

if [ -f "credentials.json" ]; then
    echo "✅ credentials.json: Present"
else
    echo "❌ credentials.json: Missing - Run 'cloudflared tunnel login'"
fi

echo ""
echo "🔧 Quick Setup Commands:"
echo "1. cloudflared tunnel login"
echo "2. cloudflared tunnel create qrono-tunnel"
echo "3. Update config.yaml with your domain"
echo "4. cloudflared tunnel route dns qrono-tunnel your-subdomain.yourdomain.com"
echo "5. ./start-tunnel.sh"