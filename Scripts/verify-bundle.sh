#!/bin/bash
# Verify Logger-TXT.app ships every SwiftPM resource bundle.
#
# SwiftPM's generated Bundle.module looks for <Package>_<Target>.bundle in
# Bundle.main.resourceURL (Contents/Resources) and calls fatalError when it is
# missing. KeyboardShortcuts uses Bundle.module when the Settings recorder is
# created, so a missing bundle crashes the app the moment Settings opens.

set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR="${1:-.build/release}"
RESOURCES_DIR="$BUILD_DIR/Logger-TXT.app/Contents/Resources"

shopt -s nullglob
bundles=("$BUILD_DIR"/*.bundle)

if [ ${#bundles[@]} -eq 0 ]; then
    echo "FAIL: no SwiftPM resource bundles found in $BUILD_DIR (run a release build first)" >&2
    exit 1
fi

missing=0
for bundle in "${bundles[@]}"; do
    name="$(basename "$bundle")"
    if [ -d "$RESOURCES_DIR/$name" ]; then
        echo "ok: $name"
    else
        echo "FAIL: $name missing from $RESOURCES_DIR" >&2
        missing=1
    fi
done

exit $missing
