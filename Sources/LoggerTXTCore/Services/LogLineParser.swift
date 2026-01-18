import Foundation

/// Parses log file lines into LogEntry objects.
///
/// Format: `{lineNum}→{DD/MM/YY HH:MM} {±HHMM} - [{TYPE} [({PROJECT})] - ]{message}`
public enum LogLineParser {
    /// Result of parsing a log line
    public enum ParseResult: Equatable, Sendable {
        /// Successfully parsed a complete log entry
        case entry(LogEntry)
        /// Parsed a placeholder line (just line number, no content)
        case placeholder(lineNumber: Int)
        /// Failed to parse the line
        case invalid(reason: String)
    }

    /// Regular expression pattern for parsing log lines
    /// Captures: lineNumber, date, time, timezone, content
    private static let linePattern = #"^(\d+)→(\d{2}/\d{2}/\d{2}) (\d{2}:\d{2}) ([+-]\d{4}) - (.+)$"#

    /// Pattern for type and optional project: "TYPE (PROJECT) - " or "TYPE - "
    private static let typeProjectPattern = #"^([A-Z0-9_]+)(?: \(([^)]+)\))? - (.+)$"#

    /// Pattern for placeholder lines (just line number)
    private static let placeholderPattern = #"^(\d+)→\s*$"#

    /// Parses a single log line into a ParseResult.
    public static func parse(_ line: String) -> ParseResult {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        // Check for placeholder line first
        if let placeholderMatch = trimmedLine.firstMatch(of: try! Regex(placeholderPattern)) {
            if let lineNumStr = placeholderMatch.output[1].substring,
               let lineNum = Int(lineNumStr) {
                return .placeholder(lineNumber: lineNum)
            }
        }

        // Try to parse as a full entry
        guard let match = trimmedLine.firstMatch(of: try! Regex(linePattern)) else {
            return .invalid(reason: "Line does not match expected format")
        }

        guard let lineNumStr = match.output[1].substring,
              let lineNum = Int(lineNumStr) else {
            return .invalid(reason: "Invalid line number")
        }

        guard let dateStr = match.output[2].substring,
              let timeStr = match.output[3].substring else {
            return .invalid(reason: "Invalid date/time")
        }

        guard let timezoneStr = match.output[4].substring else {
            return .invalid(reason: "Invalid timezone")
        }

        guard let content = match.output[5].substring else {
            return .invalid(reason: "Missing content")
        }

        // Parse the date
        let dateTimeStr = "\(dateStr) \(timeStr)"
        guard let timestamp = DateFormatting.parseFromLog(dateTimeStr) else {
            return .invalid(reason: "Could not parse date: \(dateTimeStr)")
        }

        // Parse type, project, and message from content
        let (type, project, message) = parseContent(String(content))

        let entry = LogEntry(
            lineNumber: lineNum,
            timestamp: timestamp,
            timezoneOffset: String(timezoneStr),
            type: type,
            project: project,
            message: message
        )

        return .entry(entry)
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
        lines.compactMap { line in
            if case .entry(let entry) = parse(line) {
                return entry
            }
            return nil
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

    /// Gets the next line number based on parsed results.
    /// Returns the line number from a placeholder, or the highest entry line number + 1.
    public static func getNextLineNumber(from results: [ParseResult]) -> Int {
        var maxLineNumber = 0

        for result in results {
            switch result {
            case .placeholder(let lineNumber):
                return lineNumber
            case .entry(let entry):
                maxLineNumber = max(maxLineNumber, entry.lineNumber)
            case .invalid:
                continue
            }
        }

        return maxLineNumber + 1
    }
}
