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

// MARK: - Main Document

struct ManuscriptDocument: FileDocument, Equatable, Codable {
    // Format version
    var formatVersion: ManuscriptFormatVersion

    // Document properties
    var title: String
    var author: String
    var metaDescription: String
    var style: String
    var genre: String
    var synopsis: String
    var creationDate: Date
    var modifiedDate: Date

    // The root folder of the document (contains draft, notes, research)
    var rootFolder: ManuscriptFolder

    // Additional folders
    var notesFolder: ManuscriptFolder?
    var researchFolder: ManuscriptFolder?
    var trashFolder: ManuscriptFolder?

    // Collections for characters and locations
    var characters: [ManuscriptCharacter]
    var locations: [ManuscriptLocation]

    // Labels and statuses (like Scrivener)
    var labels: [ManuscriptLabel]
    var statuses: [ManuscriptStatus]

    // Project settings
    var targets: ManuscriptTargets
    var settings: ManuscriptSettings
    var compileSettings: ManuscriptCompileSettings

    // Writing history (imported from Scrivener or tracked in-app)
    var writingHistory: WritingHistory

    // Required for FileDocument
    // Include .package and .folder as fallbacks for when custom UTType isn't registered (e.g., running from Xcode)
    // .folder is needed because macOS may identify .manuscript directories as folders rather than packages
    static var readableContentTypes: [UTType] { [.manuscriptDocument, .package, .folder] }

    // MARK: - Initialization

    init() {
        self.formatVersion = .current
        self.title = ""
        self.author = ""
        self.metaDescription = ""
        self.style = ""
        self.genre = ""
        self.synopsis = ""
        self.creationDate = Date()
        self.modifiedDate = Date()
        self.rootFolder = ManuscriptFolder(title: "Draft", folderType: .draft)
        self.notesFolder = ManuscriptFolder(title: "Notes", folderType: .notes)
        self.researchFolder = ManuscriptFolder(title: "Research", folderType: .research)
        self.trashFolder = ManuscriptFolder(title: "Trash", folderType: .trash)
        self.characters = []
        self.locations = []
        self.labels = ManuscriptLabel.defaults
        self.statuses = ManuscriptStatus.defaults
        self.targets = ManuscriptTargets()
        self.settings = ManuscriptSettings()
        self.compileSettings = ManuscriptCompileSettings()
        self.writingHistory = WritingHistory()
    }

    // MARK: - FileDocument Implementation

    init(configuration: ReadConfiguration) throws {
        // Only support package (directory) format
        guard configuration.file.isDirectory else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        try self.init(fromPackage: configuration.file)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Always write in the new package format
        return try createPackageFileWrapper()
    }

    // MARK: - Package Format (New)

    private init(fromPackage fileWrapper: FileWrapper) throws {
        guard let children = fileWrapper.fileWrappers else {
            throw CocoaError(.fileReadCorruptFile)
        }

        // Read project.json
        guard let projectJsonWrapper = children["project.json"],
              let projectJsonData = projectJsonWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let projectData = try decoder.decode(ProjectJSON.self, from: projectJsonData)

        self.formatVersion = ManuscriptFormatVersion(rawValue: projectData.version) ?? .current
        self.title = projectData.title
        self.author = projectData.author
        self.metaDescription = projectData.metaDescription ?? ""
        self.style = projectData.style ?? ""
        self.genre = projectData.genre ?? ""
        self.synopsis = projectData.synopsis ?? ""
        self.creationDate = projectData.created
        self.modifiedDate = projectData.modified
        self.settings = projectData.settings ?? ManuscriptSettings()
        self.compileSettings = projectData.compile ?? ManuscriptCompileSettings()
        self.targets = projectData.targets ?? ManuscriptTargets()
        self.labels = projectData.labels ?? ManuscriptLabel.defaults
        self.statuses = projectData.statuses ?? ManuscriptStatus.defaults
        self.characters = projectData.characters ?? []
        self.locations = projectData.locations ?? []
        self.writingHistory = projectData.writingHistory ?? WritingHistory()

        // Read contents folder
        if let contentsWrapper = children["contents"], contentsWrapper.isDirectory {
            // Read draft folder
            if let draftWrapper = contentsWrapper.fileWrappers?["draft"] {
                self.rootFolder = try Self.readFolder(from: draftWrapper, type: .draft)
            } else {
                self.rootFolder = ManuscriptFolder(title: "Draft", folderType: .draft)
            }

            // Read notes folder
            if let notesWrapper = contentsWrapper.fileWrappers?["notes"] {
                self.notesFolder = try Self.readFolder(from: notesWrapper, type: .notes)
            }

            // Read research folder
            if let researchWrapper = contentsWrapper.fileWrappers?["research"] {
                self.researchFolder = try Self.readFolder(from: researchWrapper, type: .research)
            }
        } else {
            self.rootFolder = ManuscriptFolder(title: "Draft", folderType: .draft)
        }

        // Read trash folder
        if let trashWrapper = children["trash"] {
            self.trashFolder = try Self.readFolder(from: trashWrapper, type: .trash)
        }
    }

