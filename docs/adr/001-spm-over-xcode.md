# ADR 001: Use Swift Package Manager over Xcode

## Status

Accepted

## Context

We needed to choose a build system for the Logger-TXT rewrite. The options were:

1. **Xcode project (.xcodeproj)** - Traditional Apple development workflow
2. **Swift Package Manager** - Command-line based, text-file configuration

Key constraints:

- Development would be done primarily with Claude Code (AI-assisted CLI workflow)
- Fast iteration cycles were essential
- The project needed to be easily buildable without opening Xcode
- Dependencies needed straightforward management

## Decision

We chose Swift Package Manager (SPM) as the build system.

The `Package.swift` file defines:

- Two targets: `LoggerTXT` (executable) and `LoggerTXTCore` (library)
- External dependencies: KeyboardShortcuts, LaunchAtLogin-Modern
- macOS 14.0 minimum deployment target

## Consequences

### Positive

- **Fast iteration**: `swift build` and `swift test` run quickly from
  the terminal
- **Text-based configuration**: `Package.swift` is easy to read, edit,
  and version control
- **No Xcode required**: Can build, test, and run entirely from
  command line
- **Claude Code friendly**: AI can easily modify Package.swift and
  understand the project structure
- **Clean dependency management**: Dependencies declared explicitly,
  fetched automatically

### Negative

- **App bundling requires manual work**: SPM doesn't create .app bundles
  automatically; we needed a custom `bundle.sh` script
- **No Interface Builder**: All UI must be code-based (which we wanted
  anyway with SwiftUI)
- **Limited Xcode integration**: Debugging in Xcode requires
  `swift package generate-xcodeproj` or opening the folder directly
- **Info.plist management**: Had to manually create Info.plist in the
  bundle script rather than having Xcode manage it

### Mitigations

The app bundling limitation was addressed by creating `Scripts/bundle.sh`
which:

1. Builds a release binary
2. Creates the .app bundle structure
3. Generates Info.plist with proper keys (LSUIElement, etc.)

This actually gave us more control over the bundle configuration.
