import SwiftUI
import UniformTypeIdentifiers

// MARK: - UTType Extension

extension UTType {
    static var manuscriptDocument: UTType {
        UTType(exportedAs: "com.dahlsjoo.manuscript")
    }

    static var scrivenerProject: UTType {
        UTType(filenameExtension: "scriv") ?? .folder
    }
}

// MARK: - Format Version

enum ManuscriptFormatVersion: String, Codable {
    case v1_0 = "1.0"

    static var current: ManuscriptFormatVersion { .v1_0 }
}

// MARK: - Character Gender

enum ManuscriptCharacterGender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case notSpecified = "Not Specified"
}

// MARK: - Label

struct ManuscriptLabel: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var color: String  // Hex color string e.g., "#4A90D9"

    init(id: String = UUID().uuidString, name: String, color: String = "#808080") {
        self.id = id
        self.name = name
        self.color = color
    }

    static let defaults: [ManuscriptLabel] = [
        ManuscriptLabel(id: "label-chapter", name: "Chapter", color: "#4A90D9"),
        ManuscriptLabel(id: "label-scene", name: "Scene", color: "#7ED321"),
        ManuscriptLabel(id: "label-idea", name: "Idea", color: "#F5A623"),
        ManuscriptLabel(id: "label-revision", name: "Needs Revision", color: "#D0021B")
    ]
}

// MARK: - Status

struct ManuscriptStatus: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String

    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }

    static let defaults: [ManuscriptStatus] = [
        ManuscriptStatus(id: "status-todo", name: "To Do"),
        ManuscriptStatus(id: "status-progress", name: "In Progress"),
        ManuscriptStatus(id: "status-draft", name: "First Draft"),
        ManuscriptStatus(id: "status-revised", name: "Revised"),
        ManuscriptStatus(id: "status-done", name: "Done")
    ]
}

// MARK: - Project Targets

struct ManuscriptTargets: Codable, Equatable {
    var draftWordCount: Int?
    var draftDeadline: Date?
    var sessionWordCount: Int?

    init(draftWordCount: Int? = nil, draftDeadline: Date? = nil, sessionWordCount: Int? = nil) {
        self.draftWordCount = draftWordCount
        self.draftDeadline = draftDeadline
        self.sessionWordCount = sessionWordCount
    }
}

// MARK: - Project Settings

struct ManuscriptSettings: Codable, Equatable {
    var defaultFont: String
    var defaultFontSize: Int
    var editorTheme: String
    var spellCheck: Bool
    var autoSave: Bool
    var snapshotInterval: Int  // seconds

    init(
        defaultFont: String = "Georgia",
        defaultFontSize: Int = 14,
        editorTheme: String = "light",
        spellCheck: Bool = true,
        autoSave: Bool = true,
        snapshotInterval: Int = 300
    ) {
        self.defaultFont = defaultFont
        self.defaultFontSize = defaultFontSize
        self.editorTheme = editorTheme
        self.spellCheck = spellCheck
        self.autoSave = autoSave
        self.snapshotInterval = snapshotInterval
    }
}

// MARK: - Compile Settings

struct ManuscriptCompileSettings: Codable, Equatable {
    var title: String
    var author: String
    var format: String
    var template: String

    init(title: String = "", author: String = "", format: String = "pdf", template: String = "novel") {
        self.title = title
        self.author = author
        self.format = format
        self.template = template
    }
}

// MARK: - String Extension

extension String {
    var slugified: String {
        let allowed = CharacterSet.alphanumerics
        return self
            .lowercased()
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
