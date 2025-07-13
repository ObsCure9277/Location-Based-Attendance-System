#!/bin/bash

# Exit on error
set -e

echo "🔍 Current directory: $(pwd)"
echo "📦 Installing Flutter..."

# Download Flutter SDK
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Verify Flutter installation
echo "✅ Flutter installation complete. Checking version:"
flutter --version

# Enable web support
echo "🌐 Enabling web support..."
flutter config --enable-web

# Install dependencies
echo "📚 Getting dependencies..."
flutter pub get

# Build web app
echo "🏗️ Building web app..."
flutter build web --release

echo "🎉 Build completed successfully!"
