import SwiftUI
import UniformTypeIdentifiers
import Combine

// Define our custom document type
extension UTType {
    static var manuscriptDocument: UTType {
        UTType(exportedAs: "com.dahlsjoo.manuscript")
    }
}

// Character gender definition
enum ManuscriptCharacterGender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case notSpecified = "Not Specified"
}

// Core document structure that represents a Manuscript project
class ManuscriptDocument: FileDocument, Equatable, Codable {
    // Document properties
    var title: String
    var author: String
    var metaDescription: String
    var style: String
    var genre: String
    var synopsis: String
    var creationDate: Date

    // The root folder of the document
    var rootFolder: ManuscriptFolder

    // Collections for characters and locations
    var characters: [ManuscriptCharacter]
    var locations: [ManuscriptLocation]

    // Required for FileDocument
    static var readableContentTypes: [UTType] { [.manuscriptDocument] }

    // Equatable implementation
    static func == (lhs: ManuscriptDocument, rhs: ManuscriptDocument) -> Bool {
        return lhs.title == rhs.title &&
               lhs.author == rhs.author &&
               lhs.creationDate == rhs.creationDate &&
               lhs.rootFolder.id == rhs.rootFolder.id
    }

    // Initialize with default empty state
    init() {
        self.title = ""
        self.author = ""
        self.metaDescription = ""
        self.style = ""
        self.genre = ""
        self.synopsis = ""
        self.creationDate = Date()

        // Create an initial draft folder
        self.rootFolder = ManuscriptFolder(title: "Draft")
        self.characters = []
        self.locations = []
    }

    // Initialize from external file
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()

        // Decode the document data
        if let documentData = try? decoder.decode(ManuscriptDocumentData.self, from: data) {
            title = documentData.title
            author = documentData.author
            metaDescription = documentData.metaDescription
            style = documentData.style
            genre = documentData.genre
            synopsis = documentData.synopsis
            creationDate = documentData.creationDate
            rootFolder = documentData.rootFolder
            characters = documentData.characters
            locations = documentData.locations
        } else {
            // If we can't decode, start with an empty document
            title = ""
            author = ""
            metaDescription = ""
            style = ""
            genre = ""
            synopsis = ""
            creationDate = Date()
            rootFolder = ManuscriptFolder(title: "Draft")
            characters = []
            locations = []
        }
    }

    // Write to file
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Create the data to save
        let documentData = ManuscriptDocumentData(
            title: title,
            author: author,
            metaDescription: metaDescription,
            style: style,
            genre: genre,
            synopsis: synopsis,
            creationDate: creationDate,
            rootFolder: rootFolder,
            characters: characters,
            locations: locations
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(documentData)

        // Return a file wrapper
        return FileWrapper(regularFileWithContents: data)
    }

    // Helper struct for encoding/decoding
    private struct ManuscriptDocumentData: Codable {
        var title: String
        var author: String
        var metaDescription: String
        var style: String
        var genre: String
        var synopsis: String
        var creationDate: Date
        var rootFolder: ManuscriptFolder
        var characters: [ManuscriptCharacter]
        var locations: [ManuscriptLocation]
    }
}

// MARK: - Model types

// Document folder structure
struct ManuscriptFolder: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var creationDate: Date
    var order: Int

    var subfolders: [ManuscriptFolder]
    var documents: [ManuscriptDocument.Document]

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ManuscriptFolder, rhs: ManuscriptFolder) -> Bool {
        return lhs.id == rhs.id
    }

    init(
        id: UUID = UUID(),
        title: String,
        creationDate: Date = Date(),
        order: Int = 0,
        subfolders: [ManuscriptFolder] = [],
        documents: [ManuscriptDocument.Document] = []
    ) {
        self.id = id
        self.title = title
        self.creationDate = creationDate
        self.order = order
        self.subfolders = subfolders
        self.documents = documents
    }

    // Helper to calculate total document count recursively
    var totalDocumentCount: Int {
        let documentsInFolder = documents.count
        let documentsInSubfolders = subfolders.reduce(0) { count, subfolder in
            count + subfolder.totalDocumentCount
        }
        return documentsInFolder + documentsInSubfolders
    }
}

// Character
struct ManuscriptCharacter: Identifiable, Codable {
    var id: UUID
    var name: String
    var age: Int?
    var gender: ManuscriptCharacterGender

    // List of document IDs this character appears in
    var appearsInDocumentIds: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        age: Int? = nil,
        gender: ManuscriptCharacterGender = .notSpecified,
        appearsInDocumentIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.appearsInDocumentIds = appearsInDocumentIds
    }
}

// Location
struct ManuscriptLocation: Identifiable, Codable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double

    // List of document IDs this location appears in
    var appearsInDocumentIds: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        appearsInDocumentIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.appearsInDocumentIds = appearsInDocumentIds
    }
}

// Document within a folder
extension ManuscriptDocument {
    struct Document: Identifiable, Codable {
        var id: UUID
        var title: String
        var outlinePrompt: String  // Template's outline guidance/questions
        var outline: String        // User's actual outline/synopsis
        var notes: String          // Additional notes
        var content: String        // Main content
        var creationDate: Date
        var order: Int
        var colorName: String
        var iconName: String

        // IDs of characters and locations in this document
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
            self.characterIds = characterIds
            self.locationIds = locationIds
        }
    }
}

// MARK: - Type Aliases for backward compatibility during migration
// These can be removed once all references are updated
typealias LiteratiDocument = ManuscriptDocument
typealias LiteratiFolder = ManuscriptFolder
typealias LiteratiCharacter = ManuscriptCharacter
typealias LiteratiLocation = ManuscriptLocation
typealias LiteratiCharacterGender = ManuscriptCharacterGender
