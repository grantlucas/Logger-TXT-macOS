#!/bin/bash
# Run Logger-TXT tests

set -e

cd "$(dirname "$0")/.."

echo "Running tests..."
swift test

echo "All tests passed!"
