import Foundation

// MARK: - Document Item

extension ManuscriptDocument {
    struct Document: Identifiable, Codable, Equatable {
        var id: UUID
        var title: String
        var outlinePrompt: String
        var outline: String  // synopsis
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

        init(
            id: UUID = UUID(),
            title: String,
            outlinePrompt: String = "",
            outline: String = "",
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
            locationIds: [UUID] = []
        ) {
            self.id = id
            self.title = title
            self.outlinePrompt = outlinePrompt
            self.outline = outline
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
        }
    }
}
