import SwiftUI
import KeyboardShortcuts
import LaunchAtLogin

struct PreferencesView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView {
            GeneralPreferencesView(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            HotkeyPreferencesView()
                .tabItem {
                    Label("Hotkey", systemImage: "keyboard")
                }
        }
        .frame(width: 450, height: 200)
    }
}

struct GeneralPreferencesView: View {
    @Bindable var appState: AppState
    @State private var isShowingFilePicker = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Log File:") {
                    HStack {
                        Text(appState.logFileURL.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("Choose...") {
                            isShowingFilePicker = true
                        }
                    }
                }
            }

            Section {
                LaunchAtLogin.Toggle("Start at Login")
            }
        }
        .formStyle(.grouped)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                appState.logFileURL = url
            }
        }
    }
}

struct HotkeyPreferencesView: View {
    var body: some View {
        Form {
            Section {
                LabeledContent("Show Entry Panel:") {
                    KeyboardShortcuts.Recorder(for: .showLogEntry)
                }
            } footer: {
                Text("This hotkey will summon the log entry window from anywhere.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
