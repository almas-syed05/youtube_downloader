# YouTube Downloader Android App

A Flutter-based Android application that allows users to download YouTube videos by pasting video URLs. The app provides multiple quality options for downloads with a Node.js backend for merging video and audio streams.

## 📥 Download APK

**[Download the latest APK here](https://github.com/almas-syed05/youtube_downloader/releases/latest)**

After each push to main/master branch, a new APK is automatically built and released.

## ⚠️ Important Note

YouTube frequently updates their API, which can temporarily break the direct download feature. 

**This app uses a working community fork** ([Coronon/youtube_explode_dart](https://github.com/Coronon/youtube_explode_dart)) that patches YouTube API changes faster than the official version. However, if you still encounter errors, please use the **alternative download websites** provided in the app:
- [yt1s.com](https://www.yt1s.com)
- [y2mate.com](https://www.y2mate.com)  
- [ytmp3.cc](https://ytmp3.cc)

These are updated more frequently and provide reliable downloads when the app's direct method is unavailable.

## Features

- 📱 Mobile-friendly interface optimized for Android
- 🎥 Download YouTube videos in various qualities (720p, 480p, 360p)
- 🎵 Extract MP3 audio from videos
- 🔗 Simple URL paste interface
- ⚡ Fast and easy to use
- 🔄 Automatic video+audio merging via FFmpeg backend
- 🌐 Built-in alternative download website links

## Technology Stack

- **Framework**: Flutter
- **Language**: Dart
- **Target Platform**: Android
- **Backend**: Node.js + Express + FFmpeg
- **API**: youtube-explode-dart

## Setup Instructions

### Prerequisites

1. Install Flutter SDK: [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)
2. Install Android Studio or VS Code with Flutter extension
3. Set up an Android emulator or connect a physical device

### Installation

1. This project is already set up
2. Dependencies are installed

3. Run the app:
   ```bash
   flutter run
   ```

## Building APK

To build a release APK for Android:

```bash
flutter build apk --release
```

The APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

To build a split APK (smaller file sizes):
```bash
flutter build apk --split-per-abi
```

## How to Use

1. Open the app on your Android device
2. Copy a YouTube video URL
3. Paste it in the input field
4. Tap "Get Download Links"
5. Choose your preferred quality/format
6. The download will start automatically in your browser

## Project Structure

```
youtube_downloader/
├── lib/
│   ├── main.dart              # Main app UI and logic
│   └── youtube_service.dart   # API service for YouTube downloads
├── android/                   # Android-specific configuration
├── pubspec.yaml              # Flutter dependencies
└── README.md                 # This file
```

## Dependencies

- `http`: ^1.1.0 - HTTP requests to download APIs
- `url_launcher`: ^6.2.1 - Opening download links in browser
- `path_provider`: ^2.1.1 - File system access
- `permission_handler`: ^11.0.1 - Android permissions
- `flutter_downloader`: ^1.11.5 - Download management

## Permissions

The app requires the following Android permissions:
- Internet access
- Storage read/write
- Network state access

## Legal Notice

⚠️ **Important**: Downloading YouTube videos may violate YouTube's Terms of Service. This app is for educational purposes only. Users are responsible for complying with all applicable laws and terms of service.

## Troubleshooting

### App not connecting to API
- Ensure you have an active internet connection
- Check if the API endpoints are accessible
- The app tries multiple API sources automatically

### Downloads not starting
- Grant necessary storage permissions when prompted
- Ensure you have enough storage space
- Try a different video URL

### Build errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk
```

## Future Enhancements

- [ ] Direct download to device storage
- [ ] Download queue management
- [ ] Video preview before download
- [ ] Custom download location selection
- [ ] Download history
- [ ] Playlist download support

---

**Built with Flutter ❤️**