    private static func readFolder(from fileWrapper: FileWrapper, type: ManuscriptFolderType) throws -> ManuscriptFolder {
        guard fileWrapper.isDirectory, let children = fileWrapper.fileWrappers else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Read folder.json
        var folderMetadata: FolderJSON?
        if let folderJsonWrapper = children["folder.json"],
           let folderJsonData = folderJsonWrapper.regularFileContents {
            folderMetadata = try? decoder.decode(FolderJSON.self, from: folderJsonData)
        }

        var folder = ManuscriptFolder(
            id: UUID(uuidString: folderMetadata?.id ?? "") ?? UUID(),
            title: folderMetadata?.title ?? fileWrapper.filename ?? "Untitled",
            folderType: type,
            creationDate: folderMetadata?.created ?? Date()
        )

        // Read items from folder.json to maintain order
        if let items = folderMetadata?.items {
            for item in items {
                if item.type == "document" {
                    // Read the markdown file
                    if let mdWrapper = children[item.file],
                       let mdData = mdWrapper.regularFileContents,
                       let content = String(data: mdData, encoding: .utf8) {
                        let document = ManuscriptDocument.Document(
                            id: UUID(uuidString: item.id) ?? UUID(),
                            title: item.title,
                            outline: item.synopsis ?? "",
                            notes: "",
                            content: extractContentFromMarkdown(content),
                            creationDate: item.created ?? Date(),
                            order: folder.documents.count,
                            iconName: item.iconName ?? "doc.text",
                            iconColor: item.iconColor,
                            labelId: item.label,
                            statusId: item.status,
                            keywords: item.keywords ?? [],
                            includeInCompile: item.includeInCompile ?? true
                        )
                        folder.documents.append(document)
                    }
                } else if item.type == "folder" {
                    // Recursively read subfolder
                    if let subfolderWrapper = children[item.file] {
                        let subfolder = try readFolder(from: subfolderWrapper, type: .subfolder)
                        folder.subfolders.append(subfolder)
                    }
                }
            }
        } else {
            // No folder.json - read all markdown files
            for (filename, wrapper) in children where filename.hasSuffix(".md") {
                if let data = wrapper.regularFileContents,
                   let content = String(data: data, encoding: .utf8) {
                    let title = filename.replacingOccurrences(of: ".md", with: "")
                        .replacingOccurrences(of: "-", with: " ")
                        .trimmingCharacters(in: .decimalDigits)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                        .trimmingCharacters(in: .whitespaces)
                    let document = ManuscriptDocument.Document(
                        title: title.isEmpty ? "Untitled" : title.capitalized,
                        content: extractContentFromMarkdown(content)
                    )
                    folder.documents.append(document)
                }
            }
        }

        return folder
    }

