#if DEBUG
import SwiftUI
import SwiftData

struct PreviewData {
    static var container: ModelContainer = {
        let schema = Schema([Book.self, Folder.self, Document.self, Location.self, Character.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        
        // Create the books first
        let flatBook = PreviewData.flatBook
        let groupedBook = PreviewData.groupedBook
        let heroJourneyBook = PreviewData.heroJourneyBook
        let blankBook = PreviewData.blankBook
        
        // Run context operations on main actor synchronously
        MainActor.assumeIsolated {
            let context = container.mainContext
            
            // Insert books into context
            context.insert(flatBook)
            context.insert(groupedBook)
            context.insert(heroJourneyBook)
            context.insert(blankBook)
            
            // Insert characters for each book
            if let characters = flatBook.characters {
                characters.forEach { context.insert($0) }
            }
            if let characters = groupedBook.characters {
                characters.forEach { context.insert($0) }
            }
            if let characters = heroJourneyBook.characters {
                characters.forEach { context.insert($0) }
            }
            
            // Insert folders and documents for each book
            if let rootFolder = flatBook.rootFolder {
                insertFolderHierarchy(rootFolder, in: context)
            }
            
            if let rootFolder = groupedBook.rootFolder {
                insertFolderHierarchy(rootFolder, in: context)
            }
            
            if let rootFolder = heroJourneyBook.rootFolder {
                insertFolderHierarchy(rootFolder, in: context)
            }
            
            // Insert locations for each book
            if let locations = flatBook.locations {
                locations.forEach { context.insert($0) }
            }
            if let locations = groupedBook.locations {
                locations.forEach { context.insert($0) }
            }
            if let locations = heroJourneyBook.locations {
                locations.forEach { context.insert($0) }
            }
            
            // Save all changes
            try? context.save()
        }
        
        return container
    }()
    
    private static func insertFolderHierarchy(_ folder: Folder, in context: ModelContext) {
        context.insert(folder)
        
        if let documents = folder.documents {
            documents.forEach { context.insert($0) }
        }
        
        if let subfolders = folder.subfolders {
            subfolders.forEach { insertFolderHierarchy($0, in: context) }
        }
    }
    
    static var emptyContainer: ModelContainer = {
        let schema = Schema([Book.self, Folder.self, Document.self, Location.self, Character.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        return container
    }()
    
    private static let flatBookId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let flatRootFolderId = UUID(uuidString: "11111111-1111-1111-1111-111111111112")!
    private static let flatDoc1Id = UUID(uuidString: "11111111-1111-1111-1111-111111111113")!
    private static let flatDoc2Id = UUID(uuidString: "11111111-1111-1111-1111-111111111114")!
    
    private static let groupedBookId = UUID(uuidString: "22222222-2222-2222-2222-222222222221")!
    private static let groupedRootFolderId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private static let groupedPart1Id = UUID(uuidString: "22222222-2222-2222-2222-222222222223")!
    private static let groupedPart2Id = UUID(uuidString: "22222222-2222-2222-2222-222222222224")!
    
    private static let heroJourneyBookId = UUID(uuidString: "33333333-3333-3333-3333-333333333331")!
    private static let heroJourneyRootFolderId = UUID(uuidString: "33333333-3333-3333-3333-333333333332")!
    
    private static let blankBookId = UUID(uuidString: "44444444-4444-4444-4444-444444444441")!
    private static let blankRootFolderId = UUID(uuidString: "44444444-4444-4444-4444-444444444442")!

    static var flatBook: Book {
        let rootFolder = Folder(title: "Draft")
        rootFolder.id = flatRootFolderId
        
        let documents = [
            Document(title: "Introduction", content: "The beginning of our story..."),
            Document(title: "Conclusion", content: "And that's how it ends...")
        ]
        documents[0].id = flatDoc1Id
        documents[1].id = flatDoc2Id
        documents.forEach { $0.folder = rootFolder }
        rootFolder.documents = documents
        
        let book = Book(
            title: "Flat Book",
            author: "Flat Author",
            metaDescription: "No grouping",
            style: "",
            genre: "",
            synopsis: "",
            templateId: nil,
            creationDate: Date().addingTimeInterval(-3600 * 24 * 3), // 3 days ago
            rootFolder: rootFolder,
            characters: [],
            locations: []
        )
        book.id = flatBookId
        rootFolder.book = book
        
        let characters = [
            Character(name: "Alice", age: 25, gender: .female),
            Character(name: "Bob", age: 30, gender: .male)
        ]
        characters[0].id = UUID(uuidString: "11111111-1111-1111-1111-111111111115")!
        characters[1].id = UUID(uuidString: "11111111-1111-1111-1111-111111111116")!
        characters.forEach { $0.book = book }
        book.characters = characters
        
        let locations = [
            Location(name: "Central Park", latitude: 40.7829, longitude: -73.9654),
            Location(name: "Times Square", latitude: 40.7580, longitude: -73.9855)
        ]
        locations[0].id = UUID(uuidString: "11111111-1111-1111-1111-111111111117")!
        locations[1].id = UUID(uuidString: "11111111-1111-1111-1111-111111111118")!
        book.locations = locations
        locations.forEach { $0.book = book }
        
        return book
    }
    
    static var groupedBook: Book {
        let rootFolder = Folder(title: "Draft", order: 0)
        rootFolder.id = groupedRootFolderId
        
        let part1 = Folder(title: "Part 1: The Beginning", order: 1)
        part1.id = groupedPart1Id
        let part2 = Folder(title: "Part 2: The Middle", order: 2)
        part2.id = groupedPart2Id
        
        let part1Docs = [
            Document(title: "Chapter 1", content: "Content 1"),
            Document(title: "Chapter 2", content: "Content 2")
        ]
        part1Docs[0].id = UUID(uuidString: "22222222-2222-2222-2222-222222222225")!
        part1Docs[1].id = UUID(uuidString: "22222222-2222-2222-2222-222222222226")!
        part1Docs.forEach { $0.folder = part1 }
        part1.documents = part1Docs
        
        let part2Docs = [
            Document(title: "Chapter 3", content: "Content 3"),
            Document(title: "Chapter 4", content: "Content 4")
        ]
        part2Docs[0].id = UUID(uuidString: "22222222-2222-2222-2222-222222222227")!
        part2Docs[1].id = UUID(uuidString: "22222222-2222-2222-2222-222222222228")!
        part2Docs.forEach { $0.folder = part2 }
        part2.documents = part2Docs
        
        part1.parentFolder = rootFolder
        part2.parentFolder = rootFolder
        rootFolder.subfolders = [part1, part2]
        
        let book = Book(
            title: "Grouped Book",
            author: "Grouped Author",
            metaDescription: "With grouping",
            style: "",
            genre: "",
            synopsis: "",
            templateId: nil,
            creationDate: Date().addingTimeInterval(-3600 * 24 * 2), // 2 days ago
            rootFolder: rootFolder,
            characters: [],
            locations: []
        )
        book.id = groupedBookId
        rootFolder.book = book
        
        let characters = [
            Character(name: "Charlie", age: 28, gender: .male),
            Character(name: "Dana", age: 32, gender: .female)
        ]
        characters[0].id = UUID(uuidString: "22222222-2222-2222-2222-222222222229")!
        characters[1].id = UUID(uuidString: "22222222-2222-2222-2222-22222222222A")!
        characters.forEach { $0.book = book }
        book.characters = characters
        
        let locations = [
            Location(name: "Hogwarts", latitude: 57.5934, longitude: -4.8947),
            Location(name: "Diagon Alley", latitude: 51.5074, longitude: -0.1278)
        ]
        locations[0].id = UUID(uuidString: "22222222-2222-2222-2222-22222222222B")!
        locations[1].id = UUID(uuidString: "22222222-2222-2222-2222-22222222222C")!
        book.locations = locations
        locations.forEach { $0.book = book }
        
        return book
    }
    
    static var heroJourneyBook: Book {
        let template = BookTemplate.heroJourney
        
        func createFolderFromTemplate(_ template: FolderTemplate, parentFolder: Folder? = nil) -> Folder {
            let folder = Folder(
                title: template.title,
                order: getDefaultOrder(title: template.title)
            )
            folder.parentFolder = parentFolder
            
            let documents = template.documents.map { doc in
                let document = Document(
                    title: doc.title,
                    outlinePrompt: doc.outlinePrompt,
                    content: doc.content,
                    order: doc.order
                )
                document.folder = folder
                return document
            }
            folder.documents = documents
            
            let subfolders = template.subfolders.map { subfolder in
                createFolderFromTemplate(subfolder, parentFolder: folder)
            }
            folder.subfolders = subfolders
            
            return folder
        }
        
        func getDefaultOrder(title: String) -> Int {
            switch title {
            case "Act 1": return 1
            case "Act 2": return 2
            case "Act 3": return 3
            default: return 0
            }
        }
        
        let rootFolder = createFolderFromTemplate(template.structure)
        rootFolder.id = heroJourneyRootFolderId
        
        let book = Book(
            title: "The Dragon's Path",
            author: "Sarah Stormborn",
            metaDescription: "A young dragon rider discovers her destiny as the last hope for peace between humans and dragons.",
            style: "",
            genre: "",
            synopsis: "",
            templateId: template.id,
            creationDate: Date().addingTimeInterval(-3600 * 24), // 1 day ago
            rootFolder: rootFolder,
            characters: [],
            locations: []
        )
        book.id = heroJourneyBookId
        rootFolder.book = book
        
        let characters = [
            Character(name: "Aria Windweaver", age: 18, gender: .female),
            Character(name: "Drakon the Elder Dragon", age: 1000, gender: .other),
            Character(name: "Master Chen", age: 65, gender: .male),
            Character(name: "Lord Blackthorn", age: 45, gender: .male),
            Character(name: "Princess Elena", age: 22, gender: .female)
        ]
        characters[0].id = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        characters[1].id = UUID(uuidString: "33333333-3333-3333-3333-333333333334")!
        characters[2].id = UUID(uuidString: "33333333-3333-3333-3333-333333333335")!
        characters[3].id = UUID(uuidString: "33333333-3333-3333-3333-333333333336")!
        characters[4].id = UUID(uuidString: "33333333-3333-3333-3333-333333333337")!
        characters.forEach { $0.book = book }
        book.characters = characters
        
        let locations = [
            Location(name: "Dragon's Peak", latitude: 45.8989, longitude: -119.4237),
            Location(name: "The Academy", latitude: 51.5074, longitude: -0.1278),
            Location(name: "Shadowvale", latitude: 48.8566, longitude: 2.3522),
            Location(name: "Crystal Caverns", latitude: 37.7749, longitude: -122.4194)
        ]
        locations[0].id = UUID(uuidString: "33333333-3333-3333-3333-333333333338")!
        locations[1].id = UUID(uuidString: "33333333-3333-3333-3333-333333333339")!
        locations[2].id = UUID(uuidString: "33333333-3333-3333-3333-33333333333A")!
        locations[3].id = UUID(uuidString: "33333333-3333-3333-3333-33333333333B")!
        book.locations = locations
        locations.forEach { $0.book = book }
        
        return book
    }
    
    static var blankBook: Book {
        let rootFolder = Folder(title: "Draft")
        rootFolder.id = blankRootFolderId
        
        let book = Book(
            title: "Blank Book",
            author: "New Author",
            metaDescription: "A fresh start",
            style: "",
            genre: "",
            synopsis: "",
            templateId: nil,
            creationDate: Date(), // Current time
            rootFolder: rootFolder,
            characters: [],
            locations: []
        )
        book.id = blankBookId
        rootFolder.book = book
        return book
    }
}
#endif 