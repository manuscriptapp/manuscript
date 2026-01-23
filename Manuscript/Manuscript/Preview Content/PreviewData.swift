#if DEBUG
import SwiftUI

struct PreviewData {
    // MARK: - Sample Documents

    static var sampleManuscript: ManuscriptDocument {
        var doc = ManuscriptDocument()
        doc.title = "The Dragon's Path"
        doc.author = "Sarah Stormborn"
        doc.description = "A young dragon rider discovers her destiny as the last hope for peace between humans and dragons."
        doc.genre = "Fantasy"

        // Add sample documents to draft folder
        let chapter1 = ManuscriptDocument.Document(
            title: "Chapter 1: The Beginning",
            synopsis: "Our hero discovers their powers",
            notes: "Set the scene in the mountain village",
            content: "The morning mist clung to the peaks like a shroud...",
            order: 0
        )

        let chapter2 = ManuscriptDocument.Document(
            title: "Chapter 2: The Call",
            synopsis: "The mentor appears",
            notes: "Introduce Master Chen",
            content: "Three days after the incident, the stranger arrived...",
            order: 1
        )

        doc.rootFolder.documents = [chapter1, chapter2]

        // Add sample characters
        doc.characters = [
            ManuscriptCharacter(
                name: "Aria Windweaver",
                age: 18,
                gender: .female,
                description: "The protagonist, a young woman with the rare ability to bond with dragons."
            ),
            ManuscriptCharacter(
                name: "Master Chen",
                age: 65,
                gender: .male,
                description: "The wise mentor who guides Aria on her journey."
            ),
            ManuscriptCharacter(
                name: "Lord Blackthorn",
                age: 45,
                gender: .male,
                description: "The antagonist who seeks to control all dragons."
            )
        ]

        // Add sample locations
        doc.locations = [
            ManuscriptLocation(
                name: "Dragon's Peak",
                description: "A towering mountain where dragons nest.",
                latitude: 45.8989,
                longitude: -119.4237
            ),
            ManuscriptLocation(
                name: "The Academy",
                description: "The ancient school where dragon riders train.",
                latitude: 51.5074,
                longitude: -0.1278
            )
        ]

        return doc
    }

    static var emptyManuscript: ManuscriptDocument {
        ManuscriptDocument()
    }

    // MARK: - Sample Components

    static var sampleDocument: ManuscriptDocument.Document {
        ManuscriptDocument.Document(
            title: "Sample Chapter",
            synopsis: "A brief synopsis of the chapter",
            notes: "Notes for the author",
            content: "The story begins here with compelling prose that draws the reader in...",
            order: 0
        )
    }

    static var sampleFolder: ManuscriptFolder {
        ManuscriptFolder(
            title: "Part 1",
            folderType: .subfolder,
            documents: [
                ManuscriptDocument.Document(title: "Chapter 1", content: "Content 1", order: 0),
                ManuscriptDocument.Document(title: "Chapter 2", content: "Content 2", order: 1)
            ]
        )
    }

    static var sampleCharacter: ManuscriptCharacter {
        ManuscriptCharacter(
            name: "Alice",
            age: 25,
            gender: .female,
            description: "The protagonist"
        )
    }

    static var sampleLocation: ManuscriptLocation {
        ManuscriptLocation(
            name: "Central Park",
            description: "A large urban park",
            latitude: 40.7829,
            longitude: -73.9654
        )
    }
}
#endif
