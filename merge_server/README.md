# YouTube Merge Server

Backend service for merging YouTube video and audio streams using FFmpeg.

## Features

- Merge separate video and audio streams
- Progress tracking
- Automatic file cleanup
- CORS enabled for mobile app access

## Deploy to Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/new)

### Manual Deployment Steps:

1. **Create a Railway account** at [railway.app](https://railway.app)

2. **Create a new project**:
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Connect your GitHub account
   - Select this repository
   - Set root directory to `merge_server`

3. **Configure the service**:
   - Railway will auto-detect Node.js
   - FFmpeg will be installed via nixpacks.toml
   - The service will automatically start on port 3000

4. **Get your deployment URL**:
   - After deployment, Railway will provide a URL like: `https://your-app.railway.app`
   - Copy this URL

5. **Update Flutter app**:
   - Open `lib/main.dart`
   - Find line ~44: `static const String mergeApiUrl = "http://10.0.2.2:3000/merge";`
   - Replace with: `static const String mergeApiUrl = "https://your-app.railway.app/merge";`

6. **Rebuild your APK**:
   ```bash
   flutter build apk --release
   ```

## Environment Variables

No environment variables needed! The server runs on Railway's default port.

## Local Development

```bash
npm install
npm start
```

Server will run on http://localhost:3000

## API Endpoints

- `POST /merge` - Merge video and audio
- `GET /progress/:jobId` - Check merge progress
- `GET /download/:jobId` - Download merged file

---

made by almas
