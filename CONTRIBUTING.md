# Contributing to Logger-TXT

## Building

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

## Running

```bash
make run      # Build and run the app
make stop     # Stop the running app
make restart  # Stop and restart the app
make clean    # Remove build artifacts
make help     # Show all available commands
```

## Project Structure

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

## Architecture

- **LoggerTXTCore**: Pure Swift library containing all business logic. No UI
  dependencies, fully testable.
- **LoggerTXT**: SwiftUI app with AppKit integration for the floating NSPanel
  window.
- Uses the `@Observable` macro for state management
- Dependencies managed via Swift Package Manager

## Dependencies

- [KeyboardShortcuts][1] - Global keyboard shortcuts
- [LaunchAtLogin-Modern][2] - Launch at login support

## Development Practices

### Test-Driven Development (TDD)

This project follows TDD principles:

1. **Write tests first**: Before implementing a feature, write failing tests
   that define the expected behavior
2. **Make tests pass**: Write the minimum code necessary to pass the tests
3. **Refactor**: Clean up the code while keeping tests green

All business logic lives in `LoggerTXTCore` specifically to enable thorough
testing. Run tests frequently:

```bash
swift test
```

### Code Organization

- Keep UI logic minimal; push business logic into `LoggerTXTCore`
- Services are stateless where possible
- Models are value types (structs)

### Commit Conventions

Use [Conventional Commits][3]:

- `feat:` new features
- `fix:` bug fixes
- `refactor:` code changes that neither fix bugs nor add features
- `test:` adding or updating tests
- `docs:` documentation changes
- `chore:` maintenance tasks

## Architecture Decision Records

Significant architectural decisions are documented in `docs/adr/`. These
capture the context, decision, and consequences of key choices made during
development.

[1]: https://github.com/sindresorhus/KeyboardShortcuts
[2]: https://github.com/sindresorhus/LaunchAtLogin-Modern
[3]: https://www.conventionalcommits.org/
