#!/bin/bash

# 1. Address Git's root user security warning
echo "🔧 Configuring Git safety permissions..."
git config --global --add safe.directory /vercel/path0/flutter
git config --global --add safe.directory "$PWD"

# 2. Download a newer Flutter SDK supporting Dart ^3.8.1
echo "📥 Downloading updated Flutter SDK..."
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.0-stable.tar.xz

# 3. Extract the downloaded package safely
echo "📦 Extracting Flutter..."
tar xf flutter_linux_3.27.0-stable.tar.xz

# 4. Add Flutter to the execution path environment
export PATH="$PATH:`pwd`/flutter/bin"

# 5. Pre-download the web build artifacts
echo "⚙️ Initializing web compiler tools..."
flutter config --enable-web

# 6. Run your production compilation command
echo "🚀 Compiling Flutter Web Application..."
flutter build web --release --dart-define=PRODUCTION=true --dart-define=API_BASE_URL=https://web-production-108a9.up.railway.app/api/v1 --dart-define=FLUTTER_WEB_RENDERER=canvaskit