    private static func extractContentFromMarkdown(_ markdown: String) -> String {
        // Remove YAML frontmatter if present
        if markdown.hasPrefix("---") {
            let parts = markdown.components(separatedBy: "---")
            if parts.count >= 3 {
                return parts.dropFirst(2).joined(separator: "---").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return markdown
    }

    func createPackageFileWrapper() throws -> FileWrapper {
        let rootWrapper = FileWrapper(directoryWithFileWrappers: [:])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        // Create project.json
        let projectData = ProjectJSON(
            version: formatVersion.rawValue,
            title: title,
            author: author,
            metaDescription: metaDescription.isEmpty ? nil : metaDescription,
            style: style.isEmpty ? nil : style,
            genre: genre.isEmpty ? nil : genre,
            synopsis: synopsis.isEmpty ? nil : synopsis,
            created: creationDate,
            modified: Date(),
            settings: settings,
            compile: compileSettings,
            targets: targets,
            labels: labels,
            statuses: statuses,
            characters: characters.isEmpty ? nil : characters,
            locations: locations.isEmpty ? nil : locations,
            writingHistory: writingHistory.isEmpty ? nil : writingHistory
        )
        let projectJsonData = try encoder.encode(projectData)
        rootWrapper.addRegularFile(withContents: projectJsonData, preferredFilename: "project.json")

        // Create contents directory
        let contentsWrapper = FileWrapper(directoryWithFileWrappers: [:])

        // Add draft folder
        let draftWrapper = try createFolderWrapper(for: rootFolder)
        contentsWrapper.addFileWrapper(draftWrapper)

        // Add notes folder
        if let notesFolder = notesFolder, !notesFolder.isEmpty {
            let notesWrapper = try createFolderWrapper(for: notesFolder)
            contentsWrapper.addFileWrapper(notesWrapper)
        }

        // Add research folder
        if let researchFolder = researchFolder, !researchFolder.isEmpty {
            let researchWrapper = try createFolderWrapper(for: researchFolder)
            contentsWrapper.addFileWrapper(researchWrapper)
        }

        contentsWrapper.preferredFilename = "contents"
        rootWrapper.addFileWrapper(contentsWrapper)

        // Add trash folder
        if let trashFolder = trashFolder, !trashFolder.isEmpty {
            let trashWrapper = try createFolderWrapper(for: trashFolder)
            trashWrapper.preferredFilename = "trash"
            rootWrapper.addFileWrapper(trashWrapper)
        }

        // Create empty directories for assets and snapshots
        let assetsWrapper = FileWrapper(directoryWithFileWrappers: [:])
        assetsWrapper.preferredFilename = "assets"
        rootWrapper.addFileWrapper(assetsWrapper)

        let snapshotsWrapper = FileWrapper(directoryWithFileWrappers: [:])
        snapshotsWrapper.preferredFilename = "snapshots"
        rootWrapper.addFileWrapper(snapshotsWrapper)

        return rootWrapper
    }

    private func createFolderWrapper(for folder: ManuscriptFolder) throws -> FileWrapper {
        let folderWrapper = FileWrapper(directoryWithFileWrappers: [:])
        folderWrapper.preferredFilename = folder.folderType.directoryName

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        // Build items array for folder.json
        var items: [FolderItem] = []

        // Add documents
        for (index, document) in folder.documents.enumerated() {
            let filename = String(format: "%02d-%@.md", index + 1, document.title.slugified)

            let item = FolderItem(
                id: document.id.uuidString,
                file: filename,
                title: document.title,
                type: "document",
                label: document.labelId,
                status: document.statusId,
                keywords: document.keywords.isEmpty ? nil : document.keywords,
                synopsis: document.outline.isEmpty ? nil : document.outline,
                includeInCompile: document.includeInCompile,
                created: document.creationDate,
                modified: Date(),
                iconName: document.iconName == "doc.text" ? nil : document.iconName,
                iconColor: document.iconColor
            )
            items.append(item)

            // Create markdown file with optional frontmatter
            let mdContent = createMarkdownContent(for: document)
            if let mdData = mdContent.data(using: .utf8) {
                folderWrapper.addRegularFile(withContents: mdData, preferredFilename: filename)
            }
        }

        // Add subfolders
        for (index, subfolder) in folder.subfolders.enumerated() {
            let folderName = String(format: "%02d-%@", index + folder.documents.count + 1, subfolder.title.slugified)

            let item = FolderItem(
                id: subfolder.id.uuidString,
                file: folderName,
                title: subfolder.title,
                type: "folder",
                label: nil,
                status: nil,
                keywords: nil,
                synopsis: nil,
                includeInCompile: true,
                created: subfolder.creationDate,
                modified: Date()
            )
            items.append(item)

            // Create subfolder
            var subfolderCopy = subfolder
            subfolderCopy.folderType = .subfolder
            let subfolderWrapper = try createFolderWrapper(for: subfolderCopy)
            subfolderWrapper.preferredFilename = folderName
            folderWrapper.addFileWrapper(subfolderWrapper)
        }

        // Create folder.json
        let folderJson = FolderJSON(
            id: folder.id.uuidString,
            title: folder.title,
            type: folder.folderType.rawValue,
            created: folder.creationDate,
            modified: Date(),
            expanded: true,
            items: items
        )
        let folderJsonData = try encoder.encode(folderJson)
        folderWrapper.addRegularFile(withContents: folderJsonData, preferredFilename: "folder.json")

        return folderWrapper
    }

    private func createMarkdownContent(for document: ManuscriptDocument.Document) -> String {
        var content = ""

        // Add YAML frontmatter if there's metadata
        if !document.outline.isEmpty || !document.notes.isEmpty {
            content += "---\n"
            content += "title: \(document.title)\n"
            if !document.outline.isEmpty {
                content += "synopsis: \(document.outline.replacingOccurrences(of: "\n", with: " "))\n"
            }
            content += "---\n\n"
        }

        content += document.content

        // Add notes as HTML comment at the end if present
        if !document.notes.isEmpty {
            content += "\n\n<!-- NOTES:\n\(document.notes)\n-->\n"
        }

        return content
    }

}

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

    var subfolders: [ManuscriptFolder]
    var documents: [ManuscriptDocument.Document]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ManuscriptFolder, rhs: ManuscriptFolder) -> Bool {
        lhs.id == rhs.id
    }

