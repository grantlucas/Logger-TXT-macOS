import AppKit
import SwiftUI

/// A floating panel for log entry that behaves like Spotlight.
/// - Appears above other windows
/// - Closes when clicking outside
/// - Can be dismissed with Escape
@MainActor
final class LogEntryPanel: NSPanel {
    private let appState: AppState
    private var hostingView: NSHostingView<LogEntryView>?

    init(appState: AppState) {
        self.appState = appState

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 200),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupPanel()
        setupContent()
    }

    private func setupPanel() {
        // Panel appearance
        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true

        // Panel behavior
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false

        // Allow clicking outside to close
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Set up notification for losing focus
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: self
        )
    }

    private func setupContent() {
        let contentView = LogEntryView(appState: appState, onDismiss: { [weak self] in
            self?.orderOut(nil)
            self?.appState.hideEntryPanel()
        })

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        self.contentView = hostingView
        self.hostingView = hostingView

        // Set minimum size
        minSize = NSSize(width: 400, height: 150)
        maxSize = NSSize(width: 600, height: 300)
    }

    @objc private func windowDidResignKey(_ notification: Notification) {
        // Close panel when it loses focus (clicking outside)
        orderOut(nil)
        appState.hideEntryPanel()
    }

    override func cancelOperation(_ sender: Any?) {
        // Handle Escape key - clear all input and hide
        orderOut(nil)
        appState.cancelEntry()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
