# ADR 011: Ad-Hoc Sign the App Bundle and Build with swiftbuild

## Status

Accepted. Supersedes the root symlink from
[ADR 010](010-spm-resource-bundles-in-app-bundle.md).

## Context

Release 2.0.5, installed with Homebrew, would not open. macOS said
"Logger-TXT is damaged and can't be opened. You should move it to the Trash."

`codesign` explained why:

```text
$ codesign --verify --deep --strict /Applications/Logger-TXT.app
code has no resources but signature indicates they must be present
```

The Swift linker ad-hoc signs the executable on its own (`flags=adhoc,
linker-signed`). That signature says the bundle has sealed resources, but
nothing ever signed the bundle, so there is no `_CodeSignature/CodeResources`.
Once ADR 010 put files in `Contents/Resources`, the signature no longer
matched the bundle. Homebrew downloads are quarantined, Gatekeeper checks the
signature, and a broken signature is reported as "damaged" with no way to open
the app.

Signing the bundle is the fix, but `codesign` refuses while ADR 010's symlink
sits at the `.app` root:

```text
Logger-TXT.app: unsealed contents present in the bundle root
```

A real copy at the root (ADR 010's suggested fallback) fails the same way.
Nothing outside `Contents/` can be sealed.

The root entry only existed because of which `Bundle.module` accessor SwiftPM
generates, and that depends on the build system:

| Build system | Default in | Accessor looks in |
| ------------ | ---------- | ----------------- |
| native (deprecated) | Older toolchains, including the Xcode 26 toolchain that built 2.0.5 on CI | `.app` root, then an absolute build path baked into the binary |
| swiftbuild | Swift 6.4 (verified locally) | `Contents/Resources`, then the framework bundle, then the `.app` root |

The 2.0.5 binary contains
`/Users/runner/work/Logger-TXT-macOS/Logger-TXT-macOS/.build/arm64-apple-macosx/release/KeyboardShortcuts_KeyboardShortcuts.bundle`,
which is the native accessor's baked-in fallback.

## Decision

- `Scripts/bundle.sh` builds with `--build-system swiftbuild` explicitly, so
  every toolchain generates the accessor that looks in `Contents/Resources`.
- Resource bundles go in `Contents/Resources` only. Nothing sits at the root.
- `bundle.sh` ad-hoc signs the finished bundle (`codesign --force --sign -`)
  after writing `Info.plist`, so the seal covers everything.
- `Scripts/verify-app-bundle.sh` fails when:
  - a resource bundle is missing from `Contents/Resources`,
  - `codesign --verify --deep --strict` fails, or
  - the binary contains an absolute path to a resource bundle, which only the
    native accessor bakes in.

The release workflow already runs the verifier on the extracted zip, so all
three checks cover the artifact users download.

## Consequences

### Positive

- A downloaded copy has an intact signature, so Gatekeeper treats it as an
  app from an unidentified developer rather than a damaged one. The user can
  allow it once in System Settings → Privacy & Security.
- The swiftbuild accessor has no absolute-path fallback, so launching the app
  and opening Settings is a valid test again. A missing bundle crashes on the
  build machine too.
- A build that falls back to the native build system fails verification
  instead of shipping.

### Negative

- Ad-hoc signing is not notarization. macOS still blocks the first launch,
  and the README documents the workaround. Opening cleanly needs a Developer
  ID certificate and notarization, which needs a paid Apple Developer account.
- `--build-system swiftbuild` is the default in Swift 6.4 but must be supported
  by the CI toolchain. If it is not, `bundle.sh` fails on the first PR run.
