# ADR 002: SwiftUI with NSPanel for Floating Window

## Status

Accepted

## Context

The log entry window needed to behave like Spotlight:

- Float above all other windows
- Appear when summoned by hotkey from any app
- Auto-close when clicking outside
- Accept keyboard input immediately

Pure SwiftUI windows don't provide this behavior. SwiftUI's `Window` and
`WindowGroup` scenes create standard windows that:

- Don't float above other apps by default
- Don't auto-close on focus loss
- Have standard window chrome

## Decision

We use a hybrid approach:

1. **NSPanel** (AppKit) for the window container with proper floating
   behavior
2. **NSHostingView** to embed SwiftUI content inside the panel
3. **SwiftUI** for all the actual UI (forms, text fields, buttons)

The `LogEntryPanel` class is an `NSPanel` subclass configured with:

```swift
isFloatingPanel = true
level = .floating
styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel]
titleVisibility = .hidden
titlebarAppearsTransparent = true
```

It observes `NSWindow.didResignKeyNotification` to auto-close.

## Consequences

### Positive

- **Correct floating behavior**: Window appears above all apps, exactly
  like Spotlight
- **Auto-close works**: `didResignKeyNotification` fires when clicking
  outside
- **SwiftUI for UI**: Get all SwiftUI benefits for the form (declarative,
  reactive, modern)
- **Proper focus handling**: Window can become key and accept input
  immediately
- **No title bar chrome**: Clean, minimal appearance

### Negative

- **Bridging complexity**: Need to understand both SwiftUI and AppKit
- **State synchronization**: AppState must be passed to both the panel
  and the SwiftUI view
- **Escape key handling**: Had to implement `cancelOperation(_:)` in
  NSPanel for Escape to work

### Lessons Learned

The `nonactivatingPanel` style mask is important - it allows the panel
to receive events without fully activating the app (which would bring
other windows forward).

The hosting view setup is straightforward:

```swift
let contentView = LogEntryView(appState: appState, onDismiss: { ... })
let hostingView = NSHostingView(rootView: contentView)
self.contentView = hostingView
```
