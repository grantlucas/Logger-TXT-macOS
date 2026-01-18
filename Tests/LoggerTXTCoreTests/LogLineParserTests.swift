import Testing
import Foundation
@testable import LoggerTXTCore

@Suite("LogLineParser Tests")
struct LogLineParserTests {
    @Test("Parse message only entry")
    func parseMessageOnly() {
        let line = "1→10/02/26 08:15 -0800 - Starting the day with coffee"
        let result = LogLineParser.parse(line)

        guard case .entry(let entry) = result else {
            Issue.record("Expected entry result")
            return
        }

        #expect(entry.lineNumber == 1)
        #expect(entry.timezoneOffset == "-0800")
        #expect(entry.type == nil)
        #expect(entry.project == nil)
        #expect(entry.message == "Starting the day with coffee")
    }

    @Test("Parse entry with type only")
    func parseWithTypeOnly() {
        let line = "8→10/02/26 11:15 -0800 - FREELANCE - Invoiced the Henderson project"
        let result = LogLineParser.parse(line)

        guard case .entry(let entry) = result else {
            Issue.record("Expected entry result")
            return
        }

        #expect(entry.lineNumber == 8)
        #expect(entry.type == "FREELANCE")
        #expect(entry.project == nil)
        #expect(entry.message == "Invoiced the Henderson project")
    }

    @Test("Parse entry with type and project")
    func parseWithTypeAndProject() {
        let line = "2→10/02/26 08:32 -0800 - FREELANCE (OAKMONT) - Got feedback from the Oakmont client"
        let result = LogLineParser.parse(line)

        guard case .entry(let entry) = result else {
            Issue.record("Expected entry result")
            return
        }

        #expect(entry.lineNumber == 2)
        #expect(entry.type == "FREELANCE")
        #expect(entry.project == "OAKMONT")
        #expect(entry.message == "Got feedback from the Oakmont client")
    }

    @Test("Parse placeholder line")
    func parsePlaceholder() {
        let line = "81→"
        let result = LogLineParser.parse(line)

        guard case .placeholder(let lineNumber) = result else {
            Issue.record("Expected placeholder result")
            return
        }

        #expect(lineNumber == 81)
    }

    @Test("Parse placeholder with whitespace")
    func parsePlaceholderWithWhitespace() {
        let line = "  42→  "
        let result = LogLineParser.parse(line)

        guard case .placeholder(let lineNumber) = result else {
            Issue.record("Expected placeholder result")
            return
        }

        #expect(lineNumber == 42)
    }

    @Test("Parse invalid line returns invalid result")
    func parseInvalidLine() {
        let line = "This is not a valid log line"
        let result = LogLineParser.parse(line)

        guard case .invalid = result else {
            Issue.record("Expected invalid result")
            return
        }
    }

    @Test("Parse entry with underscore in type")
    func parseTypeWithUnderscore() {
        let line = "10→10/02/26 08:15 -0800 - GAME_DEV - Working on game"
        let result = LogLineParser.parse(line)

        guard case .entry(let entry) = result else {
            Issue.record("Expected entry result")
            return
        }

        #expect(entry.type == "GAME_DEV")
    }

    @Test("Extract types from entries")
    func extractTypes() {
        let entries = [
            LogEntry(lineNumber: 1, timestamp: Date(), timezoneOffset: "-0800", type: "WORK", message: "msg"),
            LogEntry(lineNumber: 2, timestamp: Date(), timezoneOffset: "-0800", type: "HOME", message: "msg"),
            LogEntry(lineNumber: 3, timestamp: Date(), timezoneOffset: "-0800", type: "WORK", message: "msg"),
            LogEntry(lineNumber: 4, timestamp: Date(), timezoneOffset: "-0800", message: "msg")
        ]

        let types = LogLineParser.extractTypes(from: entries)
        #expect(types == Set(["WORK", "HOME"]))
    }

    @Test("Extract projects from entries")
    func extractProjects() {
        let entries = [
            LogEntry(lineNumber: 1, timestamp: Date(), timezoneOffset: "-0800", type: "WORK", project: "ALPHA", message: "msg"),
            LogEntry(lineNumber: 2, timestamp: Date(), timezoneOffset: "-0800", type: "WORK", project: "BETA", message: "msg"),
            LogEntry(lineNumber: 3, timestamp: Date(), timezoneOffset: "-0800", type: "WORK", project: "ALPHA", message: "msg"),
            LogEntry(lineNumber: 4, timestamp: Date(), timezoneOffset: "-0800", type: "HOME", message: "msg")
        ]

        let projects = LogLineParser.extractProjects(from: entries)
        #expect(projects == Set(["ALPHA", "BETA"]))
    }

    @Test("Get next line number from entries")
    func getNextLineNumberFromEntries() {
        let results: [LogLineParser.ParseResult] = [
            .entry(LogEntry(lineNumber: 1, timestamp: Date(), timezoneOffset: "-0800", message: "msg")),
            .entry(LogEntry(lineNumber: 2, timestamp: Date(), timezoneOffset: "-0800", message: "msg")),
            .entry(LogEntry(lineNumber: 3, timestamp: Date(), timezoneOffset: "-0800", message: "msg"))
        ]

        let nextLine = LogLineParser.getNextLineNumber(from: results)
        #expect(nextLine == 4)
    }

    @Test("Get next line number from placeholder")
    func getNextLineNumberFromPlaceholder() {
        let results: [LogLineParser.ParseResult] = [
            .entry(LogEntry(lineNumber: 1, timestamp: Date(), timezoneOffset: "-0800", message: "msg")),
            .entry(LogEntry(lineNumber: 2, timestamp: Date(), timezoneOffset: "-0800", message: "msg")),
            .placeholder(lineNumber: 3)
        ]

        let nextLine = LogLineParser.getNextLineNumber(from: results)
        #expect(nextLine == 3)
    }
}
