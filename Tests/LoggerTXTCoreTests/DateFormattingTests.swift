import Testing
import Foundation
@testable import LoggerTXTCore

@Suite("DateFormatting Tests")
struct DateFormattingTests {
    // Create a fixed date: Feb 10, 2026, 08:15
    let testDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 10
        components.hour = 8
        components.minute = 15
        return Calendar.current.date(from: components)!
    }()

    @Test("Format date for log")
    func formatForLog() {
        let formatted = DateFormatting.formatForLog(testDate)
        #expect(formatted == "10/02/26 08:15")
    }

    @Test("Parse date from log format")
    func parseFromLog() {
        let parsed = DateFormatting.parseFromLog("10/02/26 08:15")
        #expect(parsed != nil)

        if let parsed = parsed {
            let calendar = Calendar.current
            #expect(calendar.component(.day, from: parsed) == 10)
            #expect(calendar.component(.month, from: parsed) == 2)
            #expect(calendar.component(.year, from: parsed) == 2026)
            #expect(calendar.component(.hour, from: parsed) == 8)
            #expect(calendar.component(.minute, from: parsed) == 15)
        }
    }

    @Test("Parse invalid date returns nil")
    func parseInvalidReturnsNil() {
        #expect(DateFormatting.parseFromLog("invalid") == nil)
        #expect(DateFormatting.parseFromLog("2026-02-10") == nil)
        #expect(DateFormatting.parseFromLog("") == nil)
    }

    @Test("Format timestamp with timezone")
    func formatTimestamp() {
        let timestamp = DateFormatting.formatTimestamp(testDate, timezoneOffset: "-0800")
        #expect(timestamp == "10/02/26 08:15 -0800")
    }

    @Test("Round trip format and parse")
    func roundTrip() {
        let formatted = DateFormatting.formatForLog(testDate)
        let parsed = DateFormatting.parseFromLog(formatted)
        #expect(parsed != nil)

        if let parsed = parsed {
            let reformatted = DateFormatting.formatForLog(parsed)
            #expect(reformatted == formatted)
        }
    }
}
