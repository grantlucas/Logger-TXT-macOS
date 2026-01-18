import Foundation

/// Service for reading and writing log files.
public actor LogFileService {
    /// The URL of the log file
    public let fileURL: URL

    /// File manager for file operations
    private let fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    /// Reads all lines from the log file.
    /// - Returns: Array of lines, or empty array if file doesn't exist
    public func readLines() throws -> [String] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return content.components(separatedBy: .newlines)
    }

    /// Reads and parses all entries from the log file.
    public func readEntries() throws -> [LogEntry] {
        let lines = try readLines()
        return LogLineParser.parseLines(lines)
    }

    /// Appends a new entry to the log file.
    /// - Parameter entry: The entry to append
    public func appendEntry(_ entry: LogEntry) throws {
        let lines = try readLines()
        var newLines = lines

        // Remove empty lines at the end
        while let last = newLines.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
            newLines.removeLast()
        }

        // Add the new entry
        let formattedEntry = LogLineFormatter.format(entry)
        newLines.append(formattedEntry)

        // Write back to file
        let content = newLines.joined(separator: "\n")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Creates the log file if it doesn't exist.
    public func createIfNeeded() throws {
        guard !fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        // Create directory if needed
        let directory = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        // Create empty file
        try "".write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Extracts all unique types from the log file.
    public func extractTypes() throws -> Set<String> {
        let entries = try readEntries()
        return LogLineParser.extractTypes(from: entries)
    }

    /// Extracts all unique projects from the log file.
    public func extractProjects() throws -> Set<String> {
        let entries = try readEntries()
        return LogLineParser.extractProjects(from: entries)
    }

    /// Extracts all types with their most recent usage date from the log file.
    public func extractTypesWithRecency() throws -> [String: Date] {
        let entries = try readEntries()
        return LogLineParser.extractTypesWithRecency(from: entries)
    }

    /// Extracts all projects with their most recent usage date from the log file.
    public func extractProjectsWithRecency() throws -> [String: Date] {
        let entries = try readEntries()
        return LogLineParser.extractProjectsWithRecency(from: entries)
    }
}

/// Convenience extension for creating a LogFileService with a default log file location.
extension LogFileService {
    /// Creates a LogFileService pointing to the default log file location.
    /// Default: ~/Documents/Logger-TXT/log.txt
    public static func defaultService() -> LogFileService {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logURL = documentsURL.appendingPathComponent("Logger-TXT/log.txt")
        return LogFileService(fileURL: logURL)
    }
}
