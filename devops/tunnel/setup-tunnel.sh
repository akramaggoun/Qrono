#!/bin/bash

# Automated Cloudflare Tunnel Setup for Qrono
# This script handles the complete tunnel setup process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TUNNEL_NAME="qrono-tunnel"
CONFIG_FILE="config.yaml"
CREDENTIALS_FILE="credentials.json"

echo -e "${BLUE}🚀 Qrono Wireless QR Scanning - Automated Setup${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Function to print status messages
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running on Windows
is_windows() {
    [[ "$OS" == "Windows_NT" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]
}

# Function to run command with error handling
run_command() {
    local cmd="$1"
    local description="$2"

    echo -e "${YELLOW}🔧 $description...${NC}"
    if eval "$cmd"; then
        print_status "$description completed"
    else
        print_error "$description failed"
        exit 1
    fi
}

# Step 1: Check prerequisites
echo -e "${YELLOW}📋 Step 1: Checking Prerequisites${NC}"
echo "=================================="

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    print_error "cloudflared is not installed!"
    echo ""
    echo "Please install cloudflared first:"
    echo "1. Visit: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/"
    echo "2. Download and install cloudflared for your system"
    echo "3. Re-run this script"
    exit 1
fi
print_status "cloudflared is installed"

# Check if config.yaml exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "config.yaml not found in current directory"
    echo "Please run this script from the devops/tunnel directory"
    exit 1
fi
print_status "Configuration files found"

echo ""

# Step 2: Cloudflare Authentication
echo -e "${YELLOW}📋 Step 2: Cloudflare Authentication${NC}"
echo "===================================="

if [ ! -f "$CREDENTIALS_FILE" ]; then
    print_warning "Cloudflare authentication required"
    echo ""
    echo "This step requires browser authentication:"
    echo "1. A browser window will open"
    echo "2. Log in to your Cloudflare account"
    echo "3. Grant permission for tunnel access"
    echo ""
    read -p "Press Enter to continue and open browser for authentication..."
    run_command "cloudflared tunnel login" "Authenticating with Cloudflare"
else
    print_status "Already authenticated with Cloudflare"
fi

echo ""

# Step 3: Create Tunnel
echo -e "${YELLOW}📋 Step 3: Creating Tunnel${NC}"
echo "========================"

# Check if tunnel already exists
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    print_status "Tunnel '$TUNNEL_NAME' already exists"
else
    run_command "cloudflared tunnel create $TUNNEL_NAME" "Creating tunnel '$TUNNEL_NAME'"
fi

echo ""

# Step 4: Get Tunnel Information
echo -e "${YELLOW}📋 Step 4: Getting Tunnel Information${NC}"
echo "==================================="

TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
if [ -z "$TUNNEL_ID" ]; then
    print_error "Could not find tunnel ID for '$TUNNEL_NAME'"
    exit 1
fi
print_status "Tunnel ID: $TUNNEL_ID"

echo ""

# Step 5: Domain Configuration
echo -e "${YELLOW}📋 Step 5: Domain Configuration${NC}"
echo "=============================="

print_info "Domain setup requires manual configuration:"
echo ""
echo "You need a domain name for wireless access. Options:"
echo "1. Use a free subdomain from services like:"
echo "   - Cloudflare Pages (free)"
echo "   - ngrok (paid)"
echo "   - Localtunnel (free)"
echo "2. Use your own domain (requires DNS setup)"
echo ""
echo "Example domains:"
echo "- qrono.yourname.dev (if using a service)"
echo "- qrono-api.yourdomain.com (your own domain)"
echo ""

read -p "Enter your domain/subdomain for the API: " API_DOMAIN

if [ -z "$API_DOMAIN" ]; then
    print_error "Domain is required for wireless access"
    exit 1
fi

# Validate domain format
if [[ ! "$API_DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    print_warning "Domain format looks unusual. Please verify: $API_DOMAIN"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""

# Step 6: DNS Routing Setup
echo -e "${YELLOW}📋 Step 6: DNS Routing Setup${NC}"
echo "============================"

print_info "Setting up DNS routing for $API_DOMAIN"
echo "This will point $API_DOMAIN to your tunnel."
echo ""

# Check if DNS record already exists
if cloudflared tunnel route dns list | grep -q "$API_DOMAIN"; then
    print_status "DNS routing already configured for $API_DOMAIN"
else
    run_command "cloudflared tunnel route dns $TUNNEL_NAME $API_DOMAIN" "Configuring DNS routing"
fi

echo ""

# Step 7: Update Configuration
echo -e "${YELLOW}📋 Step 7: Updating Configuration${NC}"
echo "==============================="

# Backup original config
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

# Update config.yaml with actual values
sed -i.bak "s/qrono-api\.yourdomain\.com/$API_DOMAIN/g" "$CONFIG_FILE"
print_status "Updated config.yaml with domain: $API_DOMAIN"

echo ""

# Step 8: Test Configuration
echo -e "${YELLOW}📋 Step 8: Testing Configuration${NC}"
echo "==============================="

print_info "Testing tunnel configuration..."
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    print_status "Tunnel exists and is configured"
else
    print_error "Tunnel configuration failed"
    exit 1
fi

if cloudflared tunnel route dns list | grep -q "$API_DOMAIN"; then
    print_status "DNS routing is configured"
else
    print_error "DNS routing configuration failed"
    exit 1
fi

echo ""

# Step 9: Final Instructions
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo -e "${GREEN}=================${NC}"
echo ""
print_status "Cloudflare tunnel configured successfully"
echo ""
echo -e "${BLUE}📱 Wireless Access URL:${NC} https://$API_DOMAIN"
echo ""
echo -e "${YELLOW}🚀 To start wireless access:${NC}"
if is_windows; then
    echo "  Run: start-tunnel.bat"
else
    echo "  Run: ./start-tunnel.sh"
fi
echo ""
echo -e "${YELLOW}📱 Student App Configuration:${NC}"
echo "  1. Open Qrono app on student phone"
echo "  2. Go to Settings (⚙️ icon)"
echo "  3. Select 'Wireless (Cloudflare Tunnel)'"
echo "  4. Enter URL: https://$API_DOMAIN/api"
echo "  5. Apply settings and restart app"
echo ""
echo -e "${BLUE}🔧 Management Commands:${NC}"
if is_windows; then
    echo "  Status: status-tunnel.bat"
    echo "  Stop:   stop-tunnel.bat"
else
    echo "  Status: ./status-tunnel.sh"
    echo "  Stop:   ./stop-tunnel.sh"
fi
echo ""
print_info "Setup complete! Students can now scan QR codes wirelessly! 🎉"