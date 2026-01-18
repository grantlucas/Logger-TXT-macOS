import SwiftUI
import KeyboardShortcuts

@main
struct LoggerTXTApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Logger-TXT", systemImage: "pencil.line") {
            MenuBarContent(appState: appState, appDelegate: appDelegate)
                .onAppear {
                    // Connect app state to delegate when the view appears
                    appDelegate.setAppState(appState)
                }
        }

        Settings {
            PreferencesView(appState: appState)
        }
    }
}

struct MenuBarContent: View {
    let appState: AppState
    let appDelegate: AppDelegate

    var body: some View {
        Button("New Entry") {
            appDelegate.showEntryPanel()
        }
        .keyboardShortcut("n")

        Divider()

        SettingsLink {
            Text("Preferences...")
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit Logger-TXT") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
