import SwiftData
import Foundation

enum CharacterGender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case notSpecified = "Not Specified"
}

@Model
final class Book {
    var id: UUID = UUID()
    var title: String = ""
    var author: String = ""
    var metaDescription: String = ""
    var style: String = ""
    var genre: String = ""
    var synopsis: String = ""
    var creationDate: Date = Date()
    var templateId: UUID? = nil
    
    // Root folder for the book's content
    @Relationship(deleteRule: .cascade)
    var rootFolder: Folder?
    
    // World-building elements
    @Relationship(deleteRule: .cascade)
    var characters: [Character]? = []
    
    @Relationship(deleteRule: .cascade)
    var locations: [Location]? = []
    
    init(
        title: String = "",
        author: String = "",
        metaDescription: String = "",
        style: String = "",
        genre: String = "",
        synopsis: String = "",
        templateId: UUID? = nil,
        creationDate: Date = Date(),
        rootFolder: Folder? = nil,
        characters: [Character]? = [],
        locations: [Location]? = nil
    ) {
        self.title = title
        self.author = author
        self.metaDescription = metaDescription
        self.style = style
        self.genre = genre
        self.synopsis = synopsis
        self.templateId = templateId
        self.creationDate = creationDate
        self.rootFolder = rootFolder
        self.characters = characters
        self.locations = locations
    }
}

@Model
final class Character {
    var id: UUID = UUID()
    var name: String = ""
    var age: Int?
    var gender: CharacterGender = CharacterGender.notSpecified
    
    @Relationship(inverse: \Book.characters)
    var book: Book?
    
    @Relationship(inverse: \Document.characters)
    var appearsIn: [Document]? = []
    
    init(name: String = "", age: Int? = nil, gender: CharacterGender = CharacterGender.notSpecified) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.gender = gender
    }
}

@Model
final class Folder {
    var id: UUID = UUID()
    var title: String = ""
    var creationDate: Date = Date()
    var order: Int = 0
    
    @Relationship(deleteRule: .cascade)
    var subfolders: [Folder]? = []
    
    @Relationship(inverse: \Folder.subfolders)
    var parentFolder: Folder?
    
    @Relationship(deleteRule: .cascade)
    var documents: [Document]? = []
    
    @Relationship(inverse: \Book.rootFolder)
    var book: Book?
    
    init(
        title: String = "",
        creationDate: Date = Date(),
        order: Int = 0,
        subfolders: [Folder]? = nil,
        documents: [Document]? = nil
    ) {
        self.title = title
        self.creationDate = creationDate
        self.order = order
        self.subfolders = subfolders
        self.documents = documents
    }
}

@Model
final class Document {
    var id: UUID = UUID()
    var title: String = ""
    var outlinePrompt: String = ""  // Template's outline guidance/questions
    var outline: String = ""        // User's actual outline/synopsis
    var notes: String = ""          // Additional notes
    var content: String = ""        // Main content
    var creationDate: Date = Date()
    var order: Int = 0
    var colorName: String = "Brown"  // Default color
    var iconName: String = "doc.text"  // Default icon
    
    @Relationship(inverse: \Folder.documents)
    var folder: Folder?
    
    @Relationship(deleteRule: .nullify)
    var characters: [Character]? = []
    
    @Relationship(deleteRule: .nullify)
    var locations: [Location]? = []
    
    init(
        title: String = "",
        outlinePrompt: String = "",
        outline: String = "",
        notes: String = "",
        content: String = "",
        creationDate: Date = Date(),
        order: Int = 0,
        colorName: String = "Brown",
        iconName: String = "doc.text",
        characters: [Character]? = nil,
        locations: [Location]? = nil
    ) {
        self.title = title
        self.outlinePrompt = outlinePrompt
        self.outline = outline
        self.notes = notes
        self.content = content
        self.creationDate = creationDate
        self.order = order
        self.colorName = colorName
        self.iconName = iconName
        self.characters = characters
        self.locations = locations
    }
}

@Model
final class Location {
    var id: UUID = UUID()
    var name: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    @Relationship(inverse: \Book.locations)
    var book: Book?
    
    @Relationship(inverse: \Document.locations)
    var appearsIn: [Document]? = []
    
    init(name: String = "", latitude: Double = 0.0, longitude: Double = 0.0) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
} 