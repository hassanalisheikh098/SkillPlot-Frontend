#!/bin/bash

# 1. Download the stable Flutter SDK from the official source
echo "📥 Downloading Flutter SDK..."
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz

# 2. Extract the downloaded package
echo "📦 Extracting Flutter..."
tar xf flutter_linux_3.22.2-stable.tar.xz

# 3. Add Flutter to the temporary system environment path
export PATH="$PATH:`pwd`/flutter/bin"

# 4. Verify the setup and accept the web licenses
flutter doctor

# 5. Run your production compilation command
echo "🚀 Compiling Flutter Web Application..."
flutter build web --release --dart-define=PRODUCTION=true --dart-define=API_BASE_URL=https://web-production-108a9.up.railway.app/api/v1 --dart-define=FLUTTER_WEB_RENDERER=canvaskit