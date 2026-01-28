import Foundation

// MARK: - Folder Type

enum ManuscriptFolderType: String, Codable {
    case draft
    case notes
    case research
    case trash
    case subfolder

    var directoryName: String {
        switch self {
        case .draft: return "draft"
        case .notes: return "notes"
        case .research: return "research"
        case .trash: return "trash"
        case .subfolder: return "subfolder"
        }
    }
}

// MARK: - Folder

struct ManuscriptFolder: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var folderType: ManuscriptFolderType
    var creationDate: Date
    var order: Int
    var expanded: Bool
    var iconName: String
    var iconColor: String?  // Optional hex color for icon tint (e.g., "#FF0000")

    // Trash metadata (nil if not in trash)
    var trashMetadata: TrashedItemMetadata?

    var subfolders: [ManuscriptFolder]
    var documents: [ManuscriptDocument.Document]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(folderType)
        hasher.combine(creationDate)
        hasher.combine(order)
        hasher.combine(expanded)
        hasher.combine(iconName)
        hasher.combine(iconColor)
        hasher.combine(trashMetadata)
        hasher.combine(subfolders)
        hasher.combine(documents)
    }

    static func == (lhs: ManuscriptFolder, rhs: ManuscriptFolder) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.folderType == rhs.folderType &&
        lhs.creationDate == rhs.creationDate &&
        lhs.order == rhs.order &&
        lhs.expanded == rhs.expanded &&
        lhs.iconName == rhs.iconName &&
        lhs.iconColor == rhs.iconColor &&
        lhs.trashMetadata == rhs.trashMetadata &&
        lhs.subfolders == rhs.subfolders &&
        lhs.documents == rhs.documents
    }

    /// Default blue color for folder icons (hex)
    static let defaultIconColor = "#007AFF"

    init(
        id: UUID = UUID(),
        title: String,
        folderType: ManuscriptFolderType = .subfolder,
        creationDate: Date = Date(),
        order: Int = 0,
        expanded: Bool = true,
        iconName: String = "folder",
        iconColor: String? = defaultIconColor,
        trashMetadata: TrashedItemMetadata? = nil,
        subfolders: [ManuscriptFolder] = [],
        documents: [ManuscriptDocument.Document] = []
    ) {
        self.id = id
        self.title = title
        self.folderType = folderType
        self.creationDate = creationDate
        self.order = order
        self.expanded = expanded
        self.iconName = iconName
        self.iconColor = iconColor
        self.trashMetadata = trashMetadata
        self.subfolders = subfolders
        self.documents = documents
    }

    var totalDocumentCount: Int {
        documents.count + subfolders.reduce(0) { $0 + $1.totalDocumentCount }
    }

    var isEmpty: Bool {
        documents.isEmpty && subfolders.isEmpty
    }

    /// Total word count across all documents in this folder and subfolders
    var totalWordCount: Int {
        let documentWords = documents.reduce(0) { $0 + $1.wordCount }
        let subfolderWords = subfolders.reduce(0) { $0 + $1.totalWordCount }
        return documentWords + subfolderWords
    }
}
