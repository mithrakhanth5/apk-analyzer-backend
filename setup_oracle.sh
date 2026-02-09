#!/bin/bash
# ============================================
# APK Risk Analyzer - Oracle Cloud Setup Script
# Run this after SSH-ing into your Oracle Cloud VM
# ============================================

set -e

echo "🚀 APK Risk Analyzer - Oracle Cloud Setup"
echo "=========================================="

# Detect OS
if [ -f /etc/oracle-release ]; then
    OS="oracle"
    echo "✅ Detected: Oracle Linux"
elif [ -f /etc/lsb-release ]; then
    OS="ubuntu"
    echo "✅ Detected: Ubuntu"
else
    echo "⚠️  Unknown OS. Attempting Ubuntu-style installation..."
    OS="ubuntu"
fi

# Get current user
CURRENT_USER=$(whoami)
HOME_DIR=$(eval echo ~$CURRENT_USER)

echo ""
echo "📦 Step 1: Updating system packages..."
if [ "$OS" == "oracle" ]; then
    sudo yum update -y
else
    sudo apt update && sudo apt upgrade -y
fi

echo ""
echo "🐍 Step 2: Installing Python 3.11..."
if [ "$OS" == "oracle" ]; then
    sudo yum install -y python3.11 python3.11-pip git
else
    sudo apt install -y python3.11 python3.11-venv python3-pip git
fi

echo ""
echo "🔥 Step 3: Configuring firewall..."
if [ "$OS" == "oracle" ]; then
    sudo firewall-cmd --permanent --add-port=8000/tcp
    sudo firewall-cmd --reload
else
    sudo ufw allow 8000/tcp
fi

echo ""
echo "📂 Step 4: Setting up application directory..."
APP_DIR="$HOME_DIR/apk-risk-analyzer"

if [ -d "$APP_DIR" ]; then
    echo "Directory exists, pulling latest changes..."
    cd "$APP_DIR"
    git pull || true
else
    echo "Enter your GitHub repository URL (or press Enter to skip):"
    read -r REPO_URL
    if [ -n "$REPO_URL" ]; then
        git clone "$REPO_URL" "$APP_DIR"
        cd "$APP_DIR"
    else
        echo "Creating empty directory. You'll need to copy your code manually."
        mkdir -p "$APP_DIR"
        cd "$APP_DIR"
    fi
fi

echo ""
echo "🔧 Step 5: Setting up Python virtual environment..."
python3.11 -m venv venv
source venv/bin/activate

if [ -f "requirements.txt" ]; then
    echo "Installing dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "⚠️  No requirements.txt found. Installing basic dependencies..."
    pip install --upgrade pip
    pip install fastapi uvicorn python-multipart androguard reportlab pydantic aiohttp
fi

echo ""
echo "⚙️ Step 6: Creating systemd service..."

# Prompt for VirusTotal API key
echo "Enter your VirusTotal API key (or press Enter to skip):"
read -r VT_API_KEY

SERVICE_CONTENT="[Unit]
Description=APK Risk Analyzer Backend
After=network.target

[Service]
User=$CURRENT_USER
WorkingDirectory=$APP_DIR
Environment=\"PATH=$APP_DIR/venv/bin\"
Environment=\"VIRUSTOTAL_API_KEY=$VT_API_KEY\"
ExecStart=$APP_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target"

echo "$SERVICE_CONTENT" | sudo tee /etc/systemd/system/apk-analyzer.service > /dev/null

echo ""
echo "🚀 Step 7: Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable apk-analyzer
sudo systemctl start apk-analyzer

echo ""
echo "=========================================="
echo "✅ SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "Your backend should now be running at:"
echo "  http://$(curl -s ifconfig.me):8000"
echo ""
echo "Useful commands:"
echo "  Check status:  sudo systemctl status apk-analyzer"
echo "  View logs:     sudo journalctl -u apk-analyzer -f"
echo "  Restart:       sudo systemctl restart apk-analyzer"
echo ""
echo "Don't forget to update your Flutter app's cloudApiUrl!"
