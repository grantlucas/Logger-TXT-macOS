#!/bin/bash
# Verify a built Logger-TXT.app carries the SwiftPM resource bundles it needs
# and has a code signature Gatekeeper will accept as intact.
#
# SwiftPM generates a Bundle.module accessor that hard-traps (Swift.fatalError)
# when the bundle is absent. Such a build compiles, links and launches fine; it
# dies the instant a dependency first reads a localized string. KeyboardShortcuts
# does that while initialising its Recorder, so the whole failure mode is
# "Preferences crashes on the Keyboard Shortcuts tab". The swiftbuild accessor
# looks in Contents/Resources; the native one does not. See docs/adr/010 and 011.
#
# usage: verify-app-bundle.sh <app-path> [--bin-dir DIR]
#
#   --bin-dir  SwiftPM bin path to read the expected bundle set from. Defaults
#              to `swift build -c release --show-bin-path`. Omitted when
#              verifying an extracted release artifact with no build tree, in
#              which case the expected set comes from the binary alone.

set -euo pipefail
shopt -s nullglob

APP=""
BIN_DIR=""
BIN_DIR_SET=0

while [ $# -gt 0 ]; do
    case "$1" in
        --bin-dir)
            BIN_DIR="$2"
            BIN_DIR_SET=1
            shift 2
            ;;
        -*)
            echo "error: unknown option $1" >&2
            exit 2
            ;;
        *)
            APP="$1"
            shift
            ;;
    esac
done

if [ -z "$APP" ]; then
    echo "usage: verify-app-bundle.sh <app-path> [--bin-dir DIR]" >&2
    exit 2
fi

if [ ! -d "$APP" ]; then
    echo "FAIL: no app bundle at $APP" >&2
    exit 1
fi

echo "Verifying $APP"

# --- structure -------------------------------------------------------------

INFO_PLIST="$APP/Contents/Info.plist"
if [ ! -f "$INFO_PLIST" ]; then
    echo "FAIL: missing $INFO_PLIST" >&2
    exit 1
fi
plutil -lint "$INFO_PLIST" > /dev/null

EXE_NAME="$(plutil -extract CFBundleExecutable raw -o - "$INFO_PLIST")"
EXE="$APP/Contents/MacOS/$EXE_NAME"
if [ ! -x "$EXE" ]; then
    echo "FAIL: CFBundleExecutable is '$EXE_NAME' but $EXE is not executable" >&2
    exit 1
fi

# --- expected resource bundles ---------------------------------------------

# Two independent sources, unioned, so neither has to be complete on its own
# and no dependency is ever named by hand here.
#
#   1. What SwiftPM emitted next to the executable.
#   2. What the binary itself will ask for. The accessor bakes the bundle name
#      in as a literal, and the <Package>_<Target>.bundle shape makes the
#      scrape specific enough to be trustworthy.
if [ "$BIN_DIR_SET" -eq 0 ]; then
    BIN_DIR="$(swift build -c release --show-bin-path 2> /dev/null || true)"
fi

expected=""
if [ -n "$BIN_DIR" ] && [ -d "$BIN_DIR" ]; then
    for resource_bundle in "$BIN_DIR"/*.bundle; do
        expected="$expected$(basename "$resource_bundle")"$'\n'
    done
else
    echo "  note: no SwiftPM bin dir; expected set derived from the binary only"
fi

scraped="$(strings -a "$EXE" \
    | grep -Eo '[A-Za-z0-9][A-Za-z0-9_.+-]*_[A-Za-z0-9_.+-]+\.bundle' \
    | sort -u || true)"
if [ -n "$scraped" ]; then
    expected="$expected$scraped"$'\n'
fi

expected="$(printf '%s' "$expected" | sort -u | sed '/^$/d')"

if [ -z "$expected" ]; then
    echo "  no SwiftPM resource bundles expected"
else
    echo "  expecting: $(echo "$expected" | tr '\n' ' ')"
fi

# --- each expected bundle must resolve where Bundle.module looks ------------

missing=0
while IFS= read -r name; do
    [ -n "$name" ] || continue
    target="$APP/Contents/Resources/$name"

    # The swiftbuild accessor's first candidate is Bundle.main.resourceURL,
    # which for an .app is Contents/Resources, inside the codesign seal.
    if [ ! -d "$target" ]; then
        echo "FAIL: $name is not in Contents/Resources" >&2
        echo "      expected: $target" >&2
        missing=1
        continue
    fi

    # `swift build` emits a flat bundle (Info.plist at the top level); Xcode
    # emits Contents/Info.plist. Accept either.
    if [ ! -f "$target/Info.plist" ] && [ ! -f "$target/Contents/Info.plist" ]; then
        echo "FAIL: $name has no Info.plist — not a loadable bundle" >&2
        missing=1
        continue
    fi

    if [ -z "$(ls -A "$target")" ]; then
        echo "FAIL: $name is empty" >&2
        missing=1
        continue
    fi

    echo "  ok: $name"
done <<< "$expected"

# --- the trap that let this ship silently ----------------------------------

# The native build system's accessor bakes in an absolute path to the build
# directory that produced the binary, and otherwise only looks at the .app
# root, never Contents/Resources. On the build machine that path exists, so the
# app works locally and traps for everyone else. The swiftbuild accessor bakes
# in no path, so any absolute bundle path in the binary means it was built
# with the wrong build system. See docs/adr/011.
baked_paths="$(strings -a "$EXE" \
    | grep -Eo '/[^"[:space:]]*/[A-Za-z0-9][A-Za-z0-9_.+-]*_[A-Za-z0-9_.+-]+\.bundle' \
    | sort -u || true)"
if [ -n "$baked_paths" ]; then
    echo "FAIL: binary was built with the native build system" >&2
    echo "      its Bundle.module only checks the .app root and these paths:" >&2
    echo "$baked_paths" | sed 's/^/        /' >&2
    echo "      build with: swift build -c release --build-system swiftbuild" >&2
    exit 1
fi

if [ "$missing" -ne 0 ]; then
    echo "FAIL: app bundle is missing SwiftPM resource bundles" >&2
    exit 1
fi

echo "OK: all SwiftPM resource bundles resolve"

# --- code signature --------------------------------------------------------

# The linker ad-hoc signs the executable on its own, and that signature claims
# the bundle has sealed resources. Without a bundle-level signature to seal
# Contents/Resources, Gatekeeper sees a broken signature on a quarantined
# download and reports the app as "damaged" with no way to open it. See
# docs/adr/011.
if ! codesign_output="$(codesign --verify --deep --strict "$APP" 2>&1)"; then
    echo "FAIL: code signature does not verify" >&2
    echo "$codesign_output" | sed 's/^/      /' >&2
    exit 1
fi

echo "OK: code signature verifies"
