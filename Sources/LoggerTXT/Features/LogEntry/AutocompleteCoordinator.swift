import Foundation

/// Coordinates autocomplete fields to commit their selections before form submission.
/// Stores pending suggestions directly to avoid stale closure captures in SwiftUI views.
@MainActor
final class AutocompleteCoordinator {
    /// Callbacks to apply committed text, keyed by fieldId.
    private var commitCallbacks: [String: (String) -> Void] = [:]
    /// Pending suggestion text to commit, keyed by fieldId.
    private var pendingSuggestions: [String: String] = [:]

    /// Registers a commit callback for an autocomplete field.
    func register(fieldId: String, onCommit: @escaping (String) -> Void) {
        commitCallbacks[fieldId] = onCommit
    }

    /// Unregisters a commit callback for an autocomplete field.
    func unregister(fieldId: String) {
        commitCallbacks.removeValue(forKey: fieldId)
        pendingSuggestions.removeValue(forKey: fieldId)
    }

    /// Sets the pending suggestion for a field.
    func setPending(fieldId: String, text: String?) {
        if let text = text {
            pendingSuggestions[fieldId] = text
        } else {
            pendingSuggestions.removeValue(forKey: fieldId)
        }
    }

    /// Clears the pending suggestion for a field (e.g., after explicit commit via Tab/Return).
    func clearPending(fieldId: String) {
        setPending(fieldId: fieldId, text: nil)
    }

    /// Commits all pending autocomplete selections.
    func commitAll() {
        for (fieldId, pendingText) in pendingSuggestions {
            if let callback = commitCallbacks[fieldId] {
                callback(pendingText)
            }
        }
        pendingSuggestions.removeAll()
    }
}
