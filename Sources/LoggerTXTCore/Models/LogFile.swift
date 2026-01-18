import Foundation

/// Represents metadata about a log file.
public struct LogFile: Equatable, Sendable {
    /// The URL of the log file
    public let url: URL

    /// All entries in the log file
    public let entries: [LogEntry]

    /// All unique types found in entries
    public let types: Set<String>

    /// All unique projects found in entries
    public let projects: Set<String>

    /// The next line number to use for a new entry
    public let nextLineNumber: Int

    public init(
        url: URL,
        entries: [LogEntry],
        types: Set<String>,
        projects: Set<String>,
        nextLineNumber: Int
    ) {
        self.url = url
        self.entries = entries
        self.types = types
        self.projects = projects
        self.nextLineNumber = nextLineNumber
    }

    /// Creates a LogFile by parsing the contents at the given URL.
    public static func load(from url: URL) throws -> LogFile {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        let entries = LogLineParser.parseLines(lines)
        let types = LogLineParser.extractTypes(from: entries)
        let projects = LogLineParser.extractProjects(from: entries)
        let nextLineNumber = entries.count + 1

        return LogFile(
            url: url,
            entries: entries,
            types: types,
            projects: projects,
            nextLineNumber: nextLineNumber
        )
    }

    /// Creates an empty LogFile for a URL that doesn't exist yet.
    public static func empty(url: URL) -> LogFile {
        LogFile(
            url: url,
            entries: [],
            types: [],
            projects: [],
            nextLineNumber: 1
        )
    }
}
