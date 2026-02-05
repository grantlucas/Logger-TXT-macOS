import SwiftUI
import AppKit

/// The main view for entering log entries.
struct LogEntryView: View {
    @Bindable var appState: AppState
    let onDismiss: () -> Void

    @FocusState private var focusedField: Field?
    @State private var autocompleteCoordinator = AutocompleteCoordinator()

    enum Field: Hashable {
        case message
        case type
        case project
        case saveButton
    }

    var body: some View {
        VStack(spacing: 12) {
            // Message field
            TextField("What are you working on?", text: $appState.message, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .lineLimit(5...7)
                .focused($focusedField, equals: .message)
                .onSubmit {
                    focusedField = .type
                }

            Divider()

            // Type and Project fields
            HStack(spacing: 12) {
                AutocompleteTextField(
                    fieldId: "type",
                    title: "Type",
                    text: $appState.type,
                    suggestions: appState.typeSuggestions(for: appState.type),
                    isFocused: focusedField == .type,
                    isDisabled: appState.message.isEmpty,
                    coordinator: autocompleteCoordinator,
                    onFocus: { focusedField = .type },
                    onTab: { focusedField = .project }
                )
                .focused($focusedField, equals: .type)

                AutocompleteTextField(
                    fieldId: "project",
                    title: "Project",
                    text: $appState.project,
                    suggestions: appState.projectSuggestions(for: appState.project),
                    isFocused: focusedField == .project,
                    isDisabled: appState.message.isEmpty,
                    coordinator: autocompleteCoordinator,
                    onFocus: { focusedField = .project },
                    onTab: { focusedField = .saveButton }
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
                .disabled(appState.message.isEmpty)
                .focused($focusedField, equals: .saveButton)
                .onKeyPress(.tab) {
                    focusedField = .message
                    return .handled
                }
                .onKeyPress(.return) {
                    if !appState.message.isEmpty {
                        saveEntry()
                    }
                    return .handled
                }
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
            } else {
                // Hide autocomplete when panel is hidden
                AutocompletePopoverWindow.shared.hide()
            }
        }
        .onKeyPress(.escape) {
            appState.cancelEntry()
            onDismiss()
            return .handled
        }
    }

    private func saveEntry() {
        // Commit any active autocomplete selections before saving
        autocompleteCoordinator.commitAll()

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

/// A text field with autocomplete dropdown using a popover.
struct AutocompleteTextField: View {
    let fieldId: String
    let title: String
    @Binding var text: String
    let suggestions: [String]
    let isFocused: Bool
    let isDisabled: Bool
    var coordinator: AutocompleteCoordinator?
    let onFocus: () -> Void
    let onTab: () -> Void

    @State private var selectedIndex: Int = 0
    @State private var showSuggestions: Bool = false
    @State private var anchorView: NSView?

    /// Returns filtered suggestions with optional "Create new" option prepended.
    private var displaySuggestions: [AutocompleteSuggestion] {
        guard !text.isEmpty else { return [] }

        let filtered = suggestions.filter { $0.lowercased().hasPrefix(text.lowercased()) }
        let exactMatchExists = filtered.contains { $0.lowercased() == text.lowercased() }

        var result: [AutocompleteSuggestion] = []

        // Prepend "Create new" option if typed text doesn't exactly match any suggestion
        if !exactMatchExists && !filtered.isEmpty {
            result.append(AutocompleteSuggestion(text: text, isCreateNew: true))
        }

        // Add regular suggestions
        result.append(contentsOf: filtered.map { AutocompleteSuggestion(text: $0) })

        return result
    }

    /// Returns the default selected index (skips "Create new" option if present).
    private var defaultSelectedIndex: Int {
        if let first = displaySuggestions.first, first.isCreateNew {
            return displaySuggestions.count > 1 ? 1 : 0
        }
        return 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .opacity(isDisabled ? 0.5 : 1.0)

            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .textCase(.uppercase)
                .disabled(isDisabled)
                .background(
                    ViewAnchor { view in
                        anchorView = view
                    }
                )
                .onAppear {
                    coordinator?.register(fieldId: fieldId) { [self] committedText in
                        text = committedText
                    }
                }
                .onDisappear {
                    coordinator?.unregister(fieldId: fieldId)
                }
                .onChange(of: text) { _, newValue in
                    text = newValue.uppercased()
                    selectedIndex = defaultSelectedIndex
                    showSuggestions = !displaySuggestions.isEmpty && isFocused
                    updatePendingSuggestion()
                    updatePopover()
                }
                .onChange(of: isFocused) { _, focused in
                    showSuggestions = focused && !displaySuggestions.isEmpty
                    if focused {
                        selectedIndex = defaultSelectedIndex
                        updatePendingSuggestion()
                    }
                    updatePopover()
                }
                .onChange(of: showSuggestions) { _, _ in
                    updatePopover()
                }
                .onChange(of: selectedIndex) { _, _ in
                    if showSuggestions {
                        AutocompletePopoverWindow.shared.updateSelection(selectedIndex)
                    }
                }
                .onKeyPress(.downArrow) {
                    if !displaySuggestions.isEmpty {
                        selectedIndex = min(selectedIndex + 1, displaySuggestions.count - 1)
                        showSuggestions = true
                        updatePendingSuggestion()
                    }
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    if !displaySuggestions.isEmpty {
                        selectedIndex = max(selectedIndex - 1, 0)
                        showSuggestions = true
                        updatePendingSuggestion()
                    }
                    return .handled
                }
                .onKeyPress(.tab) {
                    if showSuggestions && !displaySuggestions.isEmpty {
                        let suggestion = displaySuggestions[selectedIndex]
                        text = suggestion.text
                        showSuggestions = false
                        coordinator?.clearPending(fieldId: fieldId)
                    }
                    onTab()
                    return .handled
                }
                .onKeyPress(.return) {
                    if showSuggestions && !displaySuggestions.isEmpty {
                        let suggestion = displaySuggestions[selectedIndex]
                        text = suggestion.text
                        showSuggestions = false
                        coordinator?.clearPending(fieldId: fieldId)
                        return .handled
                    }
                    return .ignored
                }
        }
    }

    /// Updates the pending suggestion in the coordinator based on current selection.
    private func updatePendingSuggestion() {
        if !displaySuggestions.isEmpty && selectedIndex < displaySuggestions.count {
            let pendingText = displaySuggestions[selectedIndex].text
            // Only set pending if it differs from current text
            if pendingText != text {
                coordinator?.setPending(fieldId: fieldId, text: pendingText)
            } else {
                coordinator?.clearPending(fieldId: fieldId)
            }
        } else {
            coordinator?.clearPending(fieldId: fieldId)
        }
    }

    private func updatePopover() {
        guard showSuggestions, !displaySuggestions.isEmpty, let view = anchorView else {
            AutocompletePopoverWindow.shared.hide()
            return
        }

        AutocompletePopoverWindow.shared.show(
            suggestions: displaySuggestions,
            selectedIndex: selectedIndex,
            relativeTo: view,
            onSelect: { suggestion in
                text = suggestion.text
                showSuggestions = false
                coordinator?.clearPending(fieldId: fieldId)
            }
        )
    }
}

/// Helper view to capture the NSView reference for popover anchoring.
struct ViewAnchor: NSViewRepresentable {
    let onViewReady: (NSView) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            onViewReady(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            onViewReady(nsView)
        }
    }
}
