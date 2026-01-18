import SwiftUI

@main
struct LoggerTXTApp: App {
    var body: some Scene {
        MenuBarExtra("Logger-TXT", systemImage: "pencil.line") {
            Text("Logger-TXT")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
