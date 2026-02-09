# 🚀 Oracle Cloud Always Free - Complete Deployment Guide

Host your APK Risk Analyzer backend **for free** with **zero cold starts**!

Oracle Cloud's "Always Free" tier gives you a powerful VM that runs 24/7 forever.

---

## 📋 What You Get (FREE Forever)

| Resource | Amount |
|----------|--------|
| ARM CPUs | 4 cores |
| RAM | 24 GB |
| Storage | 200 GB |
| Bandwidth | 10 TB/month |
| Uptime | **24/7** (no cold starts!) |

---

## Step 1: Create Oracle Cloud Account

1. Go to [cloud.oracle.com](https://cloud.oracle.com/)
2. Click **"Sign Up for Free"**
3. Fill in your details:
   - Use your real email and phone (verification required)
   - Choose **Home Region** closest to you (India → Mumbai or Hyderabad)
   - You'll need a credit card for verification (you WON'T be charged)
4. Verify your email and phone
5. Wait for account activation (usually 5-15 minutes)

> ⚠️ **Important**: Oracle may take 24 hours to verify new accounts. Be patient!

---

## Step 2: Create Your Free VM

1. After logging in, click ☰ (hamburger menu) → **Compute** → **Instances**
2. Click **"Create Instance"**

### Configure the Instance:

| Setting | Value |
|---------|-------|
| **Name** | `apk-analyzer-backend` |
| **Image** | Oracle Linux 8 (or Ubuntu 22.04) |
| **Shape** | Click **"Change shape"** → **Ampere** → `VM.Standard.A1.Flex` |
| **OCPUs** | 1 (you can use up to 4 for free) |
| **RAM** | 6 GB (you can use up to 24 for free) |
| **Boot Volume** | 50 GB (default is fine) |

### SSH Key Setup:

1. Under **"Add SSH keys"**, select **"Generate a key pair for me"**
2. Click **"Save Private Key"** → Save as `oracle-key.key`
3. **Keep this file safe!** You need it to connect to your server.

### Network Settings:

1. Keep defaults for VCN (Virtual Cloud Network)
2. Make sure **"Assign a public IPv4 address"** is checked ✅

4. Click **"Create"** and wait 2-5 minutes for your VM to start

---

## Step 3: Note Your Server IP

1. Once the instance is **Running**, find **"Public IP address"**
2. Copy it (e.g., `132.145.67.89`)
3. Save this IP - you'll need it for your Flutter app!

---

## Step 4: Open Required Ports (Firewall)

Your backend needs port 8000 to be accessible from the internet.

### A) Oracle Cloud Security List:

1. Go to ☰ → **Networking** → **Virtual Cloud Networks**
2. Click your VCN (usually named after your instance)
3. Click the **subnet** (public subnet)
4. Click **Security Lists** → **Default Security List**
5. Click **"Add Ingress Rules"**:

| Setting | Value |
|---------|-------|
| Source CIDR | `0.0.0.0/0` |
| Protocol | TCP |
| Destination Port Range | `8000` |
| Description | APK Analyzer API |

6. Click **"Add Ingress Rules"**

### B) OS Firewall (after connecting):

We'll do this in Step 5 (via SSH).

---

## Step 5: Connect to Your Server (SSH)

### Windows (PowerShell):

```powershell
# Navigate to where you saved the key
cd C:\Users\YourName\Downloads

# Fix key permissions (required for SSH)
icacls oracle-key.key /inheritance:r
icacls oracle-key.key /grant:r "$($env:USERNAME):(R)"

# Connect (replace with YOUR IP)
ssh -i oracle-key.key opc@YOUR_SERVER_IP
```

### If using Ubuntu image:
```powershell
ssh -i oracle-key.key ubuntu@YOUR_SERVER_IP
```

---

## Step 6: Install Everything on Server

Once connected via SSH, run these commands:

### Option A: Automatic Setup (Recommended)

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/setup_oracle.sh | bash
```

### Option B: Manual Setup

```bash
# 1. Update system
sudo yum update -y  # For Oracle Linux
# OR
sudo apt update && sudo apt upgrade -y  # For Ubuntu

# 2. Install Python 3.11
# Oracle Linux:
sudo yum install -y python3.11 python3.11-pip git

# Ubuntu:
sudo apt install -y python3.11 python3.11-venv python3-pip git

# 3. Open firewall port
# Oracle Linux:
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload

# Ubuntu:
sudo ufw allow 8000/tcp

