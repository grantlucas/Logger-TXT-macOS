# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) documenting key decisions made during the Logger-TXT Swift rewrite.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [001](001-spm-over-xcode.md) | Use Swift Package Manager over Xcode | Accepted |
| [002](002-swiftui-with-nspanel.md) | SwiftUI with NSPanel for floating window | Accepted |
| [003](003-observable-macro-for-state.md) | @Observable macro for state management | Accepted |
| [004](004-core-library-separation.md) | Separate testable core library | Accepted |
| [005](005-log-format-preservation.md) | Preserve exact log format | Accepted |
| [006](006-keyboard-shortcuts-library.md) | KeyboardShortcuts for global hotkey | Accepted |
| [007](007-actor-for-file-service.md) | Swift Actor for file operations | Accepted |
| [008](008-lessons-learned.md) | Lessons learned and pitfalls avoided | N/A |

## Context

Logger-TXT is a rewrite of a legacy Objective-C macOS menu bar app. The original app provided quick timestamped logging with Type and Project categorization. The rewrite needed to:

1. Preserve the exact log file format for bash script compatibility
2. Modernize the codebase to Swift 6
3. Maintain feature parity (global hotkey, autocomplete, floating window)
4. Enable easy development iteration with Claude Code

## How to Read These ADRs

Each ADR follows a standard format:
- **Status**: Current state (Proposed, Accepted, Deprecated, Superseded)
- **Context**: The situation and constraints that led to the decision
- **Decision**: What we decided to do
- **Consequences**: The results of this decision, both positive and negative
