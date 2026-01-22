//
//  FindReplaceViewModel.swift
//  Manuscript
//
//  View model managing find & replace state and logic
//

import SwiftUI
import Combine
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// View model for managing find & replace functionality
@MainActor
final class FindReplaceViewModel: ObservableObject {

    // MARK: - Published State

    /// The text to search for
    @Published var searchText: String = "" {
        didSet {
            debounceSearch()
        }
    }

    /// The text to replace with
    @Published var replaceText: String = ""

    /// Whether the find bar is visible
    @Published var isVisible: Bool = false {
        didSet {
            if !isVisible {
                clearHighlights()
            }
        }
    }

    /// Whether replace mode is active (shows replace field and buttons)
    @Published var isReplaceMode: Bool = false

    /// Whether search is case-sensitive
    @Published var isCaseSensitive: Bool = false {
        didSet {
            performSearch()
        }
    }

    /// All found match ranges
    @Published private(set) var matches: [NSRange] = []

    /// Index of the current match (0-based)
    @Published private(set) var currentMatchIndex: Int = 0

    /// Total number of matches
    var totalMatches: Int { matches.count }

    /// Display string for match count (e.g., "3 of 12" or "No matches")
    var matchCountDisplay: String {
        if searchText.isEmpty {
            return ""
        } else if matches.isEmpty {
            return "No matches"
        } else {
            return "\(currentMatchIndex + 1) of \(totalMatches)"
        }
    }

    // MARK: - Dependencies

    private let service = FindReplaceService()
    private var searchDebounceTask: Task<Void, Never>?

    /// Reference to the document detail view model for content access
    weak var documentDetailViewModel: DocumentDetailViewModel?

    /// Reference to text view for scrolling
    #if os(macOS)
    weak var textViewRef: NSTextView?
    #else
    weak var textViewRef: UITextView?
    #endif

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Show the find bar
    func show(replaceMode: Bool = false) {
        isReplaceMode = replaceMode
        isVisible = true
    }

    /// Hide the find bar and clear highlights
    func hide() {
        isVisible = false
        searchText = ""
        replaceText = ""
        matches = []
        currentMatchIndex = 0
    }

    /// Navigate to the next match
    func navigateNext() {
        guard !matches.isEmpty else { return }

        currentMatchIndex = (currentMatchIndex + 1) % matches.count
        updateHighlightsAndScroll()
    }

    /// Navigate to the previous match
    func navigatePrevious() {
        guard !matches.isEmpty else { return }

        currentMatchIndex = (currentMatchIndex - 1 + matches.count) % matches.count
        updateHighlightsAndScroll()
    }

    /// Replace the current match with the replacement text
    func replaceCurrent() {
        guard !matches.isEmpty,
              currentMatchIndex < matches.count,
              let viewModel = documentDetailViewModel else { return }

        let currentRange = matches[currentMatchIndex]
        let attributedContent = viewModel.attributedContent

        let (newContent, newRanges, newIndex) = service.replace(
            in: attributedContent,
            at: currentRange,
            with: replaceText,
            allRanges: matches,
            currentIndex: currentMatchIndex
        )

        // Update state
        matches = newRanges
        currentMatchIndex = newRanges.isEmpty ? 0 : min(newIndex, newRanges.count - 1)

        // Apply highlights to new content
        let highlightedContent = service.applyHighlights(
            to: newContent,
            ranges: matches,
            currentIndex: currentMatchIndex
        )

        viewModel.attributedContent = highlightedContent

        // Scroll to new current match if there are still matches
        if !matches.isEmpty {
            scrollToCurrentMatch()
        }
    }

    /// Replace all matches with the replacement text
    func replaceAll() {
        guard !matches.isEmpty,
              let viewModel = documentDetailViewModel else { return }

        let replacedContent = service.replaceAll(
            in: viewModel.attributedContent,
            ranges: matches,
            with: replaceText
        )

        // Clear matches and update content
        matches = []
        currentMatchIndex = 0
        viewModel.attributedContent = replacedContent
    }

    /// Perform search with current parameters
    func performSearch() {
        guard let viewModel = documentDetailViewModel else { return }

        // Get the plain text content
        let plainText = viewModel.attributedContent.string

        // Find all matches
        matches = service.findRanges(
            searchText: searchText,
            in: plainText,
            caseSensitive: isCaseSensitive
        )

        // Reset to first match or adjust if current index is out of bounds
        if matches.isEmpty {
            currentMatchIndex = 0
        } else {
            currentMatchIndex = min(currentMatchIndex, matches.count - 1)
        }

        // Apply highlights
        updateHighlights()

        // Scroll to current match
        if !matches.isEmpty {
            scrollToCurrentMatch()
        }
    }

    // MARK: - Private Methods

    /// Debounce search to avoid excessive updates while typing
    private func debounceSearch() {
        searchDebounceTask?.cancel()

        searchDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

            if !Task.isCancelled {
                performSearch()
            }
        }
    }

    /// Update highlights in the attributed content
    private func updateHighlights() {
        guard let viewModel = documentDetailViewModel else { return }

        // Remove existing highlights first
        var content = service.removeHighlights(from: viewModel.attributedContent)

        // Apply new highlights if we have matches
        if !matches.isEmpty {
            content = service.applyHighlights(
                to: content,
                ranges: matches,
                currentIndex: currentMatchIndex
            )
        }

        viewModel.attributedContent = content
    }

    /// Update highlights and scroll to current match
    private func updateHighlightsAndScroll() {
        updateHighlights()
        scrollToCurrentMatch()
    }

    /// Clear all find highlights from the content
    private func clearHighlights() {
        guard let viewModel = documentDetailViewModel else { return }

        let cleanedContent = service.removeHighlights(from: viewModel.attributedContent)
        viewModel.attributedContent = cleanedContent
    }

    /// Scroll the text view to show the current match
    private func scrollToCurrentMatch() {
        guard !matches.isEmpty,
              currentMatchIndex < matches.count else { return }

        let range = matches[currentMatchIndex]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            #if os(macOS)
            if let textView = self?.textViewRef {
                textView.setSelectedRange(range)
                textView.scrollRangeToVisible(range)
            }
            #else
            if let textView = self?.textViewRef {
                textView.selectedRange = range
                textView.scrollRangeToVisible(range)
            }
            #endif
        }
    }
}
