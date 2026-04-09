#!/bin/bash

# Start Cloudflare Tunnel for Qrono Wireless Access
# This script starts the tunnel to allow wireless QR scanning

echo "🚀 Starting Qrono Cloudflare Tunnel..."
echo "This will make the backend accessible wirelessly for QR scanning"
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared is not installed!"
    echo "Install from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/"
    exit 1
fi

# Check if config.yaml exists
if [ ! -f "config.yaml" ]; then
    echo "❌ config.yaml not found!"
    echo "Please configure your tunnel first."
    exit 1
fi

# Check if credentials.json exists
if [ ! -f "credentials.json" ]; then
    echo "❌ credentials.json not found!"
    echo "Run 'cloudflared tunnel login' first."
    exit 1
fi

echo "✅ Starting tunnel..."
echo "Backend will be accessible at: https://qrono-api.yourdomain.com"
echo "Press Ctrl+C to stop"
echo ""

# Start the tunnel
cloudflared tunnel run qrono-tunnel