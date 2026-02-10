# 🚀 Koyeb Deployment Guide - Fast & Free

Deploy your APK Risk Analyzer backend on Koyeb for **~200ms cold starts** (vs Render's 30-50 seconds)!

---

## 📋 Why Koyeb?

| Feature | Render (Free) | Koyeb (Free) |
|---------|---------------|--------------|
| Cold Start | 30-50 seconds | **~200ms** |
| Sleep Timer | 15 min inactivity | 5 min (but wakes fast!) |
| Deployment | GitHub/Docker | GitHub/Docker |
| Free Tier | 1 service | 2 nano services |

---

## Step 1: Push Backend to GitHub

Your backend needs to be in a GitHub repository.

1. Go to [github.com](https://github.com/) and create a new repository (e.g., `apk-risk-analyzer-backend`)

2. Push your backend folder:
```bash
cd d:\creater\my_first_app\backend
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/apk-risk-analyzer-backend.git
git push -u origin main
```

> **Important**: This project uses a **monorepo structure**. You MUST configure Koyeb to use `backend_new` as the **Root Directory** (see Step 4).

---

## Step 2: Sign Up for Koyeb

1. Go to [koyeb.com](https://www.koyeb.com/)
2. Click **"Get Started Free"**
3. Sign up with **GitHub** (easiest) or email
4. Verify your email if needed

---

## Step 3: Create New App

1. From the Koyeb dashboard, click **"Create App"**
2. Select **"GitHub"** as the deployment method
3. **Install Koyeb GitHub App** if prompted
4. Select your `apk-risk-analyzer-backend` repository
5. Choose the **main** branch

---

## Step 4: Configure Deployment

### Builder Settings:
| Setting | Value |
|---------|-------|
| **Builder** | Dockerfile |
| **Dockerfile location** | `Dockerfile` (default) |

### Instance Settings:
| Setting | Value |
|---------|-------|
| **Instance type** | Free (nano) |
| **Regions** | Select closest to you (Singapore/Frankfurt) |
| **Root Directory** | `backend_new` |

### Exposed Ports:
| Port | Protocol |
|------|----------|
| **8000** | HTTP |

### Environment Variables (Optional):
Click **"Add variable"** to add:
| Key | Value |
|-----|-------|
| `VIRUSTOTAL_API_KEY` | Your VirusTotal API key |

---

## Step 5: Set App Name & Deploy

1. **App name**: `apk-analyzer` (or your preference)
2. Click **"Deploy"**
3. Wait 2-5 minutes for the build to complete

---

## Step 6: Get Your URL

Once deployed, Koyeb gives you a URL like:
```
https://apk-analyzer-YOUR_USERNAME.koyeb.app
```

Test it by opening in browser:
```
https://apk-analyzer-YOUR_USERNAME.koyeb.app/api/v1/health
```

You should see:
```json
{"status":"operational","version":"1.0.0","analyzer_ready":true}
```

---

## Step 7: Update Flutter App

Edit `lib/config/constants.dart`:

```dart
// Change this to your Koyeb URL
static const String cloudApiUrl = 'https://apk-analyzer-YOUR_USERNAME.koyeb.app';
```

Rebuild your APK and test!

---

## 🔄 Auto-Deployments

Koyeb automatically redeploys when you push to GitHub:

```bash
# Make changes to your backend
git add .
git commit -m "Update backend"
git push
# Koyeb auto-deploys! 🎉
```

---

## 🛠️ Useful Dashboard Features

From [app.koyeb.com](https://app.koyeb.com):

- **Logs**: Real-time logs of your app
- **Metrics**: CPU, Memory, Requests
- **Domains**: Add custom domain (optional)
- **Settings**: Scale, redeploy, delete

---

## ❓ Troubleshooting

### Build fails with "Dockerfile not found"
- Make sure `Dockerfile` is at the root of your repo
- Check the Dockerfile location setting in Koyeb

### "Port 8000 not responding"
- Verify your Dockerfile has `EXPOSE 8000`
- Check that uvicorn runs on `0.0.0.0:8000`

### App sleeps after inactivity
- Koyeb free tier sleeps after 5 minutes, but wakes in ~200ms
- This is much faster than Render's 30-50 second wake time!

### "Out of memory" errors
- Koyeb nano instances have 256MB RAM
- For large APKs, you may need to upgrade to small instance

---

## ✅ Quick Checklist

- [ ] Backend pushed to GitHub
- [ ] Signed up for Koyeb
- [ ] Connected GitHub repo
- [ ] Deployed successfully
- [ ] Tested health endpoint
- [ ] Updated Flutter app URL
- [ ] Tested mobile app

---

## 🎉 Done!

Your APK Risk Analyzer is now on Koyeb with:
- ⚡ **~200ms cold starts** (15x faster than Render!)
- 🔄 **Auto-deploy on Git push**
- 🌍 **Global edge network**
- 🆓 **Completely free**

Your mobile app will now respond much faster!
