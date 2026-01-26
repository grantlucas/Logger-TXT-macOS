# macOS Swift Development with SPM for Agentic Workflows

A guide for building native macOS applications using Swift Package Manager
(SPM) instead of Xcode projects. This approach optimizes for fast iteration
cycles and works exceptionally well with AI coding assistants like Claude Code.

## Why SPM Over Xcode Projects?

Xcode projects (`.xcodeproj`) are binary-ish XML files that:

- Are difficult for AI tools to read and modify reliably
- Create merge conflicts frequently
- Require Xcode to be open for most operations
- Hide configuration in nested UI panels

SPM uses `Package.swift`—a plain Swift file that:

- Is human-readable and AI-editable
- Version controls cleanly with git
- Builds from the command line with `swift build`
- Declares dependencies explicitly

**For agentic development**, SPM enables a tight feedback loop:

1. AI modifies code
2. `make build` validates in seconds
3. `make test` runs unit tests
4. `make run` launches the app
5. Repeat

No Xcode required. No waiting for project indexing. No clicking through menus.

## Project Structure

```text
MyApp/
├── Package.swift           # SPM configuration
├── Makefile                # Development commands
├── CLAUDE.md               # AI assistant context
├── Sources/
│   ├── MyApp/              # Executable target (SwiftUI app)
│   │   ├── App/
│   │   │   ├── MyApp.swift       # @main entry point
│   │   │   ├── AppState.swift    # @Observable state
│   │   │   └── AppDelegate.swift # AppKit integration
│   │   └── Features/
│   │       └── ...               # Feature modules
│   └── MyAppCore/          # Library target (testable logic)
│       ├── Models/
│       ├── Services/
│       └── Utilities/
├── Tests/
│   └── MyAppCoreTests/     # Unit tests for core library
└── Scripts/
    └── bundle.sh           # Creates .app bundle
```

### Two-Target Architecture

Separate your project into:

1. **Core Library** (`MyAppCore`): Pure Swift with no UI dependencies
   - Models, services, utilities
   - Fully unit testable
   - Could be reused in CLI tools

2. **App Target** (`MyApp`): SwiftUI app that imports the core
   - UI code only
   - Depends on core library
   - Harder to test (requires UI automation)

This separation enables TDD for business logic while keeping UI code clean.

## Package.swift Template

```swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .macOS(.v14)  // macOS 14+ for @Observable
    ],
    products: [
        .executable(name: "MyApp", targets: ["MyApp"]),
        .library(name: "MyAppCore", targets: ["MyAppCore"])
    ],
    dependencies: [
        // Add external dependencies here
    ],
    targets: [
        .executableTarget(
            name: "MyApp",
            dependencies: ["MyAppCore"]
        ),
        .target(
            name: "MyAppCore"
        ),
        .testTarget(
            name: "MyAppCoreTests",
            dependencies: ["MyAppCore"]
        )
    ]
)
```

## Makefile as Universal Entry Point

A Makefile serves as the universal interface to your project's development
workflow. This matters for several reasons:

**Abstracts away complexity**: You don't need to remember that stopping the app
requires `pkill -x AppName 2>/dev/null`, or that release builds need
`swift build -c release`, or that cleaning requires both `swift package clean`
and `rm -rf .build`. You just type `make stop`, `make release`, or `make clean`.
The Makefile encodes the correct incantation once, and you never think about it
again.

**Reduces errors**: Dangerous or complex commands are defined once and tested.
No risk of typos in `pkill` flags or forgetting the `-c release` flag. The
Makefile is the single source of truth for how operations are performed.

**Language-agnostic commands**: Whether the project uses Swift, Rust, Go, or
Python, `make build`, `make test`, and `make run` work the same way. You don't
need to remember `swift build` vs `cargo build` vs `go build`—it's always just
`make build`.

**Self-documenting**: `make help` lists all available commands. New contributors
(human or AI) can immediately see what operations are available without reading
documentation.

