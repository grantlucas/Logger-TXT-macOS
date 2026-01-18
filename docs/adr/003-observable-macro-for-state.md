# ADR 003: @Observable Macro for State Management

## Status

Accepted

## Context

We needed a state management solution for the app. Options considered:

1. **ObservableObject + @Published** - Pre-Swift 5.9 approach
2. **@Observable macro** - New in Swift 5.9, improved in Swift 6
3. **Third-party (TCA, etc.)** - External state management frameworks

Requirements:
- Reactive updates when state changes
- Simple, minimal boilerplate
- Works well with SwiftUI
- Supports async operations (file I/O)

## Decision

We chose the `@Observable` macro (Swift 5.9+) for `AppState`:

```swift
@Observable
@MainActor
final class AppState {
    var message: String = ""
    var type: String = ""
    var project: String = ""
    var isEntryPanelShowing: Bool = false
    // ...
}
```

Views use `@Bindable` to get bindings:
```swift
struct LogEntryView: View {
    @Bindable var appState: AppState
    // ...
}
```

## Consequences

### Positive

- **Minimal boilerplate**: No need for `@Published` on every property
- **Efficient tracking**: Only properties that are actually read trigger updates
- **Modern Swift**: Aligns with Swift 6 direction
- **Clean syntax**: Properties look like normal properties
- **MainActor safety**: `@MainActor` ensures thread safety for UI state

### Negative

- **macOS 14+ required**: The `@Observable` macro requires macOS 14 (Sonoma)
- **Learning curve**: Different mental model from ObservableObject
- **Initialization gotcha**: Self-reference before all properties initialized can cause errors

### Pitfall Encountered

During implementation, we hit a compilation error:

```swift
init() {
    self.logFileURL = /* computed */
    self.logFileService = LogFileService(fileURL: logFileURL) // ERROR!
}
```

The error: "self used in property access 'logFileURL' before all stored properties are initialized"

**Solution**: Use a local variable:
```swift
init() {
    let url = /* computed */
    self.logFileURL = url
    self.logFileService = LogFileService(fileURL: url)
}
```

This is a Swift initialization order issue, not specific to `@Observable`, but the macro's code generation can make it less obvious.
