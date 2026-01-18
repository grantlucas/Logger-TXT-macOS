import AppKit
import SwiftUI

/// A popover for autocomplete suggestions that can extend beyond parent window bounds.
@MainActor
final class AutocompletePopoverWindow {
    static let shared = AutocompletePopoverWindow()

    private let popover: NSPopover
    private var viewController: NSViewController?
    private var currentSuggestions: [String] = []
    private var currentSelectedIndex: Int = 0
    private var onSelectCallback: ((String) -> Void)?

    private init() {
        popover = NSPopover()
        popover.behavior = .semitransient
        popover.animates = false
    }

    func show(
        suggestions: [String],
        selectedIndex: Int,
        relativeTo view: NSView,
        onSelect: @escaping (String) -> Void
    ) {
        guard !suggestions.isEmpty else {
            hide()
            return
        }

        currentSuggestions = suggestions
        currentSelectedIndex = selectedIndex
        onSelectCallback = onSelect

        let listView = AutocompleteListView(
            suggestions: suggestions,
            selectedIndex: selectedIndex,
            onSelect: { [weak self] suggestion in
                self?.hide()
                onSelect(suggestion)
            }
        )

        let hostingController = NSHostingController(rootView: listView)

        // Calculate size based on content
        let itemHeight: CGFloat = 24
        let maxVisibleItems = 6
        let visibleItems = min(suggestions.count, maxVisibleItems)
        let height = CGFloat(visibleItems) * itemHeight + 8
        let width = max(view.bounds.width, 150)

        hostingController.view.frame = NSRect(x: 0, y: 0, width: width, height: height)
        popover.contentSize = NSSize(width: width, height: height)
        popover.contentViewController = hostingController
        viewController = hostingController

        if !popover.isShown {
            popover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
        }
    }

    func updateSelection(_ selectedIndex: Int) {
        guard popover.isShown, let onSelect = onSelectCallback else { return }

        currentSelectedIndex = selectedIndex

        let listView = AutocompleteListView(
            suggestions: currentSuggestions,
            selectedIndex: selectedIndex,
            onSelect: { [weak self] suggestion in
                self?.hide()
                onSelect(suggestion)
            }
        )

        if let hostingController = viewController as? NSHostingController<AutocompleteListView> {
            hostingController.rootView = listView
        }
    }

    func hide() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    var isShown: Bool {
        popover.isShown
    }
}

/// SwiftUI view for the autocomplete list content.
struct AutocompleteListView: View {
    let suggestions: [String]
    let selectedIndex: Int
    let onSelect: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        Text(suggestion)
                            .font(.system(size: 13))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(index == selectedIndex ? Color.accentColor.opacity(0.3) : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(suggestion)
                            }
                            .id(index)
                    }
                }
            }
            .onChange(of: selectedIndex) { _, newIndex in
                proxy.scrollTo(newIndex, anchor: .center)
            }
            .onAppear {
                proxy.scrollTo(selectedIndex, anchor: .center)
            }
        }
    }
}
