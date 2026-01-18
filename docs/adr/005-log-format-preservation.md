# ADR 005: Preserve Exact Log Format

## Status

Accepted

## Context

The existing log file format is used by external bash scripts. The format is:

```
{lineNum}→{DD/MM/YY HH:MM} {±HHMM} - [{TYPE} [({PROJECT})] - ]{message}
```

Examples from the existing log:
```
1→10/02/26 08:15 -0800 - Starting the day with coffee
2→10/02/26 08:32 -0800 - FREELANCE (OAKMONT) - Got feedback from client
8→10/02/26 11:15 -0800 - FREELANCE - Invoiced the Henderson project
```

Critical details:
- Arrow is Unicode `→` (U+2192), NOT ASCII `->`
- Date format is DD/MM/YY (European style)
- Time is 24-hour format
- Timezone has space before it: `08:15 -0800` not `08:15-0800`
- Placeholder line at end: `81→` (just line number, no content)

## Decision

We made format preservation a first-class concern:

1. **Created reference file**: `logger-txt-context/sample-logger-log.txt` with real examples
2. **Wrote format tests first**: Tests assert exact string output
3. **Used constants**: `LogLineFormatter.lineNumberSeparator = "→"`
4. **Documented the format**: In AGENTS.md and code comments

The formatter produces lines like:
```swift
public static func format(_ entry: LogEntry) -> String {
    // ... builds: "2→10/02/26 08:15 -0800 - FREELANCE (OAKMONT) - Message"
}
```

## Consequences

### Positive

- **Bash script compatibility**: Existing scripts continue to work
- **Bidirectional**: Can read old logs AND write new entries
- **Test-verified**: Format tests catch any regressions
- **Clear specification**: Sample file serves as living documentation

### Negative

- **Date format complexity**: DD/MM/YY is less common in code
- **Rigid format**: Can't easily extend without breaking compatibility
- **Timezone handling**: Must format offset manually, not use system formatters

### Parser Robustness

The parser handles edge cases:
- Lines with leading whitespace (common in log files)
- Placeholder lines at end of file
- Types with underscores (GAME_DEV)
- Entries with or without Type/Project

```swift
@Test("Parse entry with type and project")
func parseWithTypeAndProject() {
    let line = "2→10/02/26 08:32 -0800 - FREELANCE (OAKMONT) - Got feedback"
    let result = LogLineParser.parse(line)
    guard case .entry(let entry) = result else { ... }
    #expect(entry.type == "FREELANCE")
    #expect(entry.project == "OAKMONT")
}
```

### Verification Process

To verify format compatibility:
1. Read existing log file with parser
2. Re-format each entry with formatter
3. Compare output (should be identical)

This round-trip test ensures we can read what we write and write what we read.
