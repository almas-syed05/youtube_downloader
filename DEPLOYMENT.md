# Deployment Guide

This guide will walk you through deploying the YouTube Downloader app to GitHub and the backend to Railway.

## Part 1: Deploy to GitHub

### 1. Initialize Git Repository

```bash
cd C:\pj\youtube_downloader
git init
git add .
git commit -m "Initial commit - YouTube Downloader by almas"
```

### 2. Create GitHub Repository

1. Go to [github.com](https://github.com) and log in
2. Click the "+" icon → "New repository"
3. Name it: `youtube_downloader`
4. Keep it public (so anyone can download the APK)
5. Don't initialize with README (we already have one)
6. Click "Create repository"

### 3. Push to GitHub

```bash
git remote add origin https://github.com/YOUR_USERNAME/youtube_downloader.git
git branch -M main
git push -u origin main
```

### 4. Enable GitHub Actions

1. Go to your repository on GitHub
2. Click "Actions" tab
3. The workflow should automatically run and build the APK
4. Wait for it to complete (~5 minutes)

### 5. Download APK

After the workflow completes:
- Go to "Releases" on the right sidebar
- Download the latest APK file
- Share this link with anyone who wants to use your app!

**Direct download link format:**
```
https://github.com/YOUR_USERNAME/youtube_downloader/releases/latest
```

---

## Part 2: Deploy Backend to Railway

### 1. Sign Up for Railway

1. Go to [railway.app](https://railway.app)
2. Click "Login" → "Login with GitHub"
3. Authorize Railway

### 2. Deploy the Backend

1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose your `youtube_downloader` repository
4. Click "Add variables" (not needed for now, but you can add later)
5. Click "Deploy"

### 3. Configure Root Directory

IMPORTANT: Railway needs to know where the server code is!

1. Go to project Settings
2. Find "Root Directory" or "Service Settings"
3. Set it to: `merge_server`
4. Save and redeploy

### 4. Get Your Server URL

1. Go to your deployment
2. Click on "Settings"
3. Under "Networking" → "Public Networking"
4. Click "Generate Domain"
5. Copy the URL (e.g., `https://your-app-name.up.railway.app`)

### 5. Update Flutter App with Railway URL

1. Open `lib/main.dart`
2. Find line ~44:
   ```dart
   static const String mergeApiUrl = "http://10.0.2.2:3000/merge";
   ```
3. Replace with your Railway URL:
   ```dart
   static const String mergeApiUrl = "https://your-app-name.up.railway.app/merge";
   ```

### 6. Commit and Push Changes

```bash
git add lib/main.dart
git commit -m "Update API URL to Railway deployment"
git push
```

This will trigger GitHub Actions to build a new APK with the updated backend URL!

---

## Part 3: Verify Everything Works

### Test the Backend

1. Visit your Railway URL in a browser (e.g., `https://your-app.railway.app`)
2. You should see: "YouTube Merge Server is running! 🎬"

### Test the App

1. Download the latest APK from GitHub Releases
2. Install it on your Android device
3. Try downloading a YouTube video
4. It should now use your Railway backend!

---

## Part 4: Share Your App

### Share the APK Download Link

```
https://github.com/YOUR_USERNAME/youtube_downloader/releases/latest
```

Anyone can download and install the APK from this link!

### Important Notes

- **Android Security**: Users need to enable "Install from unknown sources"
- **Updates**: Every time you push to GitHub, a new APK is built automatically
- **Railway Free Tier**: Gives you 500 hours/month (enough for personal use)
- **FFmpeg**: Automatically installed on Railway via nixpacks.toml

---

## Troubleshooting

### GitHub Actions fails

- Check the Actions tab for error messages
- Make sure all dependencies are in `pubspec.yaml`
- Check Flutter version compatibility

### Railway deployment fails

- Check the logs in Railway dashboard
- Make sure `merge_server` is set as root directory
- Verify `nixpacks.toml` is in the merge_server folder

### App can't connect to backend

- Make sure you updated the API URL in `lib/main.dart`
- Check Railway deployment is running
- Test the backend URL in a browser first

---

## Cost

- **GitHub**: Free (unlimited public repositories)
- **Railway**: Free tier includes:
  - 500 hours/month
  - $5 credit/month
  - Perfect for personal projects!

---

**Made by almas** 🚀
