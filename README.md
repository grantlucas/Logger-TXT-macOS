# Logger-TXT

A lightweight macOS menu bar application for quick timestamped logging.
Press a global hotkey, type your thought, and it's saved to a plain text
file with a timestamp.

This is a modern rewrite of the original Logger-TXT (Objective-C) using
Swift 6 and SwiftUI.

## Features

- **Global Hotkey**: Press ⌘K (configurable) from anywhere to open the
  log entry window
- **Spotlight-like UI**: Floating window that auto-dismisses when clicking
  outside
- **Timestamped Entries**: Each entry is automatically timestamped with
  date, time, and timezone
- **Optional Categorization**: Add a type (e.g., WORK, HOME) and project
  (e.g., CLIENT-A) to entries
- **Autocomplete**: Type and project fields suggest values from your
  existing log
- **Plain Text Storage**: Logs are stored as simple text files compatible
  with grep, awk, and other Unix tools
- **Menu Bar App**: Lives in your menu bar, out of the way until needed
- **Launch at Login**: Optionally start Logger-TXT when you log in

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16+ or Swift 6.0+ toolchain

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/your-username/Logger-TXT.git
cd Logger-TXT

# Build and run
swift build && .build/debug/LoggerTXT

# Or create an app bundle
./Scripts/bundle.sh

# Install to Applications
cp -r .build/release/Logger-TXT.app /Applications/
```

## Usage

1. Launch Logger-TXT - it appears in your menu bar
2. Press ⌘K (or your configured hotkey) to open the entry window
3. Type your message
4. Optionally press Tab to add a type and/or project
5. Press ⌘Enter to save, or Escape to cancel

### Keyboard Shortcuts

| Shortcut | Action                              |
| -------- | ----------------------------------- |
| ⌘K       | Open entry window (global)          |
| Tab      | Move to next field                  |
| ⇧Tab     | Move to previous field              |
| ⌘Enter   | Save entry and close                |
| Escape   | Cancel and close                    |
| ↑↓       | Navigate autocomplete suggestions   |

### Log Format

Entries are stored in plain text with the following format:

```text
{lineNum}→{DD/MM/YY HH:MM} {±HHMM} - [{TYPE} [({PROJECT})] - ]{message}
```

Examples:

```text
1→10/02/26 08:15 -0800 - Just a quick note
2→10/02/26 08:32 -0800 - WORK - Starting on the new feature
3→10/02/26 09:00 -0800 - WORK (CLIENT-A) - Finished the API integration
```

The arrow character is Unicode `→` (U+2192).

### Default Log Location

```text
~/Documents/Logger-TXT/log.txt
```

This can be changed in Preferences (click the menu bar icon → Preferences).

## Development

### Building

```bash
make build    # Debug build
make release  # Release build
make test     # Run tests
make bundle   # Create .app bundle
make install  # Bundle and install to /Applications
```

Or using Swift directly:

```bash
swift build              # Debug build
swift build -c release   # Release build
swift test               # Run tests
```

### Running

```bash
make run      # Build and run the app
make stop     # Stop the running app
make restart  # Stop and restart the app
make clean    # Remove build artifacts
make help     # Show all available commands
```

### Project Structure

```text
Sources/
├── LoggerTXT/              # Main app (executable target)
│   ├── App/                # App entry point, state, delegate
│   └── Features/           # UI features (LogEntry, Preferences)
└── LoggerTXTCore/          # Core library (testable business logic)
    ├── Models/             # Data models
    ├── Services/           # Business logic services
    └── Utilities/          # Helper functions

Tests/
└── LoggerTXTCoreTests/     # Unit tests for core library
```

### Architecture

- **LoggerTXTCore**: Pure Swift library containing all business logic.
  No UI dependencies, fully testable.
- **LoggerTXT**: SwiftUI app with AppKit integration for the floating
  NSPanel window.
- Uses the `@Observable` macro for state management
- Dependencies managed via Swift Package Manager

### Development Practices

#### Test-Driven Development (TDD)

This project follows TDD principles:

1. **Write tests first**: Before implementing a feature, write failing
   tests that define the expected behavior
2. **Make tests pass**: Write the minimum code necessary to pass the tests
3. **Refactor**: Clean up the code while keeping tests green

All business logic lives in `LoggerTXTCore` specifically to enable
thorough testing. Run tests frequently:

```bash
swift test
```

#### Code Organization

- Keep UI logic minimal; push business logic into `LoggerTXTCore`
- Services are stateless where possible
- Models are value types (structs)

#### Commit Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` new features
- `fix:` bug fixes
- `refactor:` code changes that neither fix bugs nor add features
- `test:` adding or updating tests
- `docs:` documentation changes
- `chore:` maintenance tasks

### Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) -
  Global keyboard shortcuts
- [LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern) -
  Launch at login support

## Architecture Decision Records

Significant architectural decisions are documented in `docs/adr/`. These
capture the context, decision, and consequences of key choices made during
development.

## License

[Add your license here]

## Acknowledgments

- Original Logger-TXT concept and Objective-C implementation
- [Sindre Sorhus](https://github.com/sindresorhus) for the excellent macOS
  Swift libraries
