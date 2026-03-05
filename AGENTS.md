# Logger-TXT Development Guide

## Project Overview

Logger-TXT is a macOS menu bar application for quick
timestamped logging.
It rewrites the legacy Objective-C app in modern Swift 6.

## Key Files

- `Package.swift` - SPM package definition
- `Sources/LoggerTXTCore/` - Testable business logic library
- `Sources/LoggerTXT/` - Main app with SwiftUI UI
- `Tests/LoggerTXTCoreTests/` - Unit tests for core library
- `logger-txt-context/sample-logger-log.txt` - Reference log
  format

## Log Format (CRITICAL)

The log format must be preserved exactly for bash script
compatibility:

```text
{DD/MM/YY HH:MM} {±HHMM} - [{TYPE} [({PROJECT})] - ]{message}
```

Examples:

- `10/02/26 08:15 -0800 - Just a message`
- `10/02/26 08:32 -0800 - WORK - Message with type`
- `10/02/26 09:00 -0800 - WORK (PROJECT) - Message with type and project`

## Build Commands

```bash
make build    # Build debug version
make release  # Build release version
make test     # Run tests
make run      # Build and run the app
make stop     # Stop the running app
make restart  # Stop and restart the app
make bundle   # Create .app bundle
make install  # Bundle and install to /Applications
make clean    # Remove build artifacts
make help     # Show all commands
```

Or using Swift directly:

```bash
swift build              # Build the project
swift test               # Run tests
swift build && .build/debug/LoggerTXT  # Build and run
./Scripts/bundle.sh      # Create .app bundle
```

## Architecture

- __LoggerTXTCore__: Pure Swift library with models and
  services, fully testable
- __LoggerTXT__: SwiftUI app with AppKit integration for
  NSPanel floating window
- Uses `@Observable` macro (requires macOS 14+)
- KeyboardShortcuts for global hotkey (user-configurable, no
  default)
- LaunchAtLogin-Modern for login item support

## Commit Conventions

Use conventional commits:

- `feat:` new features
- `fix:` bug fixes
- `refactor:` code changes that neither fix bugs nor add
  features
- `test:` adding or updating tests
- `docs:` documentation changes
- `chore:` maintenance tasks

## Architecture Decision Records (ADRs)

Capture key decisions and learnings in `docs/adr/` when:

- Making significant architectural choices (e.g., choosing a
  framework,
  library, or pattern)
- Encountering and solving non-obvious problems
- Discovering limitations or pitfalls in APIs/tools
- Choosing between multiple valid approaches

Don't create ADRs for routine work. Focus on decisions that
future developers
(or AI assistants) would benefit from understanding.

Format: See existing ADRs for the template (Status, Context,
Decision, Consequences).

## Testing

Run tests with `swift test` . The core library is designed
for testability -
all business logic should have corresponding tests.

**All code changes MUST use the `/tdd` skill.** Write failing tests first,
implement minimal code to pass, then refactor. Commit after tests pass to
checkpoint before moving on.

## UI Behavior

- Global hotkey (user-configurable) summons the entry window
- Window auto-closes when clicking outside (Spotlight-like)
- Tab navigation: Message → Type → Project
- Escape closes without saving
- ⌘Enter saves entry and closes
- Type and Project fields autocomplete from existing log
  entries
- Arrow keys navigate autocomplete suggestions

## Project Structure

```text
Sources/
├── LoggerTXT/              # Main app (executable target)
│   ├── App/
│   │   ├── LoggerTXTApp.swift    # @main entry point with MenuBarExtra
│   │   ├── AppState.swift        # @Observable root state
│   │   └── AppDelegate.swift     # NSPanel management, hotkey setup
│   └── Features/
│       ├── LogEntry/
│       │   ├── LogEntryPanel.swift    # NSPanel subclass
│       │   └── LogEntryView.swift     # SwiftUI entry form
│       └── Preferences/
│           └── PreferencesView.swift  # Settings UI
└── LoggerTXTCore/          # Core library (testable business logic)
    ├── Models/
    │   ├── LogEntry.swift         # Entry data model
    │   └── LogFile.swift          # Log file metadata
    ├── Services/
    │   ├── LogFileService.swift   # Read/write operations
    │   ├── LogLineFormatter.swift # Format entries to text
    │   ├── LogLineParser.swift    # Parse text to entries
    │   └── AutocompleteMatcher.swift
    └── Utilities/
        └── DateFormatting.swift
```

## Default Log File Location

`~/Documents/Logger-TXT/log.txt`

Can be changed in Preferences.