**Composable workflows**: Makefiles naturally express dependencies. `make run`
depends on `make build`. `make install` depends on `make bundle`. The tool
handles ordering automatically.

**Works everywhere**: Make is installed on every Unix system. No additional
tooling required. CI systems, local development, and AI assistants all use the
same commands.

**AI-friendly**: When you document `make test` in your CLAUDE.md, the AI
doesn't need to know the underlying build system. It just runs `make test` and
interprets the output. This abstraction layer means your AI context files stay
stable even if you change build tools.

### Makefile Template

<!-- markdownlint-disable MD010 -->

```makefile
.PHONY: all build test run stop restart bundle install clean help

APP_NAME := MyApp
DEBUG_BIN := .build/debug/$(APP_NAME)
RELEASE_BIN := .build/release/$(APP_NAME)
BUNDLE_DIR := .build/release/$(APP_NAME).app

all: build

build:
	@echo "Building $(APP_NAME) (debug)..."
	@swift build
	@echo "Build complete: $(DEBUG_BIN)"

release:
	@echo "Building $(APP_NAME) (release)..."
	@swift build -c release
	@echo "Build complete: $(RELEASE_BIN)"

test:
	@echo "Running tests..."
	@swift test

run: build
	@echo "Starting $(APP_NAME)..."
	@$(DEBUG_BIN) &

stop:
	@echo "Stopping $(APP_NAME)..."
	@-pkill -x $(APP_NAME) 2>/dev/null || echo "$(APP_NAME) is not running"

restart: stop
	@sleep 0.5
	@$(MAKE) run

bundle:
	@./Scripts/bundle.sh

install: bundle
	@echo "Installing to /Applications..."
	@cp -r "$(BUNDLE_DIR)" /Applications/
	@echo "Installed $(APP_NAME).app to /Applications"

clean:
	@echo "Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build
	@echo "Clean complete"

help:
	@echo "$(APP_NAME) Development Commands"
	@echo ""
	@echo "  make build    - Build debug version"
	@echo "  make release  - Build release version"
	@echo "  make test     - Run tests"
	@echo "  make run      - Build and run the app"
	@echo "  make stop     - Stop the running app"
	@echo "  make restart  - Stop and restart the app"
	@echo "  make bundle   - Create .app bundle"
	@echo "  make install  - Bundle and install to /Applications"
	@echo "  make clean    - Remove build artifacts"
```

<!-- markdownlint-enable MD010 -->

## App Bundling Script

SPM builds executables, not `.app` bundles. Create `Scripts/bundle.sh`:

```bash
#!/bin/bash
set -e

cd "$(dirname "$0")/.."

APP_NAME="MyApp"
BUNDLE_NAME="$APP_NAME.app"
BUILD_DIR=".build/release"
BUNDLE_DIR="$BUILD_DIR/$BUNDLE_NAME"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building $APP_NAME for release..."
swift build -c release

echo "Creating app bundle..."

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

cat > "$CONTENTS_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MyApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.myapp</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MyApp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "Bundle created at: $BUNDLE_DIR"
```

Make it executable: `chmod +x Scripts/bundle.sh`

## GitHub Actions CI

Create `.github/workflows/test.yml`. Using `make` commands here ensures CI runs
the exact same operations as local development:

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode 16
        run: sudo xcode-select -s /Applications/Xcode_16.2.app

      - name: Build
        run: make build

      - name: Run tests
        run: make test
```

## AI Assistant Context (CLAUDE.md)

Create a `CLAUDE.md` file at project root to give AI assistants context:

```markdown
# MyApp Development Guide

## Build Commands
- `make build` - Build debug version
- `make test` - Run tests
- `make run` - Build and run
- `make restart` - Stop and restart

## Architecture
- **MyAppCore**: Testable business logic library
- **MyApp**: SwiftUI app with AppKit integration
- Uses `@Observable` macro (requires macOS 14+)

## Project Structure
[Document key files and their purposes]

