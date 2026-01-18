import Testing
import Foundation
@testable import LoggerTXTCore

@Suite("LogLineParser Tests")
struct LogLineParserTests {
    @Test("Parse message only entry")
    func parseMessageOnly() {
        let line = "10/02/26 08:15 -0800 - Starting the day with coffee"
        let entry = LogLineParser.parse(line, lineNumber: 1)

        #expect(entry != nil)
        #expect(entry?.lineNumber == 1)
        #expect(entry?.timezoneOffset == "-0800")
        #expect(entry?.type == nil)
        #expect(entry?.project == nil)
        #expect(entry?.message == "Starting the day with coffee")
    }

    @Test("Parse entry with type only")
    func parseWithTypeOnly() {
        let line = "10/02/26 11:15 -0800 - FREELANCE - Invoiced the Henderson project"
        let entry = LogLineParser.parse(line, lineNumber: 8)

        #expect(entry != nil)
        #expect(entry?.lineNumber == 8)
        #expect(entry?.type == "FREELANCE")
        #expect(entry?.project == nil)
        #expect(entry?.message == "Invoiced the Henderson project")
    }

    @Test("Parse entry with type and project")
    func parseWithTypeAndProject() {
        let line = "10/02/26 08:32 -0800 - FREELANCE (OAKMONT) - Got feedback from the Oakmont client"
        let entry = LogLineParser.parse(line, lineNumber: 2)

        #expect(entry != nil)
        #expect(entry?.lineNumber == 2)
        #expect(entry?.type == "FREELANCE")
        #expect(entry?.project == "OAKMONT")
        #expect(entry?.message == "Got feedback from the Oakmont client")
    }

    @Test("Parse empty line returns nil")
    func parseEmptyLine() {
        let entry = LogLineParser.parse("", lineNumber: 1)
        #expect(entry == nil)
    }

    @Test("Parse whitespace only line returns nil")
    func parseWhitespaceOnlyLine() {
        let entry = LogLineParser.parse("   ", lineNumber: 1)
        #expect(entry == nil)
    }

    @Test("Parse invalid line returns nil")
    func parseInvalidLine() {
        let entry = LogLineParser.parse("This is not a valid log line", lineNumber: 1)
        #expect(entry == nil)
    }

    @Test("Parse line with invalid date returns nil")
    func parseInvalidDate() {
        // Matches regex pattern but not a valid date
        let entry = LogLineParser.parse("99/99/99 99:99 -0800 - Invalid date", lineNumber: 1)
        #expect(entry == nil)
    }

    @Test("Parse entry with underscore in type")
    func parseTypeWithUnderscore() {
        let line = "10/02/26 08:15 -0800 - GAME_DEV - Working on game"
        let entry = LogLineParser.parse(line, lineNumber: 10)

        #expect(entry != nil)
        #expect(entry?.type == "GAME_DEV")
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

    @Test("Parse multiple lines assigns correct line numbers")
    func parseLinesAssignsLineNumbers() {
        let lines = [
            "10/02/26 08:15 -0800 - First message",
            "10/02/26 09:00 -0800 - Second message",
            "10/02/26 10:00 -0800 - Third message"
        ]

        let entries = LogLineParser.parseLines(lines)
        #expect(entries.count == 3)
        #expect(entries[0].lineNumber == 1)
        #expect(entries[1].lineNumber == 2)
        #expect(entries[2].lineNumber == 3)
    }
}
