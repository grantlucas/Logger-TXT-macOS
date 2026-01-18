# Logger-TXT Development Guide

## Project Overview

Logger-TXT is a macOS menu bar application for quick timestamped logging. It rewrites the legacy Objective-C app in modern Swift 6.

## Key Files

- `Package.swift` - SPM package definition
- `Sources/LoggerTXTCore/` - Testable business logic library
- `Sources/LoggerTXT/` - Main app with SwiftUI UI
- `Tests/LoggerTXTCoreTests/` - Unit tests for core library
- `logger-txt-context/sample-logger-log.txt` - Reference log format

## Log Format (CRITICAL)

The log format must be preserved exactly for bash script compatibility:

```
{lineNum}→{DD/MM/YY HH:MM} {±HHMM} - [{TYPE} [({PROJECT})] - ]{message}
```

Examples:
- `1→10/02/26 08:15 -0800 - Just a message`
- `2→10/02/26 08:32 -0800 - WORK - Message with type`
- `3→10/02/26 09:00 -0800 - WORK (PROJECT) - Message with type and project`

The arrow is Unicode `→` (U+2192), not `->`.

## Build Commands

```bash
swift build              # Build the project
swift test               # Run tests
swift build && .build/debug/LoggerTXT  # Build and run
./Scripts/bundle.sh      # Create .app bundle
```

## Architecture

- **LoggerTXTCore**: Pure Swift library with models and services, fully testable
- **LoggerTXT**: SwiftUI app with AppKit integration for NSPanel floating window
- Uses `@Observable` macro (requires macOS 14+)
- KeyboardShortcuts for global hotkey (default ⌘K)
- LaunchAtLogin-Modern for login item support

## Commit Conventions

Use conventional commits:
- `feat:` new features
- `fix:` bug fixes
- `refactor:` code changes that neither fix bugs nor add features
- `test:` adding or updating tests
- `docs:` documentation changes
- `chore:` maintenance tasks

## Testing

Run tests with `swift test`. The core library is designed for testability - all business logic should have corresponding tests.

## UI Behavior

- Global hotkey (⌘K) summons the entry window
- Window auto-closes when clicking outside (Spotlight-like)
- Tab navigation: Message → Type → Project
- Escape closes without saving
- ⌘Enter saves entry and closes
- Type and Project fields autocomplete from existing log entries
- Arrow keys navigate autocomplete suggestions
