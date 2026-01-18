# ADR 009: NSPopover for Autocomplete Dropdowns

## Status

Accepted

## Context

The autocomplete fields for Type and Project needed dropdown menus showing
matching suggestions. Initial implementations tried:

1. **SwiftUI `.overlay` modifier**: Dropdown clipped to parent view bounds
2. **SwiftUI `ZStack`**: Dropdown affected layout of sibling views, pushing
   them down
3. **Increased window height with spacer**: Temporary workaround, not a real
   fix
4. **Child `NSWindow`**: Caused infinite layout loop crash when hiding -
   `NSHostingView` constraint updates conflicted with window resizing

The core problem: **SwiftUI overlays and ZStacks are always clipped to their
containing window bounds**. There's no SwiftUI-native way to render content
outside the window frame.

## Decision

Use `NSPopover` for autocomplete dropdowns. NSPopover is Apple's native
solution for floating content that extends beyond window bounds.

Implementation:

```swift
final class AutocompletePopoverWindow {
    private let popover: NSPopover

    func show(suggestions: [String], relativeTo view: NSView, ...) {
        let hostingController = NSHostingController(rootView: listView)
        popover.contentViewController = hostingController
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
    }
}
```

To anchor the popover, we use `NSViewRepresentable` to capture the NSView
reference from SwiftUI:

```swift
struct ViewAnchor: NSViewRepresentable {
    let onViewReady: (NSView) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onViewReady(view) }
        return view
    }
}
```

## Consequences

### Positive

- **No clipping**: Popover extends beyond window bounds naturally
- **Native behavior**: Matches macOS autocomplete conventions
- **No layout conflicts**: Popover doesn't affect parent view layout
- **Stable**: No constraint/layout loop crashes
- **Automatic positioning**: NSPopover handles edge cases (screen bounds,
  flipping direction)

### Negative

- **Requires NSView reference**: Need NSViewRepresentable bridge to get
  anchor view
- **Mixed paradigms**: SwiftUI content inside AppKit popover inside SwiftUI
  view
- **Singleton pattern**: Using shared instance to avoid multiple popovers

### Key Insight

When you need UI that extends beyond window bounds on macOS, you must leave
pure SwiftUI. The options are:

- `NSPopover` - Best for anchored floating content (menus, tooltips,
  autocomplete)
- `NSWindow` - For independent floating windows (but beware layout loops
  with NSHostingView)
- `NSMenu` - For actual menus

SwiftUI's overlay system is for content *within* the window, not beyond it.
