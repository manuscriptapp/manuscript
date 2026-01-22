import Foundation

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
