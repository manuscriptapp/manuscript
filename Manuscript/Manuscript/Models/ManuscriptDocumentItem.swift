import Foundation

// MARK: - Trash Metadata

/// Metadata stored with trashed items to enable restoration
struct TrashedItemMetadata: Codable, Equatable, Hashable {
    /// The ID of the folder this item was in before being trashed
    let originalParentFolderId: UUID
    /// The order/position of the item in its original folder
    let originalOrder: Int
    /// When the item was moved to trash
    let trashedDate: Date

    init(originalParentFolderId: UUID, originalOrder: Int, trashedDate: Date = Date()) {
        self.originalParentFolderId = originalParentFolderId
        self.originalOrder = originalOrder
        self.trashedDate = trashedDate
    }
}

// MARK: - Document Item

extension ManuscriptDocument {
    struct Document: Identifiable, Codable, Equatable, Hashable {
        var id: UUID
        var title: String
        var synopsis: String
        var notes: String
        var content: String
        var creationDate: Date
        var order: Int
        var colorName: String
        var iconName: String
        var iconColor: String?  // Optional hex color for icon tint (e.g., "#FF0000")

        // Scrivener-compatible metadata
        var labelId: String?
        var statusId: String?
        var keywords: [String]
        var includeInCompile: Bool

        // Character/location references
        var characterIds: [UUID]
        var locationIds: [UUID]

        // Inline comments (Scrivener-compatible)
        var comments: [DocumentComment]

        // Trash metadata (nil if not in trash)
        var trashMetadata: TrashedItemMetadata?

        init(
            id: UUID = UUID(),
            title: String,
            synopsis: String = "",
            notes: String = "",
            content: String = "",
            creationDate: Date = Date(),
            order: Int = 0,
            colorName: String = "Brown",
            iconName: String = "doc.text",
            iconColor: String? = nil,
            labelId: String? = nil,
            statusId: String? = nil,
            keywords: [String] = [],
            includeInCompile: Bool = true,
            characterIds: [UUID] = [],
            locationIds: [UUID] = [],
            comments: [DocumentComment] = [],
            trashMetadata: TrashedItemMetadata? = nil
        ) {
            self.id = id
            self.title = title
            self.synopsis = synopsis
            self.notes = notes
            self.content = content
            self.creationDate = creationDate
            self.order = order
            self.colorName = colorName
            self.iconName = iconName
            self.iconColor = iconColor
            self.labelId = labelId
            self.statusId = statusId
            self.keywords = keywords
            self.includeInCompile = includeInCompile
            self.characterIds = characterIds
            self.locationIds = locationIds
            self.comments = comments
            self.trashMetadata = trashMetadata
        }

        /// Word count for this document's content
        var wordCount: Int {
            content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        }
    }

    /// Inline comment (Scrivener-compatible)
    struct DocumentComment: Identifiable, Codable, Equatable, Hashable {
        var id: UUID
        var text: String
        var color: String  // Hex color (e.g., "#FFFF00")
        var range: Range?  // Optional text range this comment refers to
        var creationDate: Date

        struct Range: Codable, Equatable, Hashable {
            var location: Int
            var length: Int
        }

        init(
            id: UUID = UUID(),
            text: String,
            color: String = "#FFFF00",
            range: Range? = nil,
            creationDate: Date = Date()
        ) {
            self.id = id
            self.text = text
            self.color = color
            self.range = range
            self.creationDate = creationDate
        }
    }
}
