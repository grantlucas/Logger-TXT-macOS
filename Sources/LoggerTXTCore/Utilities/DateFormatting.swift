import Foundation

/// Utilities for formatting dates in the Logger-TXT log format.
public enum DateFormatting {
    /// The date format used in log entries: DD/MM/YY HH:MM
    private static let logDateFormat = "dd/MM/yy HH:mm"

    /// Thread-safe date formatter for log entries
    private static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = logDateFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Formats a date for display in log entries (DD/MM/YY HH:MM)
    public static func formatForLog(_ date: Date) -> String {
        logFormatter.string(from: date)
    }

    /// Parses a date string from log format (DD/MM/YY HH:MM)
    /// - Returns: The parsed date, or nil if parsing fails
    public static func parseFromLog(_ string: String) -> Date? {
        logFormatter.date(from: string)
    }

    /// Formats a date with timezone offset for the complete log timestamp
    /// - Parameters:
    ///   - date: The date to format
    ///   - timezoneOffset: The timezone offset string (e.g., "-0800")
    /// - Returns: Formatted string like "10/02/26 08:15 -0800"
    public static func formatTimestamp(_ date: Date, timezoneOffset: String) -> String {
        "\(formatForLog(date)) \(timezoneOffset)"
    }
}
