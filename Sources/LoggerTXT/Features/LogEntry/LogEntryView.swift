import SwiftUI

/// The main view for entering log entries.
struct LogEntryView: View {
    @Bindable var appState: AppState
    let onDismiss: () -> Void

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case message
        case type
        case project
    }

    var body: some View {
        VStack(spacing: 12) {
            // Message field
            TextField("What are you working on?", text: $appState.message, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .lineLimit(3...5)
                .focused($focusedField, equals: .message)
                .onSubmit {
                    focusedField = .type
                }

            Divider()

            // Type and Project fields
            HStack(spacing: 12) {
                AutocompleteTextField(
                    title: "Type",
                    text: $appState.type,
                    suggestions: appState.typeSuggestions(for: appState.type),
                    isFocused: focusedField == .type,
                    onFocus: { focusedField = .type },
                    onTab: { focusedField = .project }
                )
                .focused($focusedField, equals: .type)

                AutocompleteTextField(
                    title: "Project",
                    text: $appState.project,
                    suggestions: appState.projectSuggestions(for: appState.project),
                    isFocused: focusedField == .project,
                    onFocus: { focusedField = .project },
                    onTab: { focusedField = .message }
                )
                .focused($focusedField, equals: .project)
            }

            // Keyboard shortcuts hint and save button
            HStack {
                Spacer()
                Text("⎋ Cancel")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Save") {
                    saveEntry()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            focusedField = .message
        }
        .onChange(of: appState.isEntryPanelShowing) { _, isShowing in
            if isShowing {
                focusedField = .message
            }
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    private func saveEntry() {
        Task {
            do {
                try await appState.saveEntry()
                onDismiss()
            } catch {
                // TODO: Show error to user
                print("Error saving entry: \(error)")
            }
        }
    }
}

/// A text field with autocomplete dropdown.
struct AutocompleteTextField: View {
    let title: String
    @Binding var text: String
    let suggestions: [String]
    let isFocused: Bool
    let onFocus: () -> Void
    let onTab: () -> Void

    @State private var selectedIndex: Int = 0
    @State private var showSuggestions: Bool = false

    private var filteredSuggestions: [String] {
        guard !text.isEmpty else { return [] }
        return suggestions.filter { $0.lowercased().hasPrefix(text.lowercased()) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                TextField("", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .textCase(.uppercase)
                    .onChange(of: text) { _, newValue in
                        text = newValue.uppercased()
                        selectedIndex = 0
                        showSuggestions = !filteredSuggestions.isEmpty && isFocused
                    }
                    .onChange(of: isFocused) { _, focused in
                        showSuggestions = focused && !filteredSuggestions.isEmpty
                    }
                    .onKeyPress(.downArrow) {
                        if !filteredSuggestions.isEmpty {
                            selectedIndex = min(selectedIndex + 1, filteredSuggestions.count - 1)
                            showSuggestions = true
                        }
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        if !filteredSuggestions.isEmpty {
                            selectedIndex = max(selectedIndex - 1, 0)
                            showSuggestions = true
                        }
                        return .handled
                    }
                    .onKeyPress(.tab) {
                        if showSuggestions && !filteredSuggestions.isEmpty {
                            text = filteredSuggestions[selectedIndex]
                            showSuggestions = false
                        }
                        onTab()
                        return .handled
                    }
                    .onKeyPress(.return) {
                        if showSuggestions && !filteredSuggestions.isEmpty {
                            text = filteredSuggestions[selectedIndex]
                            showSuggestions = false
                            return .handled
                        }
                        return .ignored
                    }

                // Suggestions dropdown
                if showSuggestions && !filteredSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredSuggestions.enumerated()), id: \.offset) { index, suggestion in
                            Text(suggestion)
                                .font(.system(size: 13))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(index == selectedIndex ? Color.accentColor.opacity(0.2) : Color.clear)
                                .onTapGesture {
                                    text = suggestion
                                    showSuggestions = false
                                }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.regularMaterial)
                            .shadow(radius: 4)
                    )
                    .offset(y: 30)
                    .zIndex(100)
                }
            }
        }
    }
}
