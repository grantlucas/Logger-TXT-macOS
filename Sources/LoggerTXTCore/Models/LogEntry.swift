import Foundation

/// Represents a single log entry with all its components.
public struct LogEntry: Equatable, Sendable {
    /// The timestamp when the entry was created
    public let timestamp: Date

    /// The timezone offset string (e.g., "-0800", "+0530")
    public let timezoneOffset: String

    /// Optional category/type (e.g., "FREELANCE", "GAMEDEV")
    public let type: String?

    /// Optional project name (e.g., "OAKMONT", "WANDERLUST")
    public let project: String?

    /// The actual log message content
    public let message: String

    public init(
        timestamp: Date,
        timezoneOffset: String,
        type: String? = nil,
        project: String? = nil,
        message: String
    ) {
        self.timestamp = timestamp
        self.timezoneOffset = timezoneOffset
        self.type = type
        self.project = project
        self.message = message
    }

    /// Creates a new LogEntry with the current date/time and system timezone
    public static func create(
        type: String? = nil,
        project: String? = nil,
        message: String
    ) -> LogEntry {
        let now = Date()
        let offset = TimeZone.current.formattedOffset()
        return LogEntry(
            timestamp: now,
            timezoneOffset: offset,
            type: type,
            project: project,
            message: message
        )
    }
}

extension TimeZone {
    /// Returns the timezone offset formatted as ±HHMM (e.g., "-0800", "+0530")
    func formattedOffset(for date: Date = Date()) -> String {
        let seconds = secondsFromGMT(for: date)
        let hours = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        let sign = seconds >= 0 ? "+" : "-"
        return String(format: "%@%02d%02d", sign, hours, minutes)
    }
}
