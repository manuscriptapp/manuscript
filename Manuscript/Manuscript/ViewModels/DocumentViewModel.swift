import SwiftUI
import Combine

/// Unified view model for document operations.
/// Works with @Binding to ensure changes propagate to DocumentGroup for autosave.
@MainActor
class DocumentViewModel: ObservableObject {
    // MARK: - Published State
    @Published var currentFolder: ManuscriptFolder
    @Published var selectedDocument: ManuscriptDocument.Document?
    @Published var detailSelection: DetailSelection?

    // Sidebar expansion state - tracks which folders are expanded
    @Published var expandedFolderIds: Set<UUID> = []

    // Published root folder for sidebar display - this is the source of truth for UI
    @Published private(set) var rootFolder: ManuscriptFolder = ManuscriptFolder(title: "Draft")

    // Published document title for sidebar display
    @Published private(set) var documentTitle: String = ""

    // Rename state
    @Published var isRenameAlertPresented = false
    @Published var renameAlertTitle = ""
    @Published var newItemName = ""

    private var itemToRename: Any?

    // Reference to the document binding - set by the view
    private var documentBinding: Binding<ManuscriptDocument>?

    // Computed property to access document through binding
    var document: ManuscriptDocument {
        get { documentBinding?.wrappedValue ?? ManuscriptDocument() }
        set {
            documentBinding?.wrappedValue = newValue
            // Update the published rootFolder for immediate UI updates
            rootFolder = newValue.rootFolder
            // Update the published title for sidebar display
            documentTitle = newValue.title
        }
    }

    init() {
        self.currentFolder = ManuscriptFolder(title: "Draft")
    }

    /// Connect this view model to the document binding from DocumentGroup
    func bind(to document: Binding<ManuscriptDocument>) {
        self.documentBinding = document
        self.rootFolder = document.wrappedValue.rootFolder
        self.currentFolder = document.wrappedValue.rootFolder
        self.documentTitle = document.wrappedValue.title
        // Auto-expand root folder
        expandedFolderIds.insert(document.wrappedValue.rootFolder.id)
    }

    // MARK: - Folder Expansion

    func isFolderExpanded(_ folder: ManuscriptFolder) -> Bool {
        expandedFolderIds.contains(folder.id)
    }

    func toggleFolderExpansion(_ folder: ManuscriptFolder) {
        if expandedFolderIds.contains(folder.id) {
            expandedFolderIds.remove(folder.id)
        } else {
            expandedFolderIds.insert(folder.id)
        }
    }

    func setFolderExpanded(_ folder: ManuscriptFolder, expanded: Bool) {
        if expanded {
            expandedFolderIds.insert(folder.id)
        } else {
            expandedFolderIds.remove(folder.id)
        }
    }

    /// Expands all ancestor folders to make the given folder visible in the sidebar
    func expandToFolder(_ targetFolder: ManuscriptFolder) {
        let ancestorIds = findAncestorIdsForFolder(targetFolder.id, in: document.rootFolder, path: [])
        for id in ancestorIds {
            expandedFolderIds.insert(id)
        }
    }

    /// Expands all ancestor folders to make the given document visible in the sidebar
    func expandToDocument(_ targetDocument: ManuscriptDocument.Document) {
        let ancestorIds = findAncestorIdsForDocument(targetDocument.id, in: document.rootFolder, path: [])
        for id in ancestorIds {
            expandedFolderIds.insert(id)
        }
    }

    /// Returns the path of folder IDs from root to the target folder (exclusive of target)
    private func findAncestorIdsForFolder(_ targetId: UUID, in folder: ManuscriptFolder, path: [UUID]) -> [UUID] {
        // Check if target is a direct child subfolder
        if folder.subfolders.contains(where: { $0.id == targetId }) {
            return path + [folder.id]
        }

        // Recursively search in subfolders
        for subfolder in folder.subfolders {
            let result = findAncestorIdsForFolder(targetId, in: subfolder, path: path + [folder.id])
            if !result.isEmpty {
                return result
            }
        }

        return []
    }

    /// Returns the path of folder IDs from root to the folder containing the target document
    private func findAncestorIdsForDocument(_ targetDocId: UUID, in folder: ManuscriptFolder, path: [UUID]) -> [UUID] {
        // Check if target document is in this folder
        if folder.documents.contains(where: { $0.id == targetDocId }) {
            return path + [folder.id]
        }

        // Recursively search in subfolders
        for subfolder in folder.subfolders {
            let result = findAncestorIdsForDocument(targetDocId, in: subfolder, path: path + [folder.id])
            if !result.isEmpty {
                return result
            }
        }

        return []
    }

