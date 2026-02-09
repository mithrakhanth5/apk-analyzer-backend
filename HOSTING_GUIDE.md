# 🚀 Complete Free Hosting Guide for APK Risk Analyzer

Your project is **already configured** for deployment! Follow these steps to host your backend for free.

---

## Prerequisites ✅

Your project already has:
- ✅ [Dockerfile](file:///d:/creater/my_first_app/backend/Dockerfile) - Ready for container deployment
- ✅ [requirements.txt](file:///d:/creater/my_first_app/backend/requirements.txt) - All dependencies listed
- ✅ [main.py](file:///d:/creater/my_first_app/backend/main.py) - CORS enabled for mobile access
- ✅ [constants.dart](file:///d:/creater/my_first_app/lib/config/constants.dart) - Easy cloud URL switching

---

## Step 1: Push Backend to GitHub

1. **Create a new GitHub repository**:
   - Go to [github.com/new](https://github.com/new)
   - Name it `apk-analyzer-backend`
   - Keep it **Public** (required for free Render tier)
   - Click **Create repository**

2. **Upload only the backend folder**:
   ```powershell
   # In your terminal, navigate to backend folder
   cd d:\creater\my_first_app\backend
   
   # Initialize git (if not already)
   git init
   git add .
   git commit -m "Initial backend commit"
   
   # Add your GitHub repo as remote
   git remote add origin https://github.com/YOUR_USERNAME/apk-analyzer-backend.git
   git branch -M main
   git push -u origin main
   ```

> [!IMPORTANT]
> Your GitHub repo should have `main.py`, `Dockerfile`, and `requirements.txt` at the **root level** (not inside a subfolder).

---

## Step 2: Deploy to Render.com (FREE)

1. **Sign up at [render.com](https://render.com)** using your GitHub account

2. **Create a New Web Service**:
   - Click **"New +"** → **"Web Service"**
   - Connect your GitHub account if prompted
   - Select your `apk-analyzer-backend` repository

3. **Configure the service**:
   | Setting | Value |
   |---------|-------|
   | **Name** | `apk-analyzer-backend` |
   | **Region** | Singapore or Mumbai (closest to you) |
   | **Runtime** | Docker |
   | **Instance Type** | **Free** |

4. **Click "Create Web Service"** and wait 2-5 minutes for deployment

5. **Copy your URL** - It will look like:
   ```
   https://apk-analyzer-backend.onrender.com
   ```

---

## Step 3: Update Your Flutter App

Edit [constants.dart](file:///d:/creater/my_first_app/lib/config/constants.dart):

```diff
- static const String cloudApiUrl = 'https://your-app.onrender.com';
+ static const String cloudApiUrl = 'https://apk-analyzer-backend.onrender.com';

- static bool useCloud = false;
+ static bool useCloud = true;   // Enable cloud mode!
```

Then rebuild your APK:
```powershell
cd d:\creater\my_first_app
flutter build apk --release
```

---

## Step 4: Test Your Deployment

1. **Test the health endpoint** in your browser:
   ```
   https://apk-analyzer-backend.onrender.com/api/v1/health
   ```
   
   You should see:
   ```json
   {"status":"operational","version":"1.0.0","analyzer_ready":true}
   ```

2. **Test in your Flutter app** - the app should now connect to the cloud!

---

## ⚠️ Important: Free Tier Limitations

| Limitation | What Happens | Solution |
|------------|--------------|----------|
| **Cold Starts** | First request takes 30-50 seconds after 15 min idle | Just wait, it will wake up |
| **512MB RAM** | Very large APKs (>50MB) may fail | Analyze smaller APKs first |
| **750 hours/month** | Enough for personal use | Use sparingly or upgrade ($7/mo) |

---

## Alternative Free Platforms

If Render doesn't work for you:

| Platform | Deploy Method | Notes |
|----------|---------------|-------|
| [Railway.app](https://railway.app) | Connect GitHub | $5 free credit/month |
| [Fly.io](https://fly.io) | `flyctl deploy` | 3 free machines |
| [PythonAnywhere](https://pythonanywhere.com) | Manual upload | Python-specific, easy |

---

## Quick Troubleshooting

**❌ "Connection refused"**
→ Wait 30 seconds for cold start, then try again

**❌ "Build failed" on Render**
→ Check that `Dockerfile` is at repo root, not in a subfolder

**❌ "CORS error"**  
→ Already fixed! Your `main.py` has `allow_origins=["*"]`

**❌ "Hash mismatch"**
→ The app handles hashing correctly; this shouldn't happen with the current setup

---

## Summary

| Step | Action |
|------|--------|
| 1 | Push `backend/` folder to GitHub as separate repo |
| 2 | Connect GitHub to Render.com, deploy as Docker |
| 3 | Update `cloudApiUrl` and set `useCloud = true` |
| 4 | Rebuild Flutter APK and test! |

**Total time: ~10 minutes** 🎉
