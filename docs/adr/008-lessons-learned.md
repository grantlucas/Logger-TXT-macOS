# ADR 008: Lessons Learned and Pitfalls Avoided

## Status

N/A (Retrospective document)

## Overview

This document captures what worked well, what didn't, and pitfalls
encountered during the Logger-TXT Swift rewrite.

---

## What Worked Well

### 1. TDD for Core Library

Writing tests before implementation for LoggerTXTCore was highly effective:

- **Caught format issues early**: The Unicode arrow (→) vs ASCII (->) distinction
- **Clarified requirements**: Writing tests forced us to think about edge cases
- **Fast feedback loop**: `swift test` runs in <1 second
- **Confidence in refactoring**: Tests ensure behavior is preserved

### 2. Sample Data as Specification

Having `sample-logger-log.txt` with real log entries was invaluable:

- Served as the source of truth for format
- Could visually verify parser/formatter output
- Documented edge cases (entries with/without Type/Project)

### 3. Phased Implementation

Building in phases prevented scope creep:

1. Core library (testable foundation)
2. Basic app shell (verify SPM + SwiftUI works)
3. Log entry UI (core feature)
4. Autocomplete (enhancement)
5. Preferences (polish)
6. Bundle scripts (distribution)

Each phase was committable and testable independently.

### 4. SPM for Claude Code Workflow

Swift Package Manager was perfect for AI-assisted development:

- `Package.swift` is readable and editable as plain text
- No Xcode project state to corrupt
- Clear dependency declarations
- Fast `swift build` / `swift test` cycle

---

## What Didn't Work (And How We Fixed It)

### 1. SwiftUI `onKeyPress` with Modifiers

**Problem**: Tried to use `onKeyPress(.return, modifiers: .command)` for
⌘Enter save shortcut.

**Error**:

```text
extra arguments at positions #2, #3 in call
```

**Cause**: macOS 14's SwiftUI `onKeyPress` doesn't support the `modifiers:`
parameter.

**Solution**: Used a Button with `.keyboardShortcut(.return, modifiers:
.command)` instead:

```swift
Button("Save") { saveEntry() }
    .keyboardShortcut(.return, modifiers: .command)
```

### 2. @Observable Initialization Order

**Problem**: Compilation error when initializing LogFileService with a
computed property.

**Error**:

```text
'self' used in property access 'logFileURL' before all stored properties
are initialized
```

**Cause**: Swift requires all stored properties to be initialized before
accessing any property via `self`.

**Solution**: Use a local variable:

```swift
init() {
    let url = /* computed value */
    self.logFileURL = url
    self.logFileService = LogFileService(fileURL: url)  // Use local var
}
```

### 3. App Struct Init with Escaping Closure

**Problem**: Tried to connect AppState to AppDelegate in init:

```swift
init() {
    Task { @MainActor in
        appDelegate.setAppState(appState)  // ERROR
    }
}
```

**Error**:

```text
escaping closure captures mutating 'self' parameter
```

**Cause**: Task closure escapes, but `init()` context doesn't allow
escaping self capture.

**Solution**: Moved to `.onAppear` in the view:

```swift
var body: some Scene {
    MenuBarExtra(...) {
        MenuBarContent(...)
            .onAppear {
                appDelegate.setAppState(appState)
            }
    }
}
```

### 4. Empty Target Error

**Problem**: Initial `swift build` failed.

**Error**:

```text
target 'LoggerTXT' referenced in product 'LoggerTXT' is empty
```

**Cause**: Created directory structure but no source files in LoggerTXT
target.

**Solution**: Created minimal `LoggerTXTApp.swift` placeholder, then
expanded it.

---

## Decisions That Paid Off

### 1. NSPanel Over Pure SwiftUI Window

The hybrid approach (NSPanel + SwiftUI content) was essential:

- Pure SwiftUI can't create true floating panels
- NSPanel's `didResignKeyNotification` enables click-outside-to-close
- SwiftUI handles all the form UI beautifully

### 2. Conventional Commits

Making atomic commits at logical boundaries:

- Each commit is a working checkpoint
- Easy to bisect if issues arise
- Clear history of what changed when

### 3. AGENTS.md / CLAUDE.md

Creating project documentation early:

- Provides context for future AI sessions
- Documents critical constraints (log format!)
- Reduces ramp-up time

---

## What We'd Do Differently

### 1. Start with UI Spike

We built the core library first (TDD). While this was thorough, a quick UI
spike first might have revealed the SwiftUI `onKeyPress` limitation earlier.

### 2. More Integration Tests

Unit tests are comprehensive, but we lack:

- End-to-end test that creates an entry and verifies file output
- UI automation tests
- Format round-trip verification test

### 3. Error Handling

Current error handling is minimal:

- Errors are printed to console
- No user-visible error messages
- Could add alert dialogs for common failures

---

## Summary

The rewrite succeeded because of:

1. **Clear constraints** (preserve log format)
2. **Testable architecture** (core library separation)
3. **Incremental delivery** (phased approach)
4. **Right tool choices** (SPM, KeyboardShortcuts, @Observable)

The main challenges were Swift/SwiftUI API limitations that required
workarounds, not fundamental architectural issues.
