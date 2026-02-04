import SwiftUI
import Combine

@MainActor
class DocumentManager: ObservableObject {
    @Published var document: ManuscriptDocument
    @Published var currentFolder: ManuscriptFolder
    @Published var selectedDocument: ManuscriptDocument.Document?
    @Published var isRenameAlertPresented = false
    @Published var renameAlertTitle = ""
    @Published var newItemName = ""
    
    private var itemToRename: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init(document: ManuscriptDocument) {
        self.document = document
        self.currentFolder = document.rootFolder
        
        // Set up autosave
        $document
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.autosave()
            }
            .store(in: &cancellables)
    }
    
    private func autosave() {
        // This will be triggered automatically when document changes
        // The DocumentGroup manages the actual saving
    }
    
    // MARK: - Document Navigation and Selection
    
    func navigateToFolder(_ folder: ManuscriptFolder) {
        currentFolder = folder
    }
    
    func navigateToRootFolder() {
        currentFolder = document.rootFolder
    }
    
    func selectDocument(_ doc: ManuscriptDocument.Document?) {
        selectedDocument = doc
    }
    
    // Helper method to find a document by ID
    func findDocument(withId id: UUID) -> ManuscriptDocument.Document? {
        return findDocumentRecursively(withId: id, in: document.rootFolder)
    }
    
    private func findDocumentRecursively(withId id: UUID, in folder: ManuscriptFolder) -> ManuscriptDocument.Document? {
        // Check documents in this folder
        if let document = folder.documents.first(where: { $0.id == id }) {
            return document
        }
        
        // Check documents in subfolders
        for subfolder in folder.subfolders {
            if let document = findDocumentRecursively(withId: id, in: subfolder) {
                return document
            }
        }
        
        return nil
    }
    
    // MARK: - Folder Management
    
    func addFolder(to parentFolder: ManuscriptFolder, title: String) {
        let newFolder = ManuscriptFolder(title: title)
        
        // Add to parent folder
        var updatedSubfolders = parentFolder.subfolders
        updatedSubfolders.append(newFolder)
        
        // Update parent folder with new subfolders
        if parentFolder.id == currentFolder.id {
            // If modifying current folder, update it
            var updatedCurrentFolder = currentFolder
            updatedCurrentFolder.subfolders = updatedSubfolders
            currentFolder = updatedCurrentFolder
            
            // Find and update in document structure
            updateFolderInDocument(parentFolder.id, with: updatedCurrentFolder)
        } else if parentFolder.id == document.rootFolder.id {
            // If modifying root folder
            var updatedRootFolder = document.rootFolder
            updatedRootFolder.subfolders = updatedSubfolders
            document.rootFolder = updatedRootFolder
            
            if currentFolder.id == document.rootFolder.id {
                currentFolder = updatedRootFolder
            }
        } else {
            // If modifying another folder, find and update it
            var updatedParentFolder = parentFolder
            updatedParentFolder.subfolders = updatedSubfolders
            updateFolderInDocument(parentFolder.id, with: updatedParentFolder)
        }
    }
    
    private func updateFolderInDocument(_ folderId: UUID, with updatedFolder: ManuscriptFolder) {
        document.rootFolder = updateFolderRecursively(document.rootFolder, folderId: folderId, updatedFolder: updatedFolder)
    }
    
    private func updateFolderRecursively(_ folder: ManuscriptFolder, folderId: UUID, updatedFolder: ManuscriptFolder) -> ManuscriptFolder {
        if folder.id == folderId {
            return updatedFolder
        }
        
        var updatedCurrentFolder = folder
        updatedCurrentFolder.subfolders = folder.subfolders.map { subfolder in
            updateFolderRecursively(subfolder, folderId: folderId, updatedFolder: updatedFolder)
        }
        
        return updatedCurrentFolder
    }
    
    func renameFolder(_ folder: ManuscriptFolder, newTitle: String) {
        var updatedFolder = folder
        updatedFolder.title = newTitle
        
        if folder.id == currentFolder.id {
            currentFolder = updatedFolder
        }
        
        if folder.id == document.rootFolder.id {
            document.rootFolder = updatedFolder
        } else {
            updateFolderInDocument(folder.id, with: updatedFolder)
        }
    }
    
    func deleteFolder(_ folder: ManuscriptFolder) {
        // Can't delete root folder
        guard folder.id != document.rootFolder.id else { return }
        
        // Find the parent folder and remove the subfolder
        document.rootFolder = removeFolderRecursively(document.rootFolder, folderIdToRemove: folder.id)
        
        // If we deleted the current folder, navigate to root
        if folder.id == currentFolder.id {
            navigateToRootFolder()
        }
    }
    
    private func removeFolderRecursively(_ folder: ManuscriptFolder, folderIdToRemove: UUID) -> ManuscriptFolder {
        var updatedFolder = folder
        
        // Check if this folder contains the folder to remove
        updatedFolder.subfolders = folder.subfolders.filter { $0.id != folderIdToRemove }
        
        // If we didn't find it directly, search deeper
        if updatedFolder.subfolders.count == folder.subfolders.count {
            updatedFolder.subfolders = folder.subfolders.map { subfolder in
                removeFolderRecursively(subfolder, folderIdToRemove: folderIdToRemove)
            }
        }
        
        return updatedFolder
    }
    
    // MARK: - Document Management
    
    func addDocument(to folder: ManuscriptFolder, title: String, synopsis: String = "", notes: String = "", content: String = "") {
        let nextOrder = folder.documents.count
        
        let document = ManuscriptDocument.Document(
            title: title,
            synopsis: synopsis,
            notes: notes,
            content: content,
            order: nextOrder,
            colorName: "Brown"  // Default color
        )
        
        var updatedFolder = folder
        var updatedDocuments = folder.documents
        updatedDocuments.append(document)
        updatedFolder.documents = updatedDocuments
        
        if folder.id == currentFolder.id {
            currentFolder = updatedFolder
        }
        
        if folder.id == self.document.rootFolder.id {
            self.document.rootFolder = updatedFolder
        } else {
            updateFolderInDocument(folder.id, with: updatedFolder)
        }
    }
    
    func updateDocument(_ doc: ManuscriptDocument.Document, title: String? = nil, synopsis: String? = nil, notes: String? = nil, content: String? = nil, characterIds: [UUID]? = nil, locationIds: [UUID]? = nil, keywords: [String]? = nil, linkedDocumentIds: [UUID]? = nil) {
        // Find the document in the folder structure
        let updatedDoc = updateDocumentProperties(doc, title: title, synopsis: synopsis, notes: notes, content: content, characterIds: characterIds, locationIds: locationIds, keywords: keywords, linkedDocumentIds: linkedDocumentIds)
        
        // Update document in the folder structure
        updateDocumentInFolders(docId: doc.id, updatedDoc: updatedDoc)
        
        // If this was the selected document, update it
        if selectedDocument?.id == doc.id {
            selectedDocument = updatedDoc
        }
    }
    
    private func updateDocumentProperties(_ doc: ManuscriptDocument.Document, title: String?, synopsis: String?, notes: String?, content: String?, characterIds: [UUID]?, locationIds: [UUID]?, keywords: [String]?, linkedDocumentIds: [UUID]?) -> ManuscriptDocument.Document {
        var updatedDoc = doc

        if let title = title {
            updatedDoc.title = title
        }

        if let synopsis = synopsis {
            updatedDoc.synopsis = synopsis
        }
        
        if let notes = notes {
            updatedDoc.notes = notes
        }
        
        if let content = content {
            updatedDoc.content = content
        }
        
        if let characterIds = characterIds {
            updatedDoc.characterIds = characterIds
        }
        
        if let locationIds = locationIds {
            updatedDoc.locationIds = locationIds
        }

        if let keywords = keywords {
            updatedDoc.keywords = keywords
        }

        if let linkedDocumentIds = linkedDocumentIds {
            updatedDoc.linkedDocumentIds = linkedDocumentIds
        }
        
        return updatedDoc
    }
    
    private func updateDocumentInFolders(docId: UUID, updatedDoc: ManuscriptDocument.Document) {
        // Start the search at the root folder
        document.rootFolder = updateDocumentInFolder(document.rootFolder, docId: docId, updatedDoc: updatedDoc)
        
        // If the document was in the current folder, update it
        if let index = currentFolder.documents.firstIndex(where: { $0.id == docId }) {
            var updatedDocs = currentFolder.documents
            updatedDocs[index] = updatedDoc
            currentFolder.documents = updatedDocs
        }
    }
    
    private func updateDocumentInFolder(_ folder: ManuscriptFolder, docId: UUID, updatedDoc: ManuscriptDocument.Document) -> ManuscriptFolder {
        var updatedFolder = folder
        
        // Check if document is in this folder
        if let index = folder.documents.firstIndex(where: { $0.id == docId }) {
            var updatedDocs = folder.documents
            updatedDocs[index] = updatedDoc
            updatedFolder.documents = updatedDocs
            return updatedFolder
        }
        
        // If not found, check in subfolders
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            updateDocumentInFolder(subfolder, docId: docId, updatedDoc: updatedDoc)
        }
        
        return updatedFolder
    }
    
    func deleteDocument(_ doc: ManuscriptDocument.Document) {
        // Update all folders to remove this document
        document.rootFolder = removeDocumentFromFolder(document.rootFolder, docId: doc.id)
        
        // If the document is in the current folder, update it
        if let index = currentFolder.documents.firstIndex(where: { $0.id == doc.id }) {
            var updatedDocs = currentFolder.documents
            updatedDocs.remove(at: index)
            currentFolder.documents = updatedDocs
        }
        
        // If this was the selected document, deselect it
        if selectedDocument?.id == doc.id {
            selectedDocument = nil
        }
        
        // Remove document from any character references
        for i in 0..<document.characters.count {
            document.characters[i].appearsInDocumentIds.removeAll { $0 == doc.id }
        }
        
        // Remove document from any location references
        for i in 0..<document.locations.count {
            document.locations[i].appearsInDocumentIds.removeAll { $0 == doc.id }
        }
    }
    
    private func removeDocumentFromFolder(_ folder: ManuscriptFolder, docId: UUID) -> ManuscriptFolder {
        var updatedFolder = folder
        
        // Remove document if it's in this folder
        updatedFolder.documents.removeAll { $0.id == docId }
        
        // Check subfolders
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            removeDocumentFromFolder(subfolder, docId: docId)
        }
        
        return updatedFolder
    }
    
    // MARK: - Character Management
    
    func addCharacter(name: String, age: Int? = nil, gender: ManuscriptCharacterGender = .notSpecified) {
        let character = ManuscriptCharacter(
            name: name,
            age: age,
            gender: gender
        )
        
        document.characters.append(character)
    }
    
    func updateCharacter(_ character: ManuscriptCharacter, name: String? = nil, age: Int? = nil, gender: ManuscriptCharacterGender? = nil) {
        guard let index = document.characters.firstIndex(where: { $0.id == character.id }) else { return }
        
        var updatedCharacter = character
        
        if let name = name {
            updatedCharacter.name = name
        }
        
        if let age = age {
            updatedCharacter.age = age
        }
        
        if let gender = gender {
            updatedCharacter.gender = gender
        }
        
        document.characters[index] = updatedCharacter
    }
    
    func deleteCharacter(_ character: ManuscriptCharacter) {
        document.characters.removeAll { $0.id == character.id }
        
        // Remove character from all documents
        let characterId = character.id
        removeCharacterFromAllDocuments(characterId)
    }
    
    private func removeCharacterFromAllDocuments(_ characterId: UUID) {
        document.rootFolder = removeCharacterFromFolderDocuments(document.rootFolder, characterId: characterId)
    }
    
    private func removeCharacterFromFolderDocuments(_ folder: ManuscriptFolder, characterId: UUID) -> ManuscriptFolder {
        var updatedFolder = folder
        
        // Update documents in this folder
        for i in 0..<updatedFolder.documents.count {
            updatedFolder.documents[i].characterIds.removeAll { $0 == characterId }
        }
        
        // Update documents in subfolders
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            removeCharacterFromFolderDocuments(subfolder, characterId: characterId)
        }
        
        return updatedFolder
    }
    
    // MARK: - Location Management
    
    func addLocation(name: String, latitude: Double, longitude: Double) {
        let location = ManuscriptLocation(
            name: name,
            latitude: latitude,
            longitude: longitude
        )
        
        document.locations.append(location)
    }
    
    func updateLocation(_ location: ManuscriptLocation, name: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        guard let index = document.locations.firstIndex(where: { $0.id == location.id }) else { return }
        
        var updatedLocation = location
        
        if let name = name {
            updatedLocation.name = name
        }
        
        if let latitude = latitude {
            updatedLocation.latitude = latitude
        }
        
        if let longitude = longitude {
            updatedLocation.longitude = longitude
        }
        
        document.locations[index] = updatedLocation
    }
    
    func deleteLocation(_ location: ManuscriptLocation) {
        document.locations.removeAll { $0.id == location.id }
        
        // Remove location from all documents
        let locationId = location.id
        removeLocationFromAllDocuments(locationId)
    }
    
    private func removeLocationFromAllDocuments(_ locationId: UUID) {
        document.rootFolder = removeLocationFromFolderDocuments(document.rootFolder, locationId: locationId)
    }
    
    private func removeLocationFromFolderDocuments(_ folder: ManuscriptFolder, locationId: UUID) -> ManuscriptFolder {
        var updatedFolder = folder
        
        // Update documents in this folder
        for i in 0..<updatedFolder.documents.count {
            updatedFolder.documents[i].locationIds.removeAll { $0 == locationId }
        }
        
        // Update documents in subfolders
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            removeLocationFromFolderDocuments(subfolder, locationId: locationId)
        }
        
        return updatedFolder
    }
    
    // MARK: - Rename UI Management
    
    func showRenameAlert(for item: Any) {
        itemToRename = item
        
        if let folder = item as? ManuscriptFolder {
            renameAlertTitle = "Rename Folder"
            newItemName = folder.title
            isRenameAlertPresented = true
        } else if let document = item as? ManuscriptDocument.Document {
            renameAlertTitle = "Rename Document"
            newItemName = document.title
            isRenameAlertPresented = true
        } else if let character = item as? ManuscriptCharacter {
            renameAlertTitle = "Rename Character"
            newItemName = character.name
            isRenameAlertPresented = true
        } else if let location = item as? ManuscriptLocation {
            renameAlertTitle = "Rename Location"
            newItemName = location.name
            isRenameAlertPresented = true
        }
    }
    
    func performRename() {
        switch itemToRename {
        case let folder as ManuscriptFolder:
            renameFolder(folder, newTitle: newItemName)
        case let doc as ManuscriptDocument.Document:
            updateDocument(doc, title: newItemName)
        case let character as ManuscriptCharacter:
            updateCharacter(character, name: newItemName)
        case let location as ManuscriptLocation:
            updateLocation(location, name: newItemName)
        default:
            break
        }
    }
} 
