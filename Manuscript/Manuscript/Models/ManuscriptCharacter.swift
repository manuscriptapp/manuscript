import Foundation

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
