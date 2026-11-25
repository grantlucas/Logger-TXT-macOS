# ADR 010: Ship SwiftPM Resource Bundles Inside the App

## Status

Accepted

## Context

Opening Settings crashed the app with `EXC_BREAKPOINT` in
`KeyboardShortcuts.RecorderCocoa.init`. The crashing frame was SwiftPM's
generated `Bundle.module` accessor, which calls `fatalError` when it cannot
find `KeyboardShortcuts_KeyboardShortcuts.bundle`.

`Scripts/bundle.sh` assembled the `.app` by hand and only copied the
executable. It never copied the resource bundles SwiftPM writes next to the
binary in `.build/release`.

The bug hid for a while because older toolchains baked an absolute fallback
path into the accessor, pointing at the build directory on the machine that
built it. A locally built app kept working until the checkout moved or
`.build` was cleaned. Release builds from CI pointed at the runner's path and
were always broken. Newer toolchains (Swift 6.4) drop the absolute fallback
entirely and only search:

1. `Bundle.main.resourceURL` (`Contents/Resources` in an app)
2. The resource URL of the bundle containing the module
3. `Bundle.main.bundleURL`

## Decision

- `Scripts/bundle.sh` copies every `*.bundle` from the build directory into
  `Contents/Resources`, so new dependencies with resources are picked up
  without script changes.
- `Scripts/verify-bundle.sh` fails if any `*.bundle` SwiftPM produced is
  missing from the app. The release workflow runs it before zipping, so a
  broken app never reaches the Homebrew cask.

## Consequences

### Positive

- Settings works in any installed copy, independent of where it was built
- New SwiftPM dependencies with resources are bundled automatically
- CI blocks a release whose app is missing a resource bundle

### Negative

- The verify script checks presence, not that each bundle loads correctly

### Key Insight

A hand-assembled `.app` must copy SwiftPM's `*.bundle` outputs into
`Contents/Resources`. Testing a locally built app proves nothing on older
toolchains, because the absolute fallback path can mask a missing bundle.
