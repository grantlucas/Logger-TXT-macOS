# ADR 004: Separate Testable Core Library

## Status

Accepted

## Context

The app has significant business logic:

- Log file format parsing and generation
- Date formatting in specific formats
- Autocomplete matching algorithms
- File read/write operations

This logic needed to be:

- Thoroughly tested
- Reusable (potentially in CLI tools or other apps)
- Independent of UI framework

## Decision

We split the project into two targets:

1. **LoggerTXTCore** - Pure Swift library with no UI dependencies
2. **LoggerTXT** - SwiftUI app that depends on LoggerTXTCore

LoggerTXTCore contains:

```text
LoggerTXTCore/
├── Models/
│   ├── LogEntry.swift      # Data model
│   └── LogFile.swift       # File metadata
├── Services/
│   ├── LogFileService.swift      # File I/O (actor)
│   ├── LogLineFormatter.swift    # Entry → String
│   ├── LogLineParser.swift       # String → Entry
│   └── AutocompleteMatcher.swift # Suggestion matching
└── Utilities/
    └── DateFormatting.swift      # Date ↔ String
```

## Consequences

### Positive

- **Testability**: All business logic has unit tests (37 tests)
- **TDD workflow**: Could write tests first, then implementation
- **Clear boundaries**: UI code doesn't leak into business logic
- **Reusability**: LoggerTXTCore could be used by a CLI tool
- **Fast test cycle**: `swift test` runs only the core library tests
  (no UI)

### Negative

- **Import overhead**: App code must `import LoggerTXTCore`
- **Two targets to maintain**: Changes might span both targets
- **Public API surface**: Must carefully decide what to make `public`

### Test Coverage

The core library has comprehensive tests:

- `LogEntryTests` - Model creation and factory methods
- `LogLineFormatterTests` - Format output matches expected
- `LogLineParserTests` - Parsing all entry variants
- `DateFormattingTests` - Date string round-trips
- `AutocompleteMatcherTests` - Prefix/contains matching

Example test:

```swift
@Test("Format entry with type and project")
func formatWithTypeAndProject() {
    let entry = LogEntry(
        timestamp: testDate,
        timezoneOffset: "-0800",
        type: "FREELANCE",
        project: "OAKMONT",
        message: "Got feedback"
    )
    let formatted = LogLineFormatter.format(entry)
    let expected = "10/02/26 08:15 -0800 - FREELANCE (OAKMONT) - Got feedback"
    #expect(formatted == expected)
}
```

### Why This Worked Well

The TDD approach caught issues early: ensuring the date format (DD/MM/YY)
and timezone spacing were correct. If we'd written the UI first and tested
manually, these subtle format differences might have caused bash script
compatibility issues.