    /// Sync current folder when document changes externally
    func syncWithDocument(_ newDocument: ManuscriptDocument) {
        // Update the published rootFolder for sidebar display
        rootFolder = newDocument.rootFolder
        // Update the published title
        documentTitle = newDocument.title
        // Update current folder if it still exists, otherwise go to root
        if let updatedFolder = findFolder(withId: currentFolder.id, in: newDocument.rootFolder) {
            currentFolder = updatedFolder
        } else {
            currentFolder = newDocument.rootFolder
        }
    }

    // MARK: - Navigation

    func navigateToFolder(_ folder: ManuscriptFolder) {
        currentFolder = folder
    }

    func navigateToRootFolder() {
        currentFolder = document.rootFolder
    }

    func selectDocument(_ doc: ManuscriptDocument.Document?) {
        selectedDocument = doc
    }

    // MARK: - Find Helpers

    func findDocument(withId id: UUID) -> ManuscriptDocument.Document? {
        return findDocumentRecursively(withId: id, in: rootFolder)
    }

    private func findDocumentRecursively(withId id: UUID, in folder: ManuscriptFolder) -> ManuscriptDocument.Document? {
        if let doc = folder.documents.first(where: { $0.id == id }) {
            return doc
        }
        for subfolder in folder.subfolders {
            if let doc = findDocumentRecursively(withId: id, in: subfolder) {
                return doc
            }
        }
        return nil
    }

    private func findFolder(withId id: UUID, in folder: ManuscriptFolder) -> ManuscriptFolder? {
        if folder.id == id { return folder }
        for subfolder in folder.subfolders {
            if let found = findFolder(withId: id, in: subfolder) {
                return found
            }
        }
        return nil
    }

    // MARK: - Project Management

    func updateProject(title: String, author: String, metaInfo: String) {
        var doc = document
        doc.title = title
        doc.author = author
        doc.metaDescription = metaInfo
        document = doc
    }

    // MARK: - Folder Management

    func addFolder(to parentFolder: ManuscriptFolder, title: String) {
        let newFolder = ManuscriptFolder(title: title)
        var doc = document
        doc.rootFolder = addFolderRecursively(to: doc.rootFolder, parentId: parentFolder.id, newFolder: newFolder)
        document = doc

        // Update current folder if needed
        if let updated = findFolder(withId: currentFolder.id, in: doc.rootFolder) {
            currentFolder = updated
        }

        // Expand all ancestor folders and the parent folder to show the new folder
        expandToFolder(newFolder)
        setFolderExpanded(parentFolder, expanded: true)
    }

