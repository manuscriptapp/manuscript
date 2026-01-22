//
//  FindReplaceService.swift
//  Manuscript
//
//  Created for find & replace functionality
//

import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Custom attribute key for tracking find highlights (so we can remove them later)
extension NSAttributedString.Key {
    static let findHighlight = NSAttributedString.Key("manuscriptFindHighlight")
}

/// Service providing core find and replace functionality for text
@MainActor
final class FindReplaceService {

    // MARK: - Highlight Colors

    #if os(iOS)
    /// Background color for all matches
    static let matchHighlightColor = UIColor.systemYellow.withAlphaComponent(0.5)
    /// Background color for the current (active) match
    static let currentMatchHighlightColor = UIColor.systemOrange.withAlphaComponent(0.7)
    #else
    /// Background color for all matches
    static let matchHighlightColor = NSColor.systemYellow.withAlphaComponent(0.5)
    /// Background color for the current (active) match
    static let currentMatchHighlightColor = NSColor.systemOrange.withAlphaComponent(0.7)
    #endif

    // MARK: - Find Operations

    /// Find all ranges of search text within the given string
    /// - Parameters:
    ///   - searchText: The text to search for
    ///   - text: The string to search within
    ///   - caseSensitive: Whether the search should be case-sensitive
    /// - Returns: Array of NSRange representing all match locations
    func findRanges(searchText: String, in text: String, caseSensitive: Bool) -> [NSRange] {
        guard !searchText.isEmpty else { return [] }

        var ranges: [NSRange] = []
        let nsString = text as NSString
        var searchRange = NSRange(location: 0, length: nsString.length)

        let options: NSString.CompareOptions = caseSensitive ? [] : [.caseInsensitive]

        while searchRange.location < nsString.length {
            let foundRange = nsString.range(of: searchText, options: options, range: searchRange)

            if foundRange.location != NSNotFound {
                ranges.append(foundRange)
                // Move search range past the found match
                searchRange.location = foundRange.location + foundRange.length
                searchRange.length = nsString.length - searchRange.location
            } else {
                break
            }
        }

        return ranges
    }

    // MARK: - Highlight Operations

    /// Apply find highlights to an attributed string
    /// - Parameters:
    ///   - attributedString: The attributed string to modify
    ///   - ranges: The ranges to highlight
    ///   - currentIndex: The index of the current match (highlighted differently)
    /// - Returns: A new attributed string with highlights applied
    func applyHighlights(
        to attributedString: NSAttributedString,
        ranges: [NSRange],
        currentIndex: Int
    ) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributedString)

        // First, remove any existing find highlights
        removeHighlightsFromMutable(mutable)

        // Apply highlights to all matches
        for (index, range) in ranges.enumerated() {
            guard range.location + range.length <= mutable.length else { continue }

            let isCurrentMatch = index == currentIndex
            let highlightColor = isCurrentMatch ? Self.currentMatchHighlightColor : Self.matchHighlightColor

            mutable.addAttribute(.backgroundColor, value: highlightColor, range: range)
            mutable.addAttribute(.findHighlight, value: true, range: range)
        }

        return mutable
    }

    /// Remove all find highlights from an attributed string
    /// - Parameter attributedString: The attributed string to clean
    /// - Returns: A new attributed string with find highlights removed
    func removeHighlights(from attributedString: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        removeHighlightsFromMutable(mutable)
        return mutable
    }

    /// Internal helper to remove highlights from a mutable attributed string
    private func removeHighlightsFromMutable(_ mutable: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: mutable.length)

        // Find all ranges with our custom findHighlight attribute and remove the background color
        mutable.enumerateAttribute(.findHighlight, in: fullRange, options: []) { value, range, _ in
            if value != nil {
                mutable.removeAttribute(.backgroundColor, range: range)
                mutable.removeAttribute(.findHighlight, range: range)
            }
        }
    }

    // MARK: - Replace Operations

    /// Replace text at a specific range
    /// - Parameters:
    ///   - attributedString: The attributed string to modify
    ///   - range: The range to replace
    ///   - replacement: The replacement text
    /// - Returns: A tuple of (new attributed string, new ranges after replacement)
    func replace(
        in attributedString: NSAttributedString,
        at range: NSRange,
        with replacement: String,
        allRanges: [NSRange],
        currentIndex: Int
    ) -> (attributedString: NSAttributedString, newRanges: [NSRange], newIndex: Int) {
        guard range.location + range.length <= attributedString.length else {
            return (attributedString, allRanges, currentIndex)
        }

        let mutable = NSMutableAttributedString(attributedString: attributedString)

        // Get the attributes at the replacement location to preserve formatting
        var attributes: [NSAttributedString.Key: Any] = [:]
        if range.location < mutable.length {
            attributes = mutable.attributes(at: range.location, effectiveRange: nil)
            // Remove find highlight attributes
            attributes.removeValue(forKey: .findHighlight)
            attributes.removeValue(forKey: .backgroundColor)
        }

        // Create the replacement attributed string with preserved attributes
        let replacementAttrString = NSAttributedString(string: replacement, attributes: attributes)

        // Perform the replacement
        mutable.replaceCharacters(in: range, with: replacementAttrString)

        // Recalculate ranges after replacement
        let lengthDifference = replacement.count - range.length
        var newRanges: [NSRange] = []

        for (index, existingRange) in allRanges.enumerated() {
            if index == currentIndex {
                // Skip the replaced range
                continue
            } else if existingRange.location > range.location {
                // Adjust ranges after the replacement
                let adjustedRange = NSRange(
                    location: existingRange.location + lengthDifference,
                    length: existingRange.length
                )
                newRanges.append(adjustedRange)
            } else {
                // Keep ranges before the replacement unchanged
                newRanges.append(existingRange)
            }
        }

        // Calculate new index (stay at same position, but might be at end)
        let newIndex = min(currentIndex, max(0, newRanges.count - 1))

        return (mutable, newRanges, newIndex)
    }

    /// Replace all occurrences in the attributed string
    /// - Parameters:
    ///   - attributedString: The attributed string to modify
    ///   - ranges: All ranges to replace (must be sorted by location)
    ///   - replacement: The replacement text
    /// - Returns: New attributed string with all replacements made
    func replaceAll(
        in attributedString: NSAttributedString,
        ranges: [NSRange],
        with replacement: String
    ) -> NSAttributedString {
        guard !ranges.isEmpty else { return attributedString }

        let mutable = NSMutableAttributedString(attributedString: attributedString)

        // Process ranges in reverse order to maintain correct positions
        let sortedRanges = ranges.sorted { $0.location > $1.location }

        for range in sortedRanges {
            guard range.location + range.length <= mutable.length else { continue }

            // Get attributes at replacement location
            var attributes: [NSAttributedString.Key: Any] = [:]
            if range.location < mutable.length {
                attributes = mutable.attributes(at: range.location, effectiveRange: nil)
                attributes.removeValue(forKey: .findHighlight)
                attributes.removeValue(forKey: .backgroundColor)
            }

            let replacementAttrString = NSAttributedString(string: replacement, attributes: attributes)
            mutable.replaceCharacters(in: range, with: replacementAttrString)
        }

        return mutable
    }
}
