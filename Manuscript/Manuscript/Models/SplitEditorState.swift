import Foundation
import SwiftUI

/// State for the split editor view, allowing two documents to be viewed side by side
struct SplitEditorState: Codable, Equatable {
    /// Whether split view is currently enabled
    var isEnabled: Bool = false

    /// Orientation of the split (horizontal = side by side, vertical = top/bottom)
    var orientation: SplitOrientation = .horizontal

    /// ID of the document shown in the secondary pane
    var secondaryDocumentId: UUID?

    /// Ratio of the split (0.0 to 1.0, representing the primary pane's portion)
    var splitRatio: CGFloat = 0.5

    /// Which pane currently has focus (for unified toolbar)
    var focusedPane: FocusedPane = .primary

    /// Identifies which split pane has focus
    enum FocusedPane: String, Codable {
        case primary
        case secondary
    }

    /// Orientation options for split view
    enum SplitOrientation: String, Codable, CaseIterable {
        case horizontal  // Side by side (macOS default)
        case vertical    // Top and bottom (iOS only option)

        var displayName: String {
            switch self {
            case .horizontal:
                return "Side by Side"
            case .vertical:
                return "Top and Bottom"
            }
        }

        var systemImage: String {
            switch self {
            case .horizontal:
                return "rectangle.split.2x1"
            case .vertical:
                return "rectangle.split.1x2"
            }
        }
    }

    /// Minimum ratio for either pane (prevents panes from becoming too small)
    static let minimumRatio: CGFloat = 0.2

    /// Clamps the split ratio to valid bounds
    mutating func clampRatio() {
        splitRatio = min(max(splitRatio, Self.minimumRatio), 1.0 - Self.minimumRatio)
    }
}