    init(
        id: UUID = UUID(),
        title: String,
        folderType: ManuscriptFolderType = .subfolder,
        creationDate: Date = Date(),
        order: Int = 0,
        expanded: Bool = true,
        subfolders: [ManuscriptFolder] = [],
        documents: [ManuscriptDocument.Document] = []
    ) {
        self.id = id
        self.title = title
        self.folderType = folderType
        self.creationDate = creationDate
        self.order = order
        self.expanded = expanded
        self.subfolders = subfolders
        self.documents = documents
    }

    var totalDocumentCount: Int {
        documents.count + subfolders.reduce(0) { $0 + $1.totalDocumentCount }
    }

    var isEmpty: Bool {
        documents.isEmpty && subfolders.isEmpty
    }
}

// MARK: - Character

struct ManuscriptCharacter: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var age: Int?
    var gender: ManuscriptCharacterGender
    var description: String
    var notes: String
    var appearsInDocumentIds: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        age: Int? = nil,
        gender: ManuscriptCharacterGender = .notSpecified,
        description: String = "",
        notes: String = "",
        appearsInDocumentIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.description = description
        self.notes = notes
        self.appearsInDocumentIds = appearsInDocumentIds
    }
}

// MARK: - Location

struct ManuscriptLocation: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var description: String
    var latitude: Double
    var longitude: Double
    var appearsInDocumentIds: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        appearsInDocumentIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        self.appearsInDocumentIds = appearsInDocumentIds
    }
}

// MARK: - Document

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

// MARK: - JSON Schemas

/// Schema for project.json
private struct ProjectJSON: Codable {
    let version: String
    var title: String
    var author: String
    var metaDescription: String?
    var style: String?
    var genre: String?
    var synopsis: String?
    var created: Date
    var modified: Date
    var settings: ManuscriptSettings?
    var compile: ManuscriptCompileSettings?
    var targets: ManuscriptTargets?
    var labels: [ManuscriptLabel]?
    var statuses: [ManuscriptStatus]?
    var characters: [ManuscriptCharacter]?
    var locations: [ManuscriptLocation]?
    var writingHistory: WritingHistory?
}

/// Schema for folder.json
private struct FolderJSON: Codable {
    var id: String
    var title: String
    var type: String
    var created: Date
    var modified: Date
    var expanded: Bool
    var items: [FolderItem]
}

/// Item in folder.json
private struct FolderItem: Codable {
    var id: String
    var file: String
    var title: String
    var type: String  // "document" or "folder"
    var label: String?
    var status: String?
    var keywords: [String]?
    var synopsis: String?
    var includeInCompile: Bool?
    var created: Date?
    var modified: Date?
    var iconName: String?
    var iconColor: String?  // Hex color for icon tint (e.g., "#FF0000")
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

// MARK: - Preview Support

#if DEBUG
extension ManuscriptDocument {
    static func preview(title: String, author: String) -> ManuscriptDocument {
        var doc = ManuscriptDocument()
        doc.title = title
        doc.author = author
        return doc
    }
}
#endif