## Commit Conventions
Use conventional commits: feat:, fix:, refactor:, test:, docs:, chore:
```

## Testing Strategy

Use Swift Testing framework (Swift 6):

```swift
import Testing
@testable import MyAppCore

@Test("Parse valid input")
func parseValidInput() {
    let result = MyParser.parse("test input")
    #expect(result != nil)
    #expect(result?.value == "expected")
}
```

Run tests: `make test`

Tests run in under a second, enabling rapid TDD cycles.

## Common Swift/SwiftUI Patterns

### @Observable State (macOS 14+)

```swift
import SwiftUI

@Observable
final class AppState {
    var isLoading = false
    var items: [Item] = []
}
```

### App Entry Point

```swift
import SwiftUI

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Your scenes here
    }
}
```

### AppDelegate for AppKit Integration

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup code
    }
}
```

---

## Menu Bar Applications

For apps that live in the menu bar (no dock icon, no main window).

### SwiftUI MenuBarExtra

```swift
@main
struct MyMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("MyApp", systemImage: "star.fill") {
            Button("Action") { /* ... */ }
            Divider()
            SettingsLink { Text("Preferences...") }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }

        Settings {
            PreferencesView()
        }
    }
}
```

### Hide Dock Icon

In `AppDelegate.applicationDidFinishLaunching`:

```swift
NSApp.setActivationPolicy(.accessory)
```

Or add to Info.plist:

```xml
<key>LSUIElement</key>
<true/>
```

### Launch at Login

Use [LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern):

```swift
// Package.swift
.package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0")

// In SwiftUI
import LaunchAtLogin

Toggle("Launch at Login", isOn: $launchAtLogin.isEnabled)
```

### Floating Panels (Spotlight-like)

SwiftUI windows can't float above other apps. Use NSPanel with SwiftUI content:

```swift
import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    init<Content: View>(content: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false

        contentView = NSHostingView(rootView: content)

        // Auto-close when clicking outside
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.orderOut(nil)
        }
    }

    // Handle Escape key
    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }
}
```

---

## Global Keyboard Shortcuts

For system-wide hotkeys that work from any application.

### KeyboardShortcuts Library

Use [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts):

```swift
// Package.swift
.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
```

#### Define Shortcut Name

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // With default shortcut
    static let myAction = Self("myAction", default: .init(.k, modifiers: .command))

    // Without default (user must set in preferences)
    static let otherAction = Self("otherAction")
}
```

#### Register Handler

In `AppDelegate.applicationDidFinishLaunching`:

```swift
KeyboardShortcuts.onKeyDown(for: .myAction) { [weak self] in
    Task { @MainActor in
        self?.performAction()
    }
}
```

#### Preferences UI

```swift
import SwiftUI
import KeyboardShortcuts

struct HotkeyPreferences: View {
    var body: some View {
        Form {
            LabeledContent("Trigger Action:") {
                KeyboardShortcuts.Recorder(for: .myAction)
            }
        }
    }
}
```

### Why Not Native APIs?

Apple's native options for global shortcuts are problematic:

- **Carbon API (CGEventTap)**: Deprecated, complex, requires accessibility
  permissions
- **NSEvent.addGlobalMonitorForEvents**: Only monitors, can't intercept
- **Shortcuts.app integration**: Overkill for simple hotkeys

KeyboardShortcuts abstracts this cleanly with:

- SwiftUI-native recorder component
- Automatic UserDefaults persistence
- System shortcut conflict detection

---

## Quick Start Checklist

1. [ ] Create project directory
2. [ ] Write `Package.swift` with two targets (app + core library)
3. [ ] Create directory structure under `Sources/`
4. [ ] Add `Makefile` with build/test/run commands
5. [ ] Write `Scripts/bundle.sh` for distribution
6. [ ] Add `CLAUDE.md` with project context
7. [ ] Set up `.github/workflows/test.yml` for CI
8. [ ] Initialize git, make first commit

Then iterate:

```bash
# Development cycle
make test     # Run tests
make restart  # Rebuild and relaunch app
```
