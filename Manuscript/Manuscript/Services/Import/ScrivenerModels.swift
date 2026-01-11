import Foundation
import SwiftUI

// MARK: - Scrivener Version

/// Represents the version of a Scrivener project format
enum ScrivenerVersion {
    case v2  // Scrivener 2.x format (Files/Docs/)
    case v3  // Scrivener 3.x format (Files/Data/)
}

// MARK: - Scrivener Project

/// Represents a parsed Scrivener project
struct ScrivenerProject {
    let title: String
    let version: ScrivenerVersion
    let binderItems: [ScrivenerBinderItem]
    let labels: [ScrivenerLabel]
    let statuses: [ScrivenerStatus]
    let targets: ScrivenerTargets?
    let customMetadata: [ScrivenerCustomField]
}

// MARK: - Binder Item

/// Represents a binder item (folder or document) in the Scrivener project
struct ScrivenerBinderItem {
    let id: String
    let uuid: String?                   // Scrivener 3 UUID
    let type: ScrivenerItemType
    let title: String
    let created: Date?
    let modified: Date?
    let synopsis: String?
    let labelID: Int?
    let statusID: Int?
    let includeInCompile: Bool
    let children: [ScrivenerBinderItem]
    let targetWordCount: Int?

    init(
        id: String,
        uuid: String? = nil,
        type: ScrivenerItemType,
        title: String,
        created: Date? = nil,
        modified: Date? = nil,
        synopsis: String? = nil,
        labelID: Int? = nil,
        statusID: Int? = nil,
        includeInCompile: Bool = true,
        children: [ScrivenerBinderItem] = [],
        targetWordCount: Int? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.type = type
        self.title = title
        self.created = created
        self.modified = modified
        self.synopsis = synopsis
        self.labelID = labelID
        self.statusID = statusID
        self.includeInCompile = includeInCompile
        self.children = children
        self.targetWordCount = targetWordCount
    }
}

// MARK: - Item Type

/// Types of items in the Scrivener binder
enum ScrivenerItemType: String {
    case draftFolder = "DraftFolder"
    case researchFolder = "ResearchFolder"
    case trashFolder = "TrashFolder"
    case folder = "Folder"
    case text = "Text"
    case pdf = "PDF"
    case image = "Image"
    case webPage = "WebPage"
    case root = "Root"
    case other = "Other"

    init(rawValue: String) {
        switch rawValue {
        case "DraftFolder":
            self = .draftFolder
        case "ResearchFolder":
            self = .researchFolder
        case "TrashFolder":
            self = .trashFolder
        case "Folder":
            self = .folder
        case "Text":
            self = .text
        case "PDF":
            self = .pdf
        case "Image":
            self = .image
        case "WebPage":
            self = .webPage
        case "Root":
            self = .root
        default:
            self = .other
        }
    }
}

// MARK: - Label

/// A label definition from Scrivener
struct ScrivenerLabel {
    let id: Int
    let name: String
    let color: Color

    init(id: Int, name: String, color: Color = .gray) {
        self.id = id
        self.name = name
        self.color = color
    }
}

// MARK: - Status

/// A status definition from Scrivener
struct ScrivenerStatus {
    let id: Int
    let name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Targets

/// Project targets from Scrivener
struct ScrivenerTargets {
    let draftWordCount: Int?
    let sessionWordCount: Int?
    let deadline: Date?

    init(draftWordCount: Int? = nil, sessionWordCount: Int? = nil, deadline: Date? = nil) {
        self.draftWordCount = draftWordCount
        self.sessionWordCount = sessionWordCount
        self.deadline = deadline
    }
}

// MARK: - Custom Field

/// Custom metadata field definition
struct ScrivenerCustomField {
    let id: Int
    let title: String
    let type: String  // "Text", "Checkbox", "Date", etc.
}

// MARK: - Import Options

/// Configuration options for the import process
struct ScrivenerImportOptions {
    var importSnapshots: Bool
    var importTrash: Bool
    var importResearch: Bool
    var preserveScrivenerIDs: Bool  // Store original IDs in metadata

    init(
        importSnapshots: Bool = true,
        importTrash: Bool = false,
        importResearch: Bool = true,
        preserveScrivenerIDs: Bool = false
    ) {
        self.importSnapshots = importSnapshots
        self.importTrash = importTrash
        self.importResearch = importResearch
        self.preserveScrivenerIDs = preserveScrivenerIDs
    }

    static let `default` = ScrivenerImportOptions()
}

// MARK: - Validation Result

/// Result of validating a Scrivener project before import
struct ScrivenerValidationResult {
    let isValid: Bool
    let projectTitle: String
    let itemCount: Int
    let version: ScrivenerVersion
    let warnings: [String]
    let errors: [String]

    init(
        isValid: Bool,
        projectTitle: String = "",
        itemCount: Int = 0,
        version: ScrivenerVersion = .v3,
        warnings: [String] = [],
        errors: [String] = []
    ) {
        self.isValid = isValid
        self.projectTitle = projectTitle
        self.itemCount = itemCount
        self.version = version
        self.warnings = warnings
        self.errors = errors
    }
}
