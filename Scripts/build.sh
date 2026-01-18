#!/bin/bash
# Build Logger-TXT for debugging

set -e

cd "$(dirname "$0")/.."

echo "Building Logger-TXT..."
swift build

echo "Build complete!"
echo "Run with: .build/debug/LoggerTXT"
