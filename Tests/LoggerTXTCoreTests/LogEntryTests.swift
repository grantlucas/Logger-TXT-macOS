import Testing
import Foundation
@testable import LoggerTXTCore

@Suite("LogEntry Tests")
struct LogEntryTests {
    @Test("Create entry with all fields")
    func createEntryWithAllFields() {
        let date = Date()
        let entry = LogEntry(
            timestamp: date,
            timezoneOffset: "-0800",
            type: "WORK",
            project: "PROJECT",
            message: "Test message"
        )

        #expect(entry.timestamp == date)
        #expect(entry.timezoneOffset == "-0800")
        #expect(entry.type == "WORK")
        #expect(entry.project == "PROJECT")
        #expect(entry.message == "Test message")
    }

    @Test("Create entry without type and project")
    func createEntryWithoutTypeAndProject() {
        let entry = LogEntry(
            timestamp: Date(),
            timezoneOffset: "-0800",
            message: "Simple message"
        )

        #expect(entry.type == nil)
        #expect(entry.project == nil)
    }

    @Test("Static create method uses current date")
    func staticCreateUsesCurrentDate() {
        let before = Date()
        let entry = LogEntry.create(
            type: "TEST",
            message: "Created entry"
        )
        let after = Date()

        #expect(entry.timestamp >= before)
        #expect(entry.timestamp <= after)
        #expect(entry.type == "TEST")
        #expect(entry.project == nil)
    }
}

@Suite("TimeZone Extension Tests")
struct TimeZoneExtensionTests {
    @Test("Format positive offset")
    func formatPositiveOffset() {
        let timezone = TimeZone(secondsFromGMT: 5 * 3600 + 30 * 60)! // UTC+5:30
        let offset = timezone.formattedOffset()
        #expect(offset == "+0530")
    }

    @Test("Format negative offset")
    func formatNegativeOffset() {
        let timezone = TimeZone(secondsFromGMT: -8 * 3600)! // UTC-8
        let offset = timezone.formattedOffset()
        #expect(offset == "-0800")
    }

    @Test("Format zero offset")
    func formatZeroOffset() {
        let timezone = TimeZone(secondsFromGMT: 0)! // UTC
        let offset = timezone.formattedOffset()
        #expect(offset == "+0000")
    }
}
