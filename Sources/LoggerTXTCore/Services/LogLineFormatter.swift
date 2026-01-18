import Foundation

/// Formats LogEntry objects into the log file line format.
///
/// Format: `{lineNum}→{DD/MM/YY HH:MM} {±HHMM} - [{TYPE} [({PROJECT})] - ]{message}`
///
/// Examples:
/// - `1→10/02/26 08:15 -0800 - Just a message`
/// - `2→10/02/26 08:32 -0800 - WORK - Message with type`
/// - `3→10/02/26 09:00 -0800 - WORK (PROJECT) - Message with type and project`
public enum LogLineFormatter {
    /// The arrow separator between line number and timestamp
    public static let lineNumberSeparator = "→"

    /// Formats a LogEntry into the log file line format.
    public static func format(_ entry: LogEntry) -> String {
        var components: [String] = []

        // Line number and timestamp
        let timestamp = DateFormatting.formatTimestamp(entry.timestamp, timezoneOffset: entry.timezoneOffset)
        components.append("\(entry.lineNumber)\(lineNumberSeparator)\(timestamp)")

        // Build the content part after the timestamp
        var contentParts: [String] = []

        if let type = entry.type, !type.isEmpty {
            if let project = entry.project, !project.isEmpty {
                contentParts.append("\(type) (\(project))")
            } else {
                contentParts.append(type)
            }
        }

        contentParts.append(entry.message)

        // Join with " - "
        components.append(contentParts.joined(separator: " - "))

        return components.joined(separator: " - ")
    }

    /// Formats the placeholder line that appears at the end of the log file.
    /// This is the empty line with just a line number that indicates where the next entry goes.
    public static func formatPlaceholder(lineNumber: Int) -> String {
        "\(lineNumber)\(lineNumberSeparator)"
    }
}
