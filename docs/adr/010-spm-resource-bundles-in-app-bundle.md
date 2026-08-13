# ADR 010: SwiftPM Resource Bundles in the .app Bundle

## Status

Accepted

## Context

Opening Preferences → Keyboard Shortcuts killed the installed app instantly
(EXC_BREAKPOINT / SIGTRAP). The faulting thread:

```text
_assertionFailure(_:_:file:line:flags:)                        libswiftCore
closure #1 in variable initialization expression of static NSBundle.module
one-time initialization function for module
KeyboardShortcuts.RecorderCocoa.init(for:onChange:)
protocol witness for NSViewRepresentable.makeNSView(context:)
  in conformance KeyboardShortcuts._Recorder
```

`KeyboardShortcuts` sets its recorder's placeholder from a localized string
during `init` (`RecorderCocoa.swift` → `Utilities.swift`,
`NSLocalizedString(self, bundle: .module, comment:)`). For a package with
resources, SwiftPM synthesizes `Bundle.module` — and it traps rather than
returning nil:

```swift
let mainPath = Bundle.main.bundleURL.appendingPathComponent("<Pkg>_<Target>.bundle").path
let buildPath = "<absolute build dir, baked in at compile time>/<Pkg>_<Target>.bundle"
let preferredBundle = Bundle(path: mainPath)
guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
    Swift.fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
}
```

`Scripts/bundle.sh` copied only the executable into `Contents/MacOS`. Neither
candidate resolved, so the app compiled, linked, launched, and traded a
`fatalError` for the first localized string any dependency asked for.

Three things about this are worth writing down, because none of them are
obvious and each one independently hid the bug.

### `Bundle.main.bundleURL` is the .app, not Contents/Resources

Verified by running a probe binary from inside the app bundle:

```text
Bundle.main.bundleURL   = /path/to/Logger-TXT.app
Bundle.main.resourceURL = /path/to/Logger-TXT.app/Contents/Resources
accessor mainPath       = /path/to/Logger-TXT.app/KeyboardShortcuts_KeyboardShortcuts.bundle
```

The accessor has no `resourceURL` candidate. Putting the payload only in
`Contents/Resources` — the conventional home, and where every Xcode-built app
in `/Applications` keeps its SwiftPM bundles — still crashes. Those apps work
because **Xcode generates a different accessor** with a multi-candidate search
list. A bare `swift build` (ADR 001) does not, so this project cannot copy the
convention.

### The baked-in absolute build path hid it locally for months

The second candidate is an absolute path into whatever build directory produced
the binary. After `make install` on the maintainer's machine that directory
still exists, so the locally-installed app resolved the fallback and worked
fine. Every other user was broken from the first release. It only surfaced
locally when the repo directory was renamed away from the path baked into the
shipped binary.

The consequence for testing is sharp: **launching the app and clicking the tab
is not a test.** It passes on the build machine and in CI regardless of whether
the bundler is correct. Any runtime check has to move the build-directory
bundles aside first.

### `make run` cannot see the bug at all

The bare debug binary sits next to `KeyboardShortcuts_KeyboardShortcuts.bundle`
in `.build/debug`, so `Bundle.main.bundleURL` resolves and the tab works in
development. The bug is reachable only in a packaged build, in one view — and
`swift build` / `swift test` never build a package.

## Decision

**Ship the payload in `Contents/Resources` and put a relative symlink at the
.app root.** `Scripts/bundle.sh` globs `swift build -c release --show-bin-path`
for `*.bundle`, `ditto`s each into `Contents/Resources`, and symlinks it from
the root:

```bash
for resource_bundle in "$BIN_DIR"/*.bundle; do
    bundle_basename="$(basename "$resource_bundle")"
    ditto "$resource_bundle" "$RESOURCES_DIR/$bundle_basename"
    ln -s "Contents/Resources/$bundle_basename" "$BUNDLE_DIR/$bundle_basename"
done
```

`Contents/Resources` is the only part of a bundle `codesign` seals —
inspecting a signed app's `_CodeSignature/CodeResources` shows every sealed
path anchored at `Contents/`. Keeping the real bytes there means signing, if
it is ever added, seals them. The root symlink is what the accessor actually
reads. The glob means a future dependency with resources needs no edit here.

**Guard it with a structural check, not a runtime one.**
`Scripts/verify-app-bundle.sh` asserts every expected bundle resolves at the
.app root, taking the expected set from the union of two sources that each
work alone:

1. `*.bundle` in the SwiftPM bin directory, and
2. a scrape of the binary for `<Package>_<Target>.bundle` literals — which is
   what the binary *will actually ask for*, and works on an extracted release
   artifact with no build tree.

`bundle.sh` calls it before returning, so `make bundle`, `make install` and the
release workflow cannot produce an app that traps. `test.yml` builds the bundle
on every PR, so a Dependabot bump that pulls in a resource-bearing dependency
fails there rather than in the menu bar.

## Consequences

### Positive

- The packaged app works for everyone, not just on a machine whose build
  directory happens to still exist.
- No dependency is named by hand anywhere in the packaging or verification.
- The verifier reports when a build *could* lean on the absolute-path fallback,
  so that crutch can never quietly return.
- `zip -r` was replaced with `ditto -c -k` in the release workflow: `zip -r`
  follows the root symlink and stores a duplicated copy, so the artifact users
  downloaded would not have been the artifact that was verified.

### Negative

- An entry at the .app root, outside `Contents/`, is unconventional. It is
  outside the codesign seal. Today the app is unsigned so this costs nothing;
  if signing is added, run `codesign -vvv --deep --strict` and check whether the
  root symlink is objected to. If it is, replace the symlink with a real copy at
  the root — one line, and the verifier passes unchanged either way.
- CI now does a release build on every PR.

### Rejected alternatives

- **`Contents/Resources` only.** Conventional, and verified to fail: the probe
  returns nil for `Bundle(path:)` and the app traps.
- **Real copies at the .app root only.** Works, simpler, but puts the payload
  permanently outside the seal for no gain.
- **A runtime smoke test as the primary gate.** Cannot be trusted without
  hiding the build directory first, and even then needs a window server to
  render an `NSViewRepresentable`. The structural check is immune to the
  fallback and runs anywhere.
