#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Download and install Flutter
echo "Downloading Flutter..."
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable _flutter
export PATH="$PATH:`pwd`/_flutter/bin"

# Verify Flutter installation
flutter --version

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Build web app
flutter build web --release

echo "Flutter build completed successfully!"