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

            UtilitiesPreferencesView(appState: appState)
                .tabItem {
                    Label("Utilities", systemImage: "wrench.and.screwdriver")
                }
        }
        .frame(width: 450, height: 200)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
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

struct UtilitiesPreferencesView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section("Autocomplete Index") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Re-scan the log file to update type and project suggestions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        Task {
                            await appState.reloadAutocompleteData()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if appState.isRefreshingAutocomplete {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Refreshing...")
                            } else {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh Index")
                            }
                        }
                    }
                    .disabled(appState.isRefreshingAutocomplete)
                }
            }
        }
        .formStyle(.grouped)
    }
}
