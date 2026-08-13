# ADR 006: KeyboardShortcuts Library for Global Hotkey

## Status

Accepted

## Context

A core feature of Logger-TXT is the user-configurable global hotkey that
summons the entry window from any application. This requires:

1. Registering a system-wide keyboard shortcut
2. Receiving callbacks when the shortcut is pressed
3. Allowing users to customize the shortcut
4. Persisting the user's choice

Options considered:

1. **Carbon API (CGEventTap)** - Low-level, deprecated, complex
2. **MASShortcut** - Objective-C library, widely used
3. **KeyboardShortcuts** - Pure Swift, SwiftUI-native, by Sindre Sorhus

## Decision

We chose [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
(currently v3.0.1) because:

- Pure Swift, SwiftUI-native
- Well-maintained by a reputable developer
- Simple API for both registration and recording
- Built-in persistence

Usage:

```swift
// Define the shortcut name. No default: the app ships with no hotkey and the
// user picks one in Preferences. (v3 renamed the initial-shortcut label to
// `initial:`; `default:` is deprecated.)
extension KeyboardShortcuts.Name {
    static let showLogEntry = Self("showLogEntry")
}

// Register handler
KeyboardShortcuts.onKeyDown(for: .showLogEntry) { [weak self] in
    self?.toggleEntryPanel()
}

// SwiftUI recorder for preferences
KeyboardShortcuts.Recorder(for: .showLogEntry)
```

## Consequences

### Positive

- **Minimal code**: Registration is one line
- **SwiftUI recorder**: Drop-in component for preferences
- **Automatic persistence**: User customizations saved to UserDefaults
- **Conflict detection**: Warns about conflicts with system shortcuts
- **Proper key handling**: Correctly handles modifier combinations

### Negative

- **External dependency**: Adds ~50KB to binary size
- **macOS only**: Not cross-platform (but neither is this app)
- **Version coupling**: Must track library updates
- **Ships localized resources**: the library reads
  `NSLocalizedString(..., bundle: .module)`
  while initialising its `Recorder`, so the `.app` must carry
  `KeyboardShortcuts_KeyboardShortcuts.bundle` or the Keyboard Shortcuts
  preferences tab hard-traps. See ADR 010.

### Integration Points

**AppDelegate.swift** - Registers the hotkey on launch:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    KeyboardShortcuts.onKeyDown(for: .showLogEntry) { [weak self] in
        Task { @MainActor in
            self?.toggleEntryPanel()
        }
    }
}
```

**PreferencesView.swift** - Provides the recorder UI:

```swift
struct HotkeyPreferencesView: View {
    var body: some View {
        Form {
            LabeledContent("Show Entry Panel:") {
                KeyboardShortcuts.Recorder(for: .showLogEntry)
            }
        }
    }
}
```

### Why Not Native APIs?

Apple's native APIs for global shortcuts are either:

- **Carbon-based** (deprecated, complex event tap registration)
- **Accessibility-dependent** (requires special permissions)

KeyboardShortcuts abstracts these away cleanly.