# 4. Clone your backend code
cd ~
git clone https://github.com/YOUR_USERNAME/apk-risk-analyzer.git
cd apk-risk-analyzer

# 5. Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# 6. Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# 7. Test run (should see "APK Risk Analyzer Backend Starting...")
python main.py
```

Press `Ctrl+C` to stop the test.

---

## Step 7: Run as Background Service (Auto-Start)

Create a systemd service so your backend runs 24/7 and auto-restarts:

```bash
# Create service file
sudo nano /etc/systemd/system/apk-analyzer.service
```

Paste this content (adjust paths if needed):

```ini
[Unit]
Description=APK Risk Analyzer Backend
After=network.target

[Service]
User=opc
WorkingDirectory=/home/opc/apk-risk-analyzer
Environment="PATH=/home/opc/apk-risk-analyzer/venv/bin"
Environment="VIRUSTOTAL_API_KEY=your_api_key_here"
ExecStart=/home/opc/apk-risk-analyzer/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

> **Note**: If using Ubuntu, change `User=opc` to `User=ubuntu` and update paths accordingly.

Save: `Ctrl+X` → `Y` → `Enter`

```bash
# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable apk-analyzer
sudo systemctl start apk-analyzer

# Check status
sudo systemctl status apk-analyzer
```

✅ You should see **"active (running)"**

---

## Step 8: Test Your Backend

Open a browser and go to:

```
http://YOUR_SERVER_IP:8000
```

You should see:
```json
{"status":"operational","version":"1.0.0","analyzer_ready":true}
```

---

## Step 9: Update Flutter App

Edit `lib/config/constants.dart`:

```dart
// Change this line to your Oracle Cloud IP
static const String cloudApiUrl = 'http://YOUR_SERVER_IP:8000';
```

Rebuild your app and test!

---

## 🔐 Optional: Add HTTPS (Recommended for Production)

For secure HTTPS access, you can use Caddy as a reverse proxy:

```bash
# Install Caddy
sudo yum install -y 'dnf-command(copr)'
sudo dnf copr enable @caddy/caddy -y
sudo dnf install caddy -y

# Create Caddyfile
sudo nano /etc/caddy/Caddyfile
```

Content (replace with your domain):
```
your-domain.com {
    reverse_proxy localhost:8000
}
```

```bash
# Start Caddy
sudo systemctl enable caddy
sudo systemctl start caddy
```

> **Note**: You need a domain name pointing to your server IP for HTTPS.

---

## 🛠️ Useful Commands

| Action | Command |
|--------|---------|
| View logs | `sudo journalctl -u apk-analyzer -f` |
| Restart service | `sudo systemctl restart apk-analyzer` |
| Stop service | `sudo systemctl stop apk-analyzer` |
| Check status | `sudo systemctl status apk-analyzer` |
| Update code | `cd ~/apk-risk-analyzer && git pull && sudo systemctl restart apk-analyzer` |

---

## ❓ Troubleshooting

### "Connection refused" error
1. Check if service is running: `sudo systemctl status apk-analyzer`
2. Check firewall: `sudo firewall-cmd --list-ports` (should show 8000/tcp)
3. Check Oracle Cloud Security List (Step 4A)

### "Permission denied" SSH error
- Make sure your key file has correct permissions
- Use `opc` user for Oracle Linux, `ubuntu` for Ubuntu

### Service won't start
- Check logs: `sudo journalctl -u apk-analyzer -n 50`
- Usually a Python or dependency issue

### Can't create ARM instance
- Oracle's free ARM instances are popular and may be temporarily unavailable
- Try during off-peak hours or wait a few hours
- Alternative: Use AMD shape `VM.Standard.E2.1.Micro` (1 core, 1GB RAM)

---

## ✅ Comparison: Render vs Oracle Cloud

| Feature | Render (Free) | Oracle (Free) |
|---------|---------------|---------------|
| Cold Start | 30-50 seconds | **None!** |
| RAM | 512 MB | **24 GB** |
| CPUs | Shared | **4 dedicated** |
| Uptime | Sleeps after 15 min | **24/7** |
| Storage | Limited | **200 GB** |
| Bandwidth | Limited | **10 TB/month** |

**Oracle is significantly better for always-on services!**

---

## 🎉 Done!

Your APK Risk Analyzer backend is now running 24/7 on Oracle Cloud with:
- ⚡ **Zero cold starts**
- 💪 **More resources**
- 🆓 **Completely free**

Your Flutter app will now respond instantly every time!
