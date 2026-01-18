import Testing
import Foundation
@testable import LoggerTXTCore

@Suite("LogLineFormatter Tests")
struct LogLineFormatterTests {
    // Create a fixed date for testing: 10/02/26 08:15 (Feb 10, 2026)
    let testDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 10
        components.hour = 8
        components.minute = 15
        return Calendar.current.date(from: components)!
    }()

    @Test("Format entry with message only")
    func formatMessageOnly() {
        let entry = LogEntry(
            timestamp: testDate,
            timezoneOffset: "-0800",
            message: "Starting the day with coffee"
        )

        let formatted = LogLineFormatter.format(entry)
        #expect(formatted == "10/02/26 08:15 -0800 - Starting the day with coffee")
    }

    @Test("Format entry with type only")
    func formatWithTypeOnly() {
        let entry = LogEntry(
            timestamp: testDate,
            timezoneOffset: "-0800",
            type: "FREELANCE",
            message: "Invoiced the Henderson project"
        )

        let formatted = LogLineFormatter.format(entry)
        #expect(formatted == "10/02/26 08:15 -0800 - FREELANCE - Invoiced the Henderson project")
    }

    @Test("Format entry with type and project")
    func formatWithTypeAndProject() {
        let entry = LogEntry(
            timestamp: testDate,
            timezoneOffset: "-0800",
            type: "FREELANCE",
            project: "OAKMONT",
            message: "Got feedback from the Oakmont client"
        )

        let formatted = LogLineFormatter.format(entry)
        #expect(formatted == "10/02/26 08:15 -0800 - FREELANCE (OAKMONT) - Got feedback from the Oakmont client")
    }

    @Test("Format entry with positive timezone")
    func formatWithPositiveTimezone() {
        let entry = LogEntry(
            timestamp: testDate,
            timezoneOffset: "+0530",
            message: "Test message"
        )

        let formatted = LogLineFormatter.format(entry)
        #expect(formatted.contains("+0530"))
    }
}
