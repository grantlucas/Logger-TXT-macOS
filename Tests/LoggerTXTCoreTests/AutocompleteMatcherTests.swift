import Testing
import Foundation
@testable import LoggerTXTCore

@Suite("AutocompleteMatcher Tests")
struct AutocompleteMatcherTests {
    let testItems: Set<String> = ["FREELANCE", "GAMEDEV", "HOME", "LEARNING", "PODCAST", "ADMIN"]

    @Test("Match with prefix mode")
    func matchWithPrefixMode() {
        let matches = AutocompleteMatcher.match(query: "FR", items: testItems, mode: .prefix)
        #expect(matches == ["FREELANCE"])
    }

    @Test("Match is case insensitive")
    func matchIsCaseInsensitive() {
        let matches = AutocompleteMatcher.match(query: "ga", items: testItems, mode: .prefix)
        #expect(matches == ["GAMEDEV"])
    }

    @Test("Match with contains mode")
    func matchWithContainsMode() {
        let matches = AutocompleteMatcher.match(query: "DEV", items: testItems, mode: .contains)
        #expect(matches == ["GAMEDEV"])
    }

    @Test("Empty query returns all items sorted")
    func emptyQueryReturnsAllSorted() {
        let matches = AutocompleteMatcher.match(query: "", items: testItems)
        #expect(matches == ["ADMIN", "FREELANCE", "GAMEDEV", "HOME", "LEARNING", "PODCAST"])
    }

    @Test("Whitespace-only query returns all items sorted")
    func whitespaceQueryReturnsAllSorted() {
        let matches = AutocompleteMatcher.match(query: "   ", items: testItems)
        #expect(matches == ["ADMIN", "FREELANCE", "GAMEDEV", "HOME", "LEARNING", "PODCAST"])
    }

    @Test("No matches returns empty array")
    func noMatchesReturnsEmpty() {
        let matches = AutocompleteMatcher.match(query: "XYZ", items: testItems)
        #expect(matches.isEmpty)
    }

    @Test("Prefix matches come before contains matches")
    func prefixMatchesFirst() {
        let items: Set<String> = ["ALPHA", "BETA_ALPHA", "ALPHABETA"]
        let matches = AutocompleteMatcher.match(query: "ALP", items: items, mode: .contains)
        // ALPHA and ALPHABETA are prefix matches, BETA_ALPHA is contains match
        #expect(matches == ["ALPHA", "ALPHABETA", "BETA_ALPHA"])
    }

    @Test("Has exact match")
    func hasExactMatch() {
        #expect(AutocompleteMatcher.hasExactMatch(query: "HOME", items: testItems))
        #expect(AutocompleteMatcher.hasExactMatch(query: "home", items: testItems))
        #expect(!AutocompleteMatcher.hasExactMatch(query: "HOM", items: testItems))
    }

    @Test("Best match returns first alphabetical prefix match")
    func bestMatch() {
        let items: Set<String> = ["FREELANCE", "FREE_TIME", "FREEDOM"]
        let best = AutocompleteMatcher.bestMatch(query: "FREE", items: items)
        #expect(best == "FREEDOM") // First alphabetically among prefix matches
    }

    @Test("Best match returns nil for no matches")
    func bestMatchReturnsNilForNoMatches() {
        let best = AutocompleteMatcher.bestMatch(query: "XYZ", items: testItems)
        #expect(best == nil)
    }

    // MARK: - Recency-Based Sorting Tests

    @Test("Match with recency sorts by most recent first")
    func matchWithRecencySortsByMostRecentFirst() {
        let now = Date()
        let items: [String: Date] = [
            "HOME": now.addingTimeInterval(-3600),   // 1 hour ago
            "HOUSE": now.addingTimeInterval(-60)     // 1 minute ago (more recent)
        ]

        let matches = AutocompleteMatcher.match(query: "HO", items: items, mode: .prefix)
        #expect(matches == ["HOUSE", "HOME"])  // HOUSE first because more recent
    }

    @Test("Empty query with recency returns all sorted by recency then alpha")
    func emptyQueryWithRecencyReturnsAllSortedByRecency() {
        let now = Date()
        let items: [String: Date] = [
            "ALPHA": now.addingTimeInterval(-7200),  // 2 hours ago
            "BETA": now.addingTimeInterval(-60),     // 1 minute ago
            "GAMMA": now.addingTimeInterval(-3600)   // 1 hour ago
        ]

        let matches = AutocompleteMatcher.match(query: "", items: items)
        #expect(matches == ["BETA", "GAMMA", "ALPHA"])  // Most recent to oldest
    }

    @Test("Recency with prefix matches before contains matches")
    func recencyWithPrefixBeforeContainsMatches() {
        let now = Date()
        let items: [String: Date] = [
            "ALPHA": now.addingTimeInterval(-3600),      // Prefix match, older
            "ALPHABETA": now.addingTimeInterval(-60),    // Prefix match, newer
            "BETA_ALPHA": now.addingTimeInterval(-30)    // Contains match, newest
        ]

        let matches = AutocompleteMatcher.match(query: "ALP", items: items, mode: .contains)
        // Prefix matches first (sorted by recency), then contains matches
        #expect(matches == ["ALPHABETA", "ALPHA", "BETA_ALPHA"])
    }

    @Test("Identical timestamps sort alphabetically")
    func identicalTimestampsSortAlphabetically() {
        let sameTime = Date()
        let items: [String: Date] = [
            "CHARLIE": sameTime,
            "ALPHA": sameTime,
            "BETA": sameTime
        ]

        let matches = AutocompleteMatcher.match(query: "", items: items)
        #expect(matches == ["ALPHA", "BETA", "CHARLIE"])  // Alphabetical when same recency
    }

    @Test("Best match with recency returns most recent prefix match")
    func bestMatchWithRecencyReturnsMostRecentPrefixMatch() {
        let now = Date()
        let items: [String: Date] = [
            "FREELANCE": now.addingTimeInterval(-3600),  // 1 hour ago
            "FREE_TIME": now.addingTimeInterval(-60),    // 1 minute ago
            "FREEDOM": now.addingTimeInterval(-7200)     // 2 hours ago
        ]

        let best = AutocompleteMatcher.bestMatch(query: "FREE", items: items)
        #expect(best == "FREE_TIME")  // Most recent prefix match
    }

    @Test("Best match with recency returns nil for no matches")
    func bestMatchWithRecencyReturnsNilForNoMatches() {
        let items: [String: Date] = [
            "HOME": Date(),
            "WORK": Date()
        ]

        let best = AutocompleteMatcher.bestMatch(query: "XYZ", items: items)
        #expect(best == nil)
    }
}
