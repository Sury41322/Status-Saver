# Status Saver

A cross-platform Flutter app to view, preview, and save WhatsApp status photos and videos directly to your device gallery.

## Features
- Browse WhatsApp status media (photos & videos) saved on-device
- Full-screen preview before saving — view a status before deciding to download it
- One-tap save to gallery with automatic file handling for images and videos
- Runtime permission handling for storage/media access
- Built with a clean, modular widget structure (separate Home and Preview screens)

## Tech Stack
- **Framework:** Flutter (Dart)
- **Key packages:** `photo_manager` (media access), `saver_gallery` (save to device), `video_player` (video preview), `permission_handler` (runtime permissions)
- **Platforms:** Android (primary), with project scaffolding for iOS, Windows, macOS, and Linux

## How It Works
The app reads locally cached WhatsApp status files from device storage, lists them in a scrollable gallery view, and lets the user preview each photo/video full-screen before saving. Saved files are written to the device's media gallery using platform-native save APIs, with permission checks handled before any file access.

## Getting Started
```bash
flutter pub get
flutter run
```

## Status
Personal project — functional and tested on Android. Built to explore Flutter's media/file-system APIs and platform permission handling.
