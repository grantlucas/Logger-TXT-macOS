import Foundation

/// Formats LogEntry objects into the log file line format.
///
/// Format: `{DD/MM/YY HH:MM} {±HHMM} - [{TYPE} [({PROJECT})] - ]{message}`
///
/// Examples:
/// - `10/02/26 08:15 -0800 - Just a message`
/// - `10/02/26 08:32 -0800 - WORK - Message with type`
/// - `10/02/26 09:00 -0800 - WORK (PROJECT) - Message with type and project`
public enum LogLineFormatter {
    /// Formats a LogEntry into the log file line format.
    public static func format(_ entry: LogEntry) -> String {
        var components: [String] = []

        // Timestamp
        let timestamp = DateFormatting.formatTimestamp(entry.timestamp, timezoneOffset: entry.timezoneOffset)
        components.append(timestamp)

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
}
