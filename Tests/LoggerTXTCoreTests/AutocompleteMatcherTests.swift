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
}
