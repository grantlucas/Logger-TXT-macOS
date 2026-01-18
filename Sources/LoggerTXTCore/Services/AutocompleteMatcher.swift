import Foundation

/// Provides autocomplete matching functionality for types and projects.
public enum AutocompleteMatcher {
    /// Match mode for autocomplete
    public enum MatchMode: Sendable {
        /// Matches if the item starts with the query (case-insensitive)
        case prefix
        /// Matches if the item contains the query anywhere (case-insensitive)
        case contains
    }

    /// Filters and sorts suggestions based on a query string.
    /// - Parameters:
    ///   - query: The user's input to match against
    ///   - items: The set of possible items to match
    ///   - mode: The matching mode to use
    /// - Returns: Array of matching items, sorted with prefix matches first, then by alphabetical order
    public static func match(
        query: String,
        items: Set<String>,
        mode: MatchMode = .prefix
    ) -> [String] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)

        guard !trimmedQuery.isEmpty else {
            // Return all items sorted alphabetically when query is empty
            return items.sorted()
        }

        let lowercaseQuery = trimmedQuery.lowercased()

        // Separate prefix matches from contains-only matches for better sorting
        var prefixMatches: [String] = []
        var containsMatches: [String] = []

        for item in items {
            let lowercaseItem = item.lowercased()

            if lowercaseItem.hasPrefix(lowercaseQuery) {
                prefixMatches.append(item)
            } else if mode == .contains && lowercaseItem.contains(lowercaseQuery) {
                containsMatches.append(item)
            }
        }

        // Sort each group alphabetically, then combine with prefix matches first
        prefixMatches.sort()
        containsMatches.sort()

        return prefixMatches + containsMatches
    }

    /// Checks if a query has an exact match in the items set (case-insensitive).
    public static func hasExactMatch(query: String, items: Set<String>) -> Bool {
        let lowercaseQuery = query.lowercased().trimmingCharacters(in: .whitespaces)
        return items.contains { $0.lowercased() == lowercaseQuery }
    }

    /// Returns the best match for a query, or nil if no matches.
    /// "Best" is defined as the first prefix match alphabetically.
    public static func bestMatch(query: String, items: Set<String>) -> String? {
        match(query: query, items: items, mode: .prefix).first
    }
}
