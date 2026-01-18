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
    /// - Parameters:
    ///   - line: The log line to parse
    ///   - lineNumber: The line number in the file (1-indexed)
    /// - Returns: A LogEntry if parsing succeeds, nil otherwise
    public static func parse(_ line: String, lineNumber: Int) -> LogEntry? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        // Skip empty lines
        guard !trimmedLine.isEmpty else {
            return nil
        }

        // Try to parse as a full entry
        guard let match = trimmedLine.firstMatch(of: try! Regex(linePattern)) else {
            return nil
        }

        guard let dateStr = match.output[1].substring,
              let timeStr = match.output[2].substring else {
            return nil
        }

        guard let timezoneStr = match.output[3].substring else {
            return nil
        }

        guard let content = match.output[4].substring else {
            return nil
        }

        // Parse the date
        let dateTimeStr = "\(dateStr) \(timeStr)"
        guard let timestamp = DateFormatting.parseFromLog(dateTimeStr) else {
            return nil
        }

        // Parse type, project, and message from content
        let (type, project, message) = parseContent(String(content))

        return LogEntry(
            lineNumber: lineNumber,
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
        if let match = content.firstMatch(of: try! Regex(typeProjectPattern)) {
            let type = match.output[1].substring.map(String.init)
            let project = match.output[2].substring.map(String.init)
            let message = match.output[3].substring.map(String.init) ?? content

            return (type: type, project: project, message: message)
        }

        // No type/project, the entire content is the message
        return (type: nil, project: nil, message: content)
    }

    /// Parses multiple lines and returns all successfully parsed entries.
    public static func parseLines(_ lines: [String]) -> [LogEntry] {
        lines.enumerated().compactMap { index, line in
            parse(line, lineNumber: index + 1)
        }
    }

    /// Extracts all unique types from parsed entries.
    public static func extractTypes(from entries: [LogEntry]) -> Set<String> {
        Set(entries.compactMap(\.type))
    }

    /// Extracts all unique projects from parsed entries.
    public static func extractProjects(from entries: [LogEntry]) -> Set<String> {
        Set(entries.compactMap(\.project))
    }
}
