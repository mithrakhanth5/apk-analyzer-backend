# 🌐 Step-by-Step Guide: Free Cloud Hosting (Render.com)

This guide will help you host your backend for **FREE** so you can use the mobile app anywhere without your laptop.

## Step 1: Create a GitHub Repository
The easiest way to host is by connecting your code to GitHub.
1. Go to [github.com](https://github.com/) and create a new repository (e.g., `apk-risk-analyzer`).
2. Upload the contents of your `backend/` folder to this repository.
   - **Important**: Your GitHub repository should have the `main.py` and `Dockerfile` at the root (top level).

## Step 2: Sign Up for Render.com
1. Go to [Render.com](https://render.com/) and sign up (using your GitHub account is easiest).
2. Click the **"New +"** button and select **"Web Service"**.
3. Connect your GitHub repository.

## Step 3: Configure the Web Service
Render will automatically detect your `Dockerfile`. Use these settings:
- **Name**: `apk-analyzer-backend`
- **Region**: Choose the one closest to you (e.g., Singapore or Mumbai).
- **Instance Type**: **Free** ($0/month).
- **Root Directory**: `backend_new` (CRITICAL!)
- **Click "Create Web Service"**.

## Step 4: Configure Environment Variables (Optional but Recommended)
To enable **VirusTotal sandbox analysis** (70+ antivirus engines):
1. In Render dashboard, go to your service → **Environment**.
2. Add a new environment variable:
   - **Key**: `VIRUSTOTAL_API_KEY`
   - **Value**: Your free API key from [VirusTotal](https://www.virustotal.com/gui/join-us)
3. Click **Save Changes**.

> **Note**: Without the API key, the local sandbox simulator will still work, but you won't get multi-engine AV scan results.

## Step 5: Update the Flutter App
Once your service is live, Render will give you a URL like `https://apk-analyzer-backend.onrender.com`.
1. Open `lib/config/constants.dart` in your project.
2. Change the API URL to your new Render URL:
```dart
static String get defaultApiUrl {
  if (kIsWeb) return 'http://localhost:8000';
  // Use your Render URL here!
  return 'https://apk-analyzer-backend.onrender.com'; 
}
```

---

## � New Features (v1.1)
- **Sandbox Analysis**: VirusTotal integration + local behavior simulator
- **PDF Reports**: Download professional PDF reports via `/api/v1/report/pdf`
- **Combined Endpoint**: `/api/v1/analyze-and-report` for analysis + PDF in one request

---

## �🛠 Possible Problems & Solutions

### 1. "Cold Starts" (The app is slow to start)
**Problem**: Render's free tier "sleeps" after 15 minutes of inactivity. The first request might take 30-50 seconds.
**Solution**: When you open the mobile app, wait a few seconds for the "Health Check" to pass. Once it's "awake," it will be fast.

### 2. "Out of Memory" (Large APKs fail)
**Problem**: Free hosting only gives 512MB RAM. Analyzing very large APKs (>50MB) might crash the server.
**Solution**: For the free tier, try to analyze smaller APKs first. If you need more power, you might need a paid tier ($7/month).

### 3. "CORS Error"
**Problem**: The app cannot talk to the server because of security restrictions.
**Solution**: I have already configured `main.py` with `allow_origins=["*"]`, so this should not happen.

### 4. "Hash Mismatch"
**Problem**: Uploading from mobile might slightly change the file bytes.
**Solution**: Ensure you are using the `AnalysisService` correctly which handles the hashing before upload.

### 5. "VirusTotal API Error"
**Problem**: Sandbox analysis shows "API key not configured".
**Solution**: Add your free VirusTotal API key as an environment variable (see Step 4 above).

