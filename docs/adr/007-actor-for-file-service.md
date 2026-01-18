# ADR 007: Swift Actor for File Operations

## Status

Accepted

## Context

File operations (read, write, append) need to be:

1. **Thread-safe**: Multiple parts of the app might access the log file
2. **Async**: File I/O shouldn't block the main thread
3. **Sequential**: Writes must happen in order to maintain log integrity

Swift provides several concurrency options:

1. **DispatchQueue** - GCD, traditional approach
2. **Actor** - Swift concurrency, built-in isolation
3. **@MainActor class** - Run everything on main thread

## Decision

We made `LogFileService` a Swift Actor:

```swift
public actor LogFileService {
    public let fileURL: URL
    private let fileManager: FileManager

    public func readLines() throws -> [String] { ... }
    public func readEntries() throws -> [LogEntry] { ... }
    public func appendEntry(_ entry: LogEntry) throws { ... }
    public func createIfNeeded() throws { ... }
}
```

Callers use async/await:

```swift
let lineNumber = try await logFileService.getNextLineNumber()
try await logFileService.appendEntry(entry)
```

## Consequences

### Positive

- **Automatic isolation**: Actor guarantees only one operation at a time
- **No explicit locks**: Swift compiler ensures correct synchronization
- **Clear API**: Async methods signal that work is done off main thread
- **Sendable**: Actor-isolated data is safe to pass between concurrency domains

### Negative

- **Async contagion**: All callers must be async or use Task {}
- **Can't use from synchronous contexts**: Must wrap in Task
- **Testing complexity**: Tests need async test support

### Usage Pattern

In AppState (which is `@MainActor`), we call the actor:

```swift
func saveEntry() async throws {
    try await logFileService.createIfNeeded()
    let lineNumber = try await logFileService.getNextLineNumber()
    let entry = LogEntry.create(lineNumber: lineNumber, ...)
    try await logFileService.appendEntry(entry)
}
```

From SwiftUI views:

```swift
Button("Save") {
    Task {
        try await appState.saveEntry()
    }
}
```

### Alternative Considered

We could have made LogFileService a `@MainActor` class to avoid async
complexity, but:

- File I/O would block the main thread
- Large log files could cause UI stuttering
- Not a scalable pattern

The actor approach is more correct, even if slightly more complex.

### Thread Safety Guarantee

With an actor, this sequence is safe:

1. Read file to get next line number
2. Create entry with that line number
3. Append entry to file

Without an actor, a race condition could cause two entries with the same
line number.
