import AppKit
import SwiftUI
import KeyboardShortcuts

/// App delegate for handling app lifecycle and window management.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The floating panel for log entry
    private var entryPanel: LogEntryPanel?

    /// The app state (owned by AppDelegate to ensure availability for hotkey)
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up global hotkey
        setupHotkey()

        // Hide dock icon (we're a menu bar app)
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up
        entryPanel?.close()
    }

    // MARK: - Hotkey Setup

    private func setupHotkey() {
        KeyboardShortcuts.onKeyDown(for: .showLogEntry) { [weak self] in
            Task { @MainActor in
                self?.toggleEntryPanel()
            }
        }
    }

    // MARK: - Panel Management

    func toggleEntryPanel() {
        if let panel = entryPanel, panel.isVisible {
            hideEntryPanel()
        } else {
            showEntryPanel()
        }
    }

    func showEntryPanel() {
        // Create panel if needed
        if entryPanel == nil {
            entryPanel = LogEntryPanel(appState: appState)
        }

        appState.showEntryPanel()

        // Position panel in center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelSize = entryPanel!.frame.size
            let x = screenFrame.midX - panelSize.width / 2
            let y = screenFrame.midY - panelSize.height / 2 + 100 // Slightly above center
            entryPanel?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        entryPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hideEntryPanel() {
        entryPanel?.orderOut(nil)
        appState.hideEntryPanel()
    }
}

// MARK: - Keyboard Shortcuts Extension

extension KeyboardShortcuts.Name {
    static let showLogEntry = Self("showLogEntry")
}
