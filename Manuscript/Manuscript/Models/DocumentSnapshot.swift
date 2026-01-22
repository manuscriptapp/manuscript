import Foundation

/// A point-in-time snapshot of a document's content
struct DocumentSnapshot: Identifiable, Codable, Equatable {
    var id: UUID
    var documentId: UUID           // Links to ManuscriptDocument.Document
    var timestamp: Date
    var title: String?             // Optional user-provided title
    var snapshotType: SnapshotType

    // Captured content
    var content: String
    var notes: String
    var outline: String

    // Stats for display
    var wordCount: Int
    var characterCount: Int

    enum SnapshotType: String, Codable {
        case manual
        case auto
        case milestone
    }

    init(
        id: UUID = UUID(),
        documentId: UUID,
        timestamp: Date = Date(),
        title: String? = nil,
        snapshotType: SnapshotType = .manual,
        content: String,
        notes: String,
        outline: String
    ) {
        self.id = id
        self.documentId = documentId
        self.timestamp = timestamp
        self.title = title
        self.snapshotType = snapshotType
        self.content = content
        self.notes = notes
        self.outline = outline

        // Calculate stats
        self.wordCount = content.split { $0.isWhitespace || $0.isNewline }.count
        self.characterCount = content.count
    }

    /// Display title - returns user title or formatted date
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// Icon name based on snapshot type
    var iconName: String {
        switch snapshotType {
        case .manual:
            return "camera.circle"
        case .auto:
            return "clock.circle"
        case .milestone:
            return "flag.circle"
        }
    }

    /// Relative date string for display
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
