#!/bin/bash

# Stop Cloudflare Tunnel for Qrono

echo "🛑 Stopping Qrono Cloudflare Tunnel..."

# Find and kill cloudflared processes
pkill -f "cloudflared tunnel run qrono-tunnel"

if [ $? -eq 0 ]; then
    echo "✅ Tunnel stopped successfully"
else
    echo "⚠️  No running tunnel found or failed to stop"
fi