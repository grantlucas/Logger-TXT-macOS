import Foundation

/// Parses log file lines into LogEntry objects.
///
/// Format: `{DD/MM/YY HH:MM} {±HHMM} - [{TYPE} [({PROJECT})] - ]{message}`
public enum LogLineParser {
    /// Regular expression pattern for parsing log lines
    /// Captures: date, time, timezone, content
    private static let linePattern = #"^(\d{2}/\d{2}/\d{2}) (\d{2}:\d{2}) ([+-]\d{4}) - (.+)$"#

    /// Pattern for type and optional project: "TYPE (PROJECT) - " or "TYPE - "
    private static let typeProjectPattern = #"^([A-Z0-9_]+)(?: \(([^)]+)\))? - (.+)$"#

    /// Parses a single log line into a LogEntry.
    /// - Parameter line: The log line to parse
    /// - Returns: A LogEntry if parsing succeeds, nil otherwise
    public static func parse(_ line: String) -> LogEntry? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        // Skip empty lines
        guard !trimmedLine.isEmpty else {
            return nil
        }

        // Try to parse as a full entry
        guard let match = trimmedLine.firstMatch(of: try! Regex(linePattern)) else {
            return nil
        }

        // If the regex matched, all capture groups are guaranteed to have values
        let dateStr = match.output[1].substring!
        let timeStr = match.output[2].substring!
        let timezoneStr = match.output[3].substring!
        let content = match.output[4].substring!

        // Parse the date
        let dateTimeStr = "\(dateStr) \(timeStr)"
        guard let timestamp = DateFormatting.parseFromLog(dateTimeStr) else {
            return nil
        }

        // Parse type, project, and message from content
        let (type, project, message) = parseContent(String(content))

        return LogEntry(
            timestamp: timestamp,
            timezoneOffset: String(timezoneStr),
            type: type,
            project: project,
            message: message
        )
    }

    /// Parses the content portion of a log line to extract type, project, and message.
    private static func parseContent(_ content: String) -> (type: String?, project: String?, message: String) {
        // Try to match "TYPE (PROJECT) - message" or "TYPE - message"
        guard let match = content.firstMatch(of: try! Regex(typeProjectPattern)) else {
            // No type/project, the entire content is the message
            return (type: nil, project: nil, message: content)
        }

        // If the regex matched, type (group 1) and message (group 3) are guaranteed
        // Project (group 2) is optional due to the (?: ...)? in the pattern
        let type = match.output[1].substring!
        let message = match.output[3].substring!
        let project = match.output[2].substring.map(String.init)

        return (type: String(type), project: project, message: String(message))
    }

    /// Parses multiple lines and returns all successfully parsed entries.
    public static func parseLines(_ lines: [String]) -> [LogEntry] {
        lines.compactMap { parse($0) }
    }

    /// Extracts all unique types from parsed entries.
    public static func extractTypes(from entries: [LogEntry]) -> Set<String> {
        Set(entries.compactMap(\.type))
    }

    /// Extracts all unique projects from parsed entries.
    public static func extractProjects(from entries: [LogEntry]) -> Set<String> {
        Set(entries.compactMap(\.project))
    }

    // MARK: - Recency Extraction

    /// Extracts all types with their most recent usage date.
    /// - Parameter entries: The log entries to extract from
    /// - Returns: Dictionary mapping type names to their most recent timestamp
    public static func extractTypesWithRecency(from entries: [LogEntry]) -> [String: Date] {
        var result: [String: Date] = [:]
        for entry in entries {
            guard let type = entry.type else { continue }
            if let existingDate = result[type] {
                if entry.timestamp > existingDate {
                    result[type] = entry.timestamp
                }
            } else {
                result[type] = entry.timestamp
            }
        }
        return result
    }

    /// Extracts all projects with their most recent usage date.
    /// - Parameter entries: The log entries to extract from
    /// - Returns: Dictionary mapping project names to their most recent timestamp
    public static func extractProjectsWithRecency(from entries: [LogEntry]) -> [String: Date] {
        var result: [String: Date] = [:]
        for entry in entries {
            guard let project = entry.project else { continue }
            if let existingDate = result[project] {
                if entry.timestamp > existingDate {
                    result[project] = entry.timestamp
                }
            } else {
                result[project] = entry.timestamp
            }
        }
        return result
    }
}
