import SwiftUI
import LoggerTXTCore

/// Root application state using @Observable for efficient updates.
@Observable
@MainActor
final class AppState {
    // MARK: - Log Entry State

    /// The current message being composed
    var message: String = ""

    /// The current type/category being composed
    var type: String = ""

    /// The current project being composed
    var project: String = ""

    /// Whether the log entry panel is currently showing
    var isEntryPanelShowing: Bool = false

    // MARK: - Autocomplete State

    /// Available types for autocomplete
    var availableTypes: Set<String> = []

    /// Available projects for autocomplete
    var availableProjects: Set<String> = []

    // MARK: - Settings

    /// The URL of the log file
    var logFileURL: URL {
        didSet {
            UserDefaults.standard.set(logFileURL.path, forKey: "logFilePath")
            Task { await reloadAutocompleteData() }
        }
    }

    // MARK: - Services

    /// The log file service for reading/writing entries
    private var logFileService: LogFileService

    // MARK: - Initialization

    init() {
        // Load saved log file path or use default
        let url: URL
        if let savedPath = UserDefaults.standard.string(forKey: "logFilePath") {
            url = URL(fileURLWithPath: savedPath)
        } else {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            url = documentsURL.appendingPathComponent("Logger-TXT/log.txt")
        }

        self.logFileURL = url
        self.logFileService = LogFileService(fileURL: url)

        // Load autocomplete data
        Task { await reloadAutocompleteData() }
    }

    // MARK: - Actions

    /// Shows the log entry panel
    func showEntryPanel() {
        clearFields()
        isEntryPanelShowing = true
    }

    /// Hides the log entry panel
    func hideEntryPanel() {
        isEntryPanelShowing = false
        clearFields()
    }

    /// Clears all input fields
    func clearFields() {
        message = ""
        type = ""
        project = ""
    }

    /// Saves the current entry to the log file
    func saveEntry() async throws {
        guard !message.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        // Create log file if needed
        try await logFileService.createIfNeeded()

        // Get next line number
        let lineNumber = try await logFileService.getNextLineNumber()

        // Create entry
        let entry = LogEntry.create(
            lineNumber: lineNumber,
            type: type.isEmpty ? nil : type.uppercased(),
            project: project.isEmpty ? nil : project.uppercased(),
            message: message.trimmingCharacters(in: .whitespaces)
        )

        // Save to file
        try await logFileService.appendEntry(entry)

        // Update autocomplete data
        if let entryType = entry.type {
            availableTypes.insert(entryType)
        }
        if let entryProject = entry.project {
            availableProjects.insert(entryProject)
        }

        // Clear fields and hide panel
        hideEntryPanel()
    }

    /// Reloads autocomplete data from the log file
    func reloadAutocompleteData() async {
        // Update service with current URL
        logFileService = LogFileService(fileURL: logFileURL)

        do {
            availableTypes = try await logFileService.extractTypes()
            availableProjects = try await logFileService.extractProjects()
        } catch {
            // If file doesn't exist yet, just use empty sets
            availableTypes = []
            availableProjects = []
        }
    }

    /// Gets autocomplete suggestions for the type field
    func typeSuggestions(for query: String) -> [String] {
        AutocompleteMatcher.match(query: query, items: availableTypes, mode: .prefix)
    }

    /// Gets autocomplete suggestions for the project field
    func projectSuggestions(for query: String) -> [String] {
        AutocompleteMatcher.match(query: query, items: availableProjects, mode: .prefix)
    }
}
