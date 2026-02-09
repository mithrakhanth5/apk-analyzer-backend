# ☁️ Google Cloud Run Deployment Guide

Deploy your APK Risk Analyzer backend to **Google Cloud Run** for fast, free hosting with ~1-2 second cold starts.

## 📊 Free Tier Limits
- **2 million requests/month**
- 180,000 vCPU-seconds
- 360,000 GB-seconds of memory
- **HTTPS included** automatically

---

## Prerequisites
1. A Google account (Gmail works)
2. Credit/Debit card (won't be charged for free tier)

---

## Step 1: Create Google Cloud Account

1. Go to [cloud.google.com](https://cloud.google.com/)
2. Click **"Get started for free"**
3. Sign in with your Google account
4. Enter billing information (you get **$300 free credits** for 90 days!)
5. Create a new project named: `apk-risk-analyzer`

---

## Step 2: Install Google Cloud CLI

### Windows (PowerShell as Admin):
```powershell
# Download and run the installer
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:TEMP\GoogleCloudSDKInstaller.exe")
& "$env:TEMP\GoogleCloudSDKInstaller.exe"
```

Or download manually: [Google Cloud SDK Installer](https://cloud.google.com/sdk/docs/install)

### After installation:
```powershell
# Restart PowerShell, then authenticate
gcloud init
gcloud auth login
```

---

## Step 3: Deploy to Cloud Run

### Option A: Deploy from Local Dockerfile (Recommended)

Open PowerShell in your `backend` folder and run:

```powershell
# Navigate to backend folder
cd d:\creater\my_first_app\backend

# Set your project ID (replace with your project ID)
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Deploy! (This builds and deploys in one command)
gcloud run deploy apk-analyzer-backend `
  --source . `
  --region asia-south1 `
  --platform managed `
  --allow-unauthenticated `
  --memory 512Mi `
  --cpu 1 `
  --timeout 300 `
  --concurrency 10
```

### Option B: Deploy from GitHub

1. Go to [Cloud Run Console](https://console.cloud.google.com/run)
2. Click **"Create Service"**
3. Select **"Continuously deploy from a repository"**
4. Connect your GitHub repository
5. Select the `backend` folder as the source
6. Configure:
   - Region: `asia-south1` (Mumbai) or closest to you
   - Memory: `512 Mi`
   - CPU: `1`
   - Allow unauthenticated invocations: **Yes**

---

## Step 4: Get Your Service URL

After deployment completes, you'll see a URL like:
```
https://apk-analyzer-backend-xxxxxxxxxx-xx.a.run.app
```

**Test it:**
```powershell
curl https://apk-analyzer-backend-xxxxxxxxxx-xx.a.run.app/api/v1/health
```

---

## Step 5: Configure Environment Variables (Optional)

For VirusTotal integration:

```powershell
gcloud run services update apk-analyzer-backend `
  --region asia-south1 `
  --set-env-vars "VIRUSTOTAL_API_KEY=your_api_key_here"
```

Or via Console:
1. Go to Cloud Run → Your Service → **Edit & Deploy New Revision**
2. Go to **Variables & Secrets** tab
3. Add: `VIRUSTOTAL_API_KEY` = `your_api_key`

---

## Step 6: Update Flutter App

Update `lib/config/constants.dart`:

```dart
static String get defaultApiUrl {
  if (kIsWeb) return 'http://localhost:8000';
  // Use your Google Cloud Run URL!
  return 'https://apk-analyzer-backend-xxxxxxxxxx-xx.a.run.app';
}
```

---

## ⚡ Performance Tips

### Reduce Cold Starts Further
Set minimum instances to 1 (uses some free tier quota):
```powershell
gcloud run services update apk-analyzer-backend `
  --region asia-south1 `
  --min-instances 1
```

### Monitor Usage
```powershell
# View logs
gcloud run services logs read apk-analyzer-backend --region asia-south1

# View metrics
gcloud run services describe apk-analyzer-backend --region asia-south1
```

---

## 🛠️ Troubleshooting

### "Permission Denied"
```powershell
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### "Build Failed"
Check your `requirements.txt` and `Dockerfile` are in the `backend` folder.

### "Out of Memory"
Increase memory limit:
```powershell
gcloud run services update apk-analyzer-backend `
  --region asia-south1 `
  --memory 1Gi
```

### "Timeout Error"
Increase timeout (max 3600 seconds):
```powershell
gcloud run services update apk-analyzer-backend `
  --region asia-south1 `
  --timeout 600
```

---

## 💰 Cost Control

Stay within free tier:
- Monitor usage in [Cloud Console Billing](https://console.cloud.google.com/billing)
- Set up budget alerts to notify at $1 spending
- After $300 credits expire, free tier still gives 2M requests/month

---

## 🔗 Useful Links
- [Cloud Run Pricing](https://cloud.google.com/run/pricing)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Free Tier Details](https://cloud.google.com/free)
