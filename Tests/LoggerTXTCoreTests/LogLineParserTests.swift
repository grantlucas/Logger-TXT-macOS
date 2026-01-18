import Testing
import Foundation
@testable import LoggerTXTCore

@Suite("LogLineParser Tests")
struct LogLineParserTests {
    @Test("Parse message only entry")
    func parseMessageOnly() {
        let line = "10/02/26 08:15 -0800 - Starting the day with coffee"
        let entry = LogLineParser.parse(line)

        #expect(entry != nil)
        #expect(entry?.timezoneOffset == "-0800")
        #expect(entry?.type == nil)
        #expect(entry?.project == nil)
        #expect(entry?.message == "Starting the day with coffee")
    }

    @Test("Parse entry with type only")
    func parseWithTypeOnly() {
        let line = "10/02/26 11:15 -0800 - FREELANCE - Invoiced the Henderson project"
        let entry = LogLineParser.parse(line)

        #expect(entry != nil)
        #expect(entry?.type == "FREELANCE")
        #expect(entry?.project == nil)
        #expect(entry?.message == "Invoiced the Henderson project")
    }

    @Test("Parse entry with type and project")
    func parseWithTypeAndProject() {
        let line = "10/02/26 08:32 -0800 - FREELANCE (OAKMONT) - Got feedback from the Oakmont client"
        let entry = LogLineParser.parse(line)

        #expect(entry != nil)
        #expect(entry?.type == "FREELANCE")
        #expect(entry?.project == "OAKMONT")
        #expect(entry?.message == "Got feedback from the Oakmont client")
    }

    @Test("Parse empty line returns nil")
    func parseEmptyLine() {
        let entry = LogLineParser.parse("")
        #expect(entry == nil)
    }

    @Test("Parse whitespace only line returns nil")
    func parseWhitespaceOnlyLine() {
        let entry = LogLineParser.parse("   ")
        #expect(entry == nil)
    }

    @Test("Parse invalid line returns nil")
    func parseInvalidLine() {
        let entry = LogLineParser.parse("This is not a valid log line")
        #expect(entry == nil)
    }

    @Test("Parse line with invalid date returns nil")
    func parseInvalidDate() {
        // Matches regex pattern but not a valid date
        let entry = LogLineParser.parse("99/99/99 99:99 -0800 - Invalid date")
        #expect(entry == nil)
    }

    @Test("Parse entry with underscore in type")
    func parseTypeWithUnderscore() {
        let line = "10/02/26 08:15 -0800 - GAME_DEV - Working on game"
        let entry = LogLineParser.parse(line)

        #expect(entry != nil)
        #expect(entry?.type == "GAME_DEV")
    }

    @Test("Extract types from entries")
    func extractTypes() {
        let entries = [
            LogEntry(timestamp: Date(), timezoneOffset: "-0800", type: "WORK", message: "msg"),
            LogEntry(timestamp: Date(), timezoneOffset: "-0800", type: "HOME", message: "msg"),
            LogEntry(timestamp: Date(), timezoneOffset: "-0800", type: "WORK", message: "msg"),
            LogEntry(timestamp: Date(), timezoneOffset: "-0800", message: "msg")
        ]

        let types = LogLineParser.extractTypes(from: entries)
        #expect(types == Set(["WORK", "HOME"]))
    }

    @Test("Extract projects from entries")
    func extractProjects() {
        let entries = [
            LogEntry(timestamp: Date(), timezoneOffset: "-0800", type: "WORK", project: "ALPHA", message: "msg"),
            LogEntry(timestamp: Date(), timezoneOffset: "-0800", type: "WORK", project: "BETA", message: "msg"),
            LogEntry(timestamp: Date(), timezoneOffset: "-0800", type: "WORK", project: "ALPHA", message: "msg"),
            LogEntry(timestamp: Date(), timezoneOffset: "-0800", type: "HOME", message: "msg")
        ]

        let projects = LogLineParser.extractProjects(from: entries)
        #expect(projects == Set(["ALPHA", "BETA"]))
    }

    @Test("Parse multiple lines")
    func parseMultipleLines() {
        let lines = [
            "10/02/26 08:15 -0800 - First message",
            "10/02/26 09:00 -0800 - Second message",
            "10/02/26 10:00 -0800 - Third message"
        ]

        let entries = LogLineParser.parseLines(lines)
        #expect(entries.count == 3)
        #expect(entries[0].message == "First message")
        #expect(entries[1].message == "Second message")
        #expect(entries[2].message == "Third message")
    }

    // MARK: - Recency Extraction Tests

    @Test("Extract types with recency keeps most recent date")
    func extractTypesWithRecencyKeepsMostRecentDate() {
        let olderDate = DateFormatting.parseFromLog("10/02/26 08:00")!
        let newerDate = DateFormatting.parseFromLog("10/02/26 12:00")!

        let entries = [
            LogEntry(timestamp: olderDate, timezoneOffset: "-0800", type: "WORK", message: "msg"),
            LogEntry(timestamp: newerDate, timezoneOffset: "-0800", type: "WORK", message: "msg"),
            LogEntry(timestamp: olderDate, timezoneOffset: "-0800", type: "HOME", message: "msg")
        ]

        let typesWithRecency = LogLineParser.extractTypesWithRecency(from: entries)

        #expect(typesWithRecency.count == 2)
        #expect(typesWithRecency["WORK"] == newerDate)  // Most recent date for WORK
        #expect(typesWithRecency["HOME"] == olderDate)
    }

    @Test("Extract projects with recency keeps most recent date")
    func extractProjectsWithRecencyKeepsMostRecentDate() {
        let olderDate = DateFormatting.parseFromLog("10/02/26 08:00")!
        let newerDate = DateFormatting.parseFromLog("10/02/26 12:00")!

        let entries = [
            LogEntry(timestamp: olderDate, timezoneOffset: "-0800", type: "WORK", project: "ALPHA", message: "msg"),
            LogEntry(timestamp: newerDate, timezoneOffset: "-0800", type: "WORK", project: "ALPHA", message: "msg"),
            LogEntry(timestamp: olderDate, timezoneOffset: "-0800", type: "WORK", project: "BETA", message: "msg")
        ]

        let projectsWithRecency = LogLineParser.extractProjectsWithRecency(from: entries)

        #expect(projectsWithRecency.count == 2)
        #expect(projectsWithRecency["ALPHA"] == newerDate)  // Most recent date for ALPHA
        #expect(projectsWithRecency["BETA"] == olderDate)
    }

    @Test("Extract types with recency skips nil types")
    func extractTypesWithRecencySkipsNilTypes() {
        let date = DateFormatting.parseFromLog("10/02/26 08:00")!

        let entries = [
            LogEntry(timestamp: date, timezoneOffset: "-0800", type: "WORK", message: "msg"),
            LogEntry(timestamp: date, timezoneOffset: "-0800", type: nil, message: "no type"),
            LogEntry(timestamp: date, timezoneOffset: "-0800", type: "HOME", message: "msg")
        ]

        let typesWithRecency = LogLineParser.extractTypesWithRecency(from: entries)

        #expect(typesWithRecency.count == 2)
        #expect(typesWithRecency["WORK"] != nil)
        #expect(typesWithRecency["HOME"] != nil)
    }
}