    private func addFolderRecursively(to folder: ManuscriptFolder, parentId: UUID, newFolder: ManuscriptFolder) -> ManuscriptFolder {
        var updatedFolder = folder
        if folder.id == parentId {
            updatedFolder.subfolders.append(newFolder)
            return updatedFolder
        }
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            addFolderRecursively(to: subfolder, parentId: parentId, newFolder: newFolder)
        }
        return updatedFolder
    }

    func renameFolder(_ folder: ManuscriptFolder, newTitle: String) {
        var doc = document
        doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id) { f in
            var updated = f
            updated.title = newTitle
            return updated
        }
        document = doc

        if currentFolder.id == folder.id {
            currentFolder.title = newTitle
        }
    }

    func updateFolderIcon(_ folder: ManuscriptFolder, iconName: String, iconColor: String? = nil) {
        var doc = document
        doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id) { f in
            var updated = f
            updated.iconName = iconName
            if let color = iconColor {
                updated.iconColor = color
            }
            return updated
        }
        document = doc

        if currentFolder.id == folder.id {
            currentFolder.iconName = iconName
            if let color = iconColor {
                currentFolder.iconColor = color
            }
        }
    }

    func updateFolderIconColor(_ folder: ManuscriptFolder, hexColor: String?) {
        var doc = document
        doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id) { f in
            var updated = f
            updated.iconColor = hexColor
            return updated
        }
        document = doc

        if currentFolder.id == folder.id {
            currentFolder.iconColor = hexColor
        }
    }

    func deleteFolder(_ folder: ManuscriptFolder) {
        guard folder.id != document.rootFolder.id else { return }

        var doc = document
        doc.rootFolder = removeFolderRecursively(doc.rootFolder, folderIdToRemove: folder.id)
        document = doc

        if folder.id == currentFolder.id {
            navigateToRootFolder()
        }
    }

    private func updateFolderRecursively(_ folder: ManuscriptFolder, folderId: UUID, transform: (ManuscriptFolder) -> ManuscriptFolder) -> ManuscriptFolder {
        if folder.id == folderId {
            return transform(folder)
        }
        var updatedFolder = folder
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            updateFolderRecursively(subfolder, folderId: folderId, transform: transform)
        }
        return updatedFolder
    }

    private func removeFolderRecursively(_ folder: ManuscriptFolder, folderIdToRemove: UUID) -> ManuscriptFolder {
        var updatedFolder = folder
        updatedFolder.subfolders = folder.subfolders.filter { $0.id != folderIdToRemove }
        if updatedFolder.subfolders.count == folder.subfolders.count {
            updatedFolder.subfolders = folder.subfolders.map { subfolder in
                removeFolderRecursively(subfolder, folderIdToRemove: folderIdToRemove)
            }
        }
        return updatedFolder
    }

    // MARK: - Document Management

    func addDocument(to folder: ManuscriptFolder, title: String, outline: String = "", notes: String = "", content: String = "") {
        let nextOrder = folder.documents.count
        let newDoc = ManuscriptDocument.Document(
            title: title,
            outline: outline,
            notes: notes,
            content: content,
            order: nextOrder,
            colorName: "Yellow"
        )

        var doc = document
        doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id) { f in
            var updated = f
            updated.documents.append(newDoc)
            return updated
        }
        document = doc

        if let updated = findFolder(withId: currentFolder.id, in: doc.rootFolder) {
            currentFolder = updated
        }

        // Expand all ancestor folders and the target folder to show the new document
        expandToDocument(newDoc)
        setFolderExpanded(folder, expanded: true)
    }

    func updateDocument(_ docToUpdate: ManuscriptDocument.Document, title: String? = nil, outline: String? = nil, notes: String? = nil, content: String? = nil, characterIds: [UUID]? = nil, locationIds: [UUID]? = nil, iconName: String? = nil, colorName: String? = nil, comments: [ManuscriptDocument.DocumentComment]? = nil) {
        // Track word count change for writing history
        let oldWordCount = docToUpdate.wordCount

        var updatedDoc = docToUpdate
        if let title = title { updatedDoc.title = title }
        if let outline = outline { updatedDoc.outline = outline }
        if let notes = notes { updatedDoc.notes = notes }
        if let content = content { updatedDoc.content = content }
        if let characterIds = characterIds { updatedDoc.characterIds = characterIds }
        if let locationIds = locationIds { updatedDoc.locationIds = locationIds }
        if let iconName = iconName { updatedDoc.iconName = iconName }
        if let colorName = colorName { updatedDoc.colorName = colorName }
        if let comments = comments { updatedDoc.comments = comments }

        var doc = document
        doc.rootFolder = updateDocumentInFolder(doc.rootFolder, docId: docToUpdate.id, updatedDoc: updatedDoc)

        // Track writing history if content changed and words were added
        if content != nil {
            let newWordCount = updatedDoc.wordCount
            let wordDifference = newWordCount - oldWordCount
            if wordDifference > 0 {
                doc.writingHistory.recordWords(wordDifference, draftTotal: doc.rootFolder.totalWordCount)
            }
        }

        document = doc

        if selectedDocument?.id == docToUpdate.id {
            selectedDocument = updatedDoc
        }
        if let updated = findFolder(withId: currentFolder.id, in: doc.rootFolder) {
            currentFolder = updated
        }
    }

    private func updateDocumentInFolder(_ folder: ManuscriptFolder, docId: UUID, updatedDoc: ManuscriptDocument.Document) -> ManuscriptFolder {
        var updatedFolder = folder
        if let index = folder.documents.firstIndex(where: { $0.id == docId }) {
            updatedFolder.documents[index] = updatedDoc
            return updatedFolder
        }
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            updateDocumentInFolder(subfolder, docId: docId, updatedDoc: updatedDoc)
        }
        return updatedFolder
    }

    func deleteDocument(_ doc: ManuscriptDocument.Document) {
        var document = self.document
        document.rootFolder = removeDocumentFromFolder(document.rootFolder, docId: doc.id)

        // Clean up character references
        for i in 0..<document.characters.count {
            document.characters[i].appearsInDocumentIds.removeAll { $0 == doc.id }
        }

        // Clean up location references
        for i in 0..<document.locations.count {
            document.locations[i].appearsInDocumentIds.removeAll { $0 == doc.id }
        }

        self.document = document

        if selectedDocument?.id == doc.id {
            selectedDocument = nil
        }
        if let updated = findFolder(withId: currentFolder.id, in: document.rootFolder) {
            currentFolder = updated
        }
    }

    private func removeDocumentFromFolder(_ folder: ManuscriptFolder, docId: UUID) -> ManuscriptFolder {
        var updatedFolder = folder
        updatedFolder.documents.removeAll { $0.id == docId }
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            removeDocumentFromFolder(subfolder, docId: docId)
        }
        return updatedFolder
    }

    func updateDocumentIcon(_ doc: ManuscriptDocument.Document, iconName: String) {
        updateDocument(doc, iconName: iconName)
    }

    func updateDocumentColor(_ doc: ManuscriptDocument.Document, colorName: String) {
        updateDocument(doc, colorName: colorName)
    }

    // MARK: - Character Management

    func addCharacter(name: String, age: Int? = nil, gender: ManuscriptCharacterGender = .notSpecified) {
        let character = ManuscriptCharacter(name: name, age: age, gender: gender)
        var doc = document
        doc.characters.append(character)
        document = doc
    }

    func updateCharacter(_ character: ManuscriptCharacter, name: String? = nil, age: Int? = nil, gender: ManuscriptCharacterGender? = nil) {
        guard let index = document.characters.firstIndex(where: { $0.id == character.id }) else { return }

        var doc = document
        if let name = name { doc.characters[index].name = name }
        if let age = age { doc.characters[index].age = age }
        if let gender = gender { doc.characters[index].gender = gender }
        document = doc
    }

    func deleteCharacter(_ character: ManuscriptCharacter) {
        var doc = document
        doc.characters.removeAll { $0.id == character.id }
        doc.rootFolder = removeCharacterFromAllDocuments(doc.rootFolder, characterId: character.id)
        document = doc
    }

    private func removeCharacterFromAllDocuments(_ folder: ManuscriptFolder, characterId: UUID) -> ManuscriptFolder {
        var updatedFolder = folder
        for i in 0..<updatedFolder.documents.count {
            updatedFolder.documents[i].characterIds.removeAll { $0 == characterId }
        }
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            removeCharacterFromAllDocuments(subfolder, characterId: characterId)
        }
        return updatedFolder
    }

    // MARK: - Location Management

    func addLocation(name: String, latitude: Double, longitude: Double) {
        let location = ManuscriptLocation(name: name, latitude: latitude, longitude: longitude)
        var doc = document
        doc.locations.append(location)
        document = doc
    }

    func updateLocation(_ location: ManuscriptLocation, name: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        guard let index = document.locations.firstIndex(where: { $0.id == location.id }) else { return }

        var doc = document
        if let name = name { doc.locations[index].name = name }
        if let latitude = latitude { doc.locations[index].latitude = latitude }
        if let longitude = longitude { doc.locations[index].longitude = longitude }
        document = doc
    }

    func deleteLocation(_ location: ManuscriptLocation) {
        var doc = document
        doc.locations.removeAll { $0.id == location.id }
        doc.rootFolder = removeLocationFromAllDocuments(doc.rootFolder, locationId: location.id)
        document = doc
    }

    private func removeLocationFromAllDocuments(_ folder: ManuscriptFolder, locationId: UUID) -> ManuscriptFolder {
        var updatedFolder = folder
        for i in 0..<updatedFolder.documents.count {
            updatedFolder.documents[i].locationIds.removeAll { $0 == locationId }
        }
        updatedFolder.subfolders = folder.subfolders.map { subfolder in
            removeLocationFromAllDocuments(subfolder, locationId: locationId)
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
        } else if let doc = item as? ManuscriptDocument.Document {
            renameAlertTitle = "Rename Document"
            newItemName = doc.title
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
        itemToRename = nil
    }
}
