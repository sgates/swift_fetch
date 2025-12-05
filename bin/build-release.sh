#!/bin/bash

# Build release version of swift-fetch
# This script builds the optimized release binary and copies it to release/

set -e

echo "🔨 Building swift-fetch in release mode..."
swift build -c release

echo "📦 Creating release directory..."
mkdir -p release

echo "📋 Copying executable to release/..."
cp .build/release/swift-fetch release/

echo "✅ Build complete! Executable is at: release/swift-fetch"
echo ""
echo "Run with: ./release/swift-fetch"
