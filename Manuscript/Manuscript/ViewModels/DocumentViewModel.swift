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

    // Published special folders for sidebar display
    @Published private(set) var researchFolder: ManuscriptFolder = ManuscriptFolder(title: "Research", folderType: .research, iconName: "books.vertical", iconColor: "#A2845E")
    @Published private(set) var trashFolder: ManuscriptFolder = ManuscriptFolder(title: "Trash", folderType: .trash, iconName: "trash", iconColor: "#8E8E93")

    // Published document title for sidebar display
    @Published private(set) var documentTitle: String = ""

    // Published characters and locations for sidebar display
    @Published private(set) var characters: [ManuscriptCharacter] = []
    @Published private(set) var locations: [ManuscriptLocation] = []

    // Rename state
    @Published var isRenameAlertPresented = false
    @Published var renameAlertTitle = ""
    @Published var newItemName = ""

    // Inline editing state for sidebar items
    @Published var documentIdBeingRenamed: UUID?

    // Snapshot feedback
    @Published var showSnapshotConfirmation: Bool = false
    @Published var lastSnapshotDocumentTitle: String = ""
    @Published var snapshotUpdateTrigger: Int = 0

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
            // Update the published special folders
            researchFolder = newValue.researchFolder ?? ManuscriptFolder(title: "Research", folderType: .research, iconName: "books.vertical", iconColor: "#A2845E")
            trashFolder = newValue.trashFolder ?? ManuscriptFolder(title: "Trash", folderType: .trash, iconName: "trash", iconColor: "#8E8E93")
            // Update the published title for sidebar display
            documentTitle = newValue.title
            // Update the published characters and locations for immediate UI updates
            characters = newValue.characters
            locations = newValue.locations
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
        self.researchFolder = document.wrappedValue.researchFolder ?? ManuscriptFolder(title: "Research", folderType: .research, iconName: "books.vertical", iconColor: "#A2845E")
        self.trashFolder = document.wrappedValue.trashFolder ?? ManuscriptFolder(title: "Trash", folderType: .trash, iconName: "trash", iconColor: "#8E8E93")
        self.characters = document.wrappedValue.characters
        self.locations = document.wrappedValue.locations

        // Restore project state (expanded folders)
        let savedState = document.wrappedValue.projectState
        if !savedState.expandedFolderIds.isEmpty {
            expandedFolderIds = Set(savedState.expandedFolderIds)
        } else {
            // Auto-expand root folder if no saved state
            expandedFolderIds.insert(document.wrappedValue.rootFolder.id)
        }
    }

    /// Returns the saved detail selection from project state
    func getSavedDetailSelection() -> DetailSelection? {
        return document.projectState.toDetailSelection(in: document)
    }

    /// Saves the current UI state to the document
    func saveProjectState(selection: DetailSelection?) {
        var doc = document
        doc.projectState = ProjectState.from(selection: selection, expandedFolderIds: expandedFolderIds)
        document = doc
    }

    /// Updates only the expanded folder IDs in the project state
    func saveExpandedFolderIds() {
        var doc = document
        doc.projectState.expandedFolderIds = Array(expandedFolderIds)
        document = doc
    }

    /// Saves the split editor state to the document
    func saveSplitEditorState(_ state: SplitEditorState) {
        var doc = document
        doc.projectState.splitEditorState = state
        document = doc
    }

    /// Returns the saved split editor state from project state
    func getSavedSplitEditorState() -> SplitEditorState {
        return document.projectState.splitEditorState
    }

    /// Returns all documents in the project for the split view document picker
    func getAllDocuments() -> [ManuscriptDocument.Document] {
        return collectDocumentsRecursively(from: rootFolder)
    }

    private func collectDocumentsRecursively(from folder: ManuscriptFolder) -> [ManuscriptDocument.Document] {
        var documents = folder.documents
        for subfolder in folder.subfolders {
            documents.append(contentsOf: collectDocumentsRecursively(from: subfolder))
        }
        return documents
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
        // Update the published special folders
        researchFolder = newDocument.researchFolder ?? ManuscriptFolder(title: "Research", folderType: .research, iconName: "books.vertical", iconColor: "#A2845E")
        trashFolder = newDocument.trashFolder ?? ManuscriptFolder(title: "Trash", folderType: .trash, iconName: "trash", iconColor: "#8E8E93")
        // Update the published title
        documentTitle = newDocument.title
        // Update current folder if it still exists, otherwise go to root
        if let updatedFolder = findFolderInAllFolders(withId: currentFolder.id) {
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

    func findFolder(withId id: UUID, in folder: ManuscriptFolder) -> ManuscriptFolder? {
        if folder.id == id { return folder }
        for subfolder in folder.subfolders {
            if let found = findFolder(withId: id, in: subfolder) {
                return found
            }
        }
        return nil
    }

    /// Finds a folder by ID in all folder hierarchies (root, research, trash)
    func findFolderInAllFolders(withId id: UUID) -> ManuscriptFolder? {
        // Search in root folder
        if let found = findFolder(withId: id, in: rootFolder) {
            return found
        }
        // Search in research folder
        if let found = findFolder(withId: id, in: researchFolder) {
            return found
        }
        // Search in trash folder
        if let found = findFolder(withId: id, in: trashFolder) {
            return found
        }
        return nil
    }

    /// Finds the parent folder containing a given document
    func findParentFolder(of doc: ManuscriptDocument.Document) -> ManuscriptFolder? {
        return findParentFolderRecursively(of: doc.id, in: rootFolder)
    }

    private func findParentFolderRecursively(of docId: UUID, in folder: ManuscriptFolder) -> ManuscriptFolder? {
        // Check if this folder contains the document
        if folder.documents.contains(where: { $0.id == docId }) {
            return folder
        }
        // Search in subfolders
        for subfolder in folder.subfolders {
            if let found = findParentFolderRecursively(of: docId, in: subfolder) {
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
        doc.description = metaInfo
        document = doc
    }

    // MARK: - Folder Management

    /// Determines which folder hierarchy contains the given folder ID
    private func folderHierarchyContaining(folderId: UUID) -> FolderHierarchy? {
        if findFolder(withId: folderId, in: rootFolder) != nil {
            return .root
        }
        if findFolder(withId: folderId, in: researchFolder) != nil {
            return .research
        }
        if findFolder(withId: folderId, in: trashFolder) != nil {
            return .trash
        }
        return nil
    }

    private enum FolderHierarchy {
        case root, research, trash
    }

    func addFolder(to parentFolder: ManuscriptFolder, title: String) {
        let newFolder = ManuscriptFolder(title: title)
        var doc = document

        // Determine which folder hierarchy to update
        if let hierarchy = folderHierarchyContaining(folderId: parentFolder.id) {
            switch hierarchy {
            case .root:
                doc.rootFolder = addFolderRecursively(to: doc.rootFolder, parentId: parentFolder.id, newFolder: newFolder)
            case .research:
                doc.researchFolder = addFolderRecursively(to: doc.researchFolder ?? researchFolder, parentId: parentFolder.id, newFolder: newFolder)
            case .trash:
                doc.trashFolder = addFolderRecursively(to: doc.trashFolder ?? trashFolder, parentId: parentFolder.id, newFolder: newFolder)
            }
        }
        document = doc

        // Update current folder if needed
        if let updated = findFolderInAllFolders(withId: currentFolder.id) {
            currentFolder = updated
        }

        // Expand all ancestor folders and the parent folder to show the new folder
        expandToFolder(newFolder)
        setFolderExpanded(parentFolder, expanded: true)

        // Auto-select the new folder
        detailSelection = .folder(newFolder)
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

        // Update in all folder hierarchies
        if let hierarchy = folderHierarchyContaining(folderId: folder.id) {
            switch hierarchy {
            case .root:
                doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.title = newTitle
                    return updated
                }
            case .research:
                doc.researchFolder = updateFolderRecursively(doc.researchFolder ?? researchFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.title = newTitle
                    return updated
                }
            case .trash:
                doc.trashFolder = updateFolderRecursively(doc.trashFolder ?? trashFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.title = newTitle
                    return updated
                }
            }
        }
        document = doc

        if currentFolder.id == folder.id {
            currentFolder.title = newTitle
        }
    }

    func updateFolderIcon(_ folder: ManuscriptFolder, iconName: String, iconColor: String? = nil) {
        var doc = document

        // Update in all folder hierarchies
        if let hierarchy = folderHierarchyContaining(folderId: folder.id) {
            switch hierarchy {
            case .root:
                doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.iconName = iconName
                    if let color = iconColor {
                        updated.iconColor = color
                    }
                    return updated
                }
            case .research:
                doc.researchFolder = updateFolderRecursively(doc.researchFolder ?? researchFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.iconName = iconName
                    if let color = iconColor {
                        updated.iconColor = color
                    }
                    return updated
                }
            case .trash:
                doc.trashFolder = updateFolderRecursively(doc.trashFolder ?? trashFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.iconName = iconName
                    if let color = iconColor {
                        updated.iconColor = color
                    }
                    return updated
                }
            }
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

        // Update in all folder hierarchies
        if let hierarchy = folderHierarchyContaining(folderId: folder.id) {
            switch hierarchy {
            case .root:
                doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.iconColor = hexColor
                    return updated
                }
            case .research:
                doc.researchFolder = updateFolderRecursively(doc.researchFolder ?? researchFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.iconColor = hexColor
                    return updated
                }
            case .trash:
                doc.trashFolder = updateFolderRecursively(doc.trashFolder ?? trashFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.iconColor = hexColor
                    return updated
                }
            }
        }
        document = doc

        if currentFolder.id == folder.id {
            currentFolder.iconColor = hexColor
        }
    }

    func deleteFolder(_ folder: ManuscriptFolder) {
        // Don't allow deleting root folders
        guard folder.id != document.rootFolder.id,
              folder.id != researchFolder.id,
              folder.id != trashFolder.id else { return }

        var doc = document

        // Remove from all folder hierarchies
        if let hierarchy = folderHierarchyContaining(folderId: folder.id) {
            switch hierarchy {
            case .root:
                doc.rootFolder = removeFolderRecursively(doc.rootFolder, folderIdToRemove: folder.id)
            case .research:
                doc.researchFolder = removeFolderRecursively(doc.researchFolder ?? researchFolder, folderIdToRemove: folder.id)
            case .trash:
                doc.trashFolder = removeFolderRecursively(doc.trashFolder ?? trashFolder, folderIdToRemove: folder.id)
            }
        }
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

    /// Creates a new untitled document and triggers inline renaming in the sidebar
    func addUntitledDocument(to folder: ManuscriptFolder) {
        let nextOrder = folder.documents.count
        let newDoc = ManuscriptDocument.Document(
            title: "",
            synopsis: "",
            notes: "",
            content: "",
            order: nextOrder,
            colorName: "Brown"
        )

        var doc = document

        // Determine which folder hierarchy to update
        if let hierarchy = folderHierarchyContaining(folderId: folder.id) {
            switch hierarchy {
            case .root:
                doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.documents.append(newDoc)
                    return updated
                }
            case .research:
                doc.researchFolder = updateFolderRecursively(doc.researchFolder ?? researchFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.documents.append(newDoc)
                    return updated
                }
            case .trash:
                doc.trashFolder = updateFolderRecursively(doc.trashFolder ?? trashFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.documents.append(newDoc)
                    return updated
                }
            }
        }
        document = doc

        if let updated = findFolderInAllFolders(withId: currentFolder.id) {
            currentFolder = updated
        }

        // Expand all ancestor folders and the target folder to show the new document
        expandToDocument(newDoc)
        setFolderExpanded(folder, expanded: true)

        // Auto-select the new document
        detailSelection = .document(newDoc)

        // Trigger inline renaming after a short delay to allow the UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.documentIdBeingRenamed = newDoc.id
        }
    }

    func addDocument(to folder: ManuscriptFolder, title: String, synopsis: String = "", notes: String = "", content: String = "") {
        let nextOrder = folder.documents.count
        let newDoc = ManuscriptDocument.Document(
            title: title,
            synopsis: synopsis,
            notes: notes,
            content: content,
            order: nextOrder,
            colorName: "Brown"
        )

        var doc = document

        // Determine which folder hierarchy to update
        if let hierarchy = folderHierarchyContaining(folderId: folder.id) {
            switch hierarchy {
            case .root:
                doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.documents.append(newDoc)
                    return updated
                }
            case .research:
                doc.researchFolder = updateFolderRecursively(doc.researchFolder ?? researchFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.documents.append(newDoc)
                    return updated
                }
            case .trash:
                doc.trashFolder = updateFolderRecursively(doc.trashFolder ?? trashFolder, folderId: folder.id) { f in
                    var updated = f
                    updated.documents.append(newDoc)
                    return updated
                }
            }
        }
        document = doc

        if let updated = findFolderInAllFolders(withId: currentFolder.id) {
            currentFolder = updated
        }

        // Expand all ancestor folders and the target folder to show the new document
        expandToDocument(newDoc)
        setFolderExpanded(folder, expanded: true)

        // Auto-select the new document
        detailSelection = .document(newDoc)
    }

    func updateDocument(_ docToUpdate: ManuscriptDocument.Document, title: String? = nil, synopsis: String? = nil, notes: String? = nil, content: String? = nil, characterIds: [UUID]? = nil, locationIds: [UUID]? = nil, iconName: String? = nil, colorName: String? = nil, comments: [ManuscriptDocument.DocumentComment]? = nil) {
        // Track word count change for writing history
        let oldWordCount = docToUpdate.wordCount

        var updatedDoc = docToUpdate
        if let title = title { updatedDoc.title = title }
        if let synopsis = synopsis { updatedDoc.synopsis = synopsis }
        if let notes = notes { updatedDoc.notes = notes }
        if let content = content { updatedDoc.content = content }
        if let characterIds = characterIds { updatedDoc.characterIds = characterIds }
        if let locationIds = locationIds { updatedDoc.locationIds = locationIds }
        if let iconName = iconName { updatedDoc.iconName = iconName }
        if let colorName = colorName { updatedDoc.colorName = colorName }
        if let comments = comments { updatedDoc.comments = comments }

        var doc = document

        // Update in all folder hierarchies
        doc.rootFolder = updateDocumentInFolder(doc.rootFolder, docId: docToUpdate.id, updatedDoc: updatedDoc)
        doc.researchFolder = updateDocumentInFolder(doc.researchFolder ?? researchFolder, docId: docToUpdate.id, updatedDoc: updatedDoc)
        doc.trashFolder = updateDocumentInFolder(doc.trashFolder ?? trashFolder, docId: docToUpdate.id, updatedDoc: updatedDoc)

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
        if let updated = findFolderInAllFolders(withId: currentFolder.id) {
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

        // Remove from all folder hierarchies
        document.rootFolder = removeDocumentFromFolder(document.rootFolder, docId: doc.id)
        document.researchFolder = removeDocumentFromFolder(document.researchFolder ?? researchFolder, docId: doc.id)
        document.trashFolder = removeDocumentFromFolder(document.trashFolder ?? trashFolder, docId: doc.id)

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
        if let updated = findFolderInAllFolders(withId: currentFolder.id) {
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

    /// Update document label and status metadata (used by outline view inline editing)
    func updateDocumentMetadata(_ doc: ManuscriptDocument.Document, labelId: String?, statusId: String?) {
        var updatedDoc = doc
        updatedDoc.labelId = labelId
        updatedDoc.statusId = statusId

        var document = self.document

        // Update in all folder hierarchies
        document.rootFolder = updateDocumentInFolder(document.rootFolder, docId: doc.id, updatedDoc: updatedDoc)
        document.researchFolder = updateDocumentInFolder(document.researchFolder ?? researchFolder, docId: doc.id, updatedDoc: updatedDoc)
        document.trashFolder = updateDocumentInFolder(document.trashFolder ?? trashFolder, docId: doc.id, updatedDoc: updatedDoc)

        self.document = document

        if selectedDocument?.id == doc.id {
            selectedDocument = updatedDoc
        }
        if let updated = findFolderInAllFolders(withId: currentFolder.id) {
            currentFolder = updated
        }
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

    // MARK: - Reordering

    /// Move documents within a folder from source indices to a destination index
    func moveDocuments(in folder: ManuscriptFolder, from source: IndexSet, to destination: Int) {
        // Force UI update notification
        objectWillChange.send()

        var doc = document

        let moveTransform: (ManuscriptFolder) -> ManuscriptFolder = { f in
            var updated = f
            updated.documents.move(fromOffsets: source, toOffset: destination)
            // Update order property to match new positions
            for (index, _) in updated.documents.enumerated() {
                updated.documents[index].order = index
            }
            return updated
        }

        // Determine which folder hierarchy to update
        if let hierarchy = folderHierarchyContaining(folderId: folder.id) {
            switch hierarchy {
            case .root:
                doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id, transform: moveTransform)
            case .research:
                doc.researchFolder = updateFolderRecursively(doc.researchFolder ?? researchFolder, folderId: folder.id, transform: moveTransform)
            case .trash:
                doc.trashFolder = updateFolderRecursively(doc.trashFolder ?? trashFolder, folderId: folder.id, transform: moveTransform)
            }
        }
        document = doc
        if let updated = findFolderInAllFolders(withId: currentFolder.id) {
            currentFolder = updated
        }
    }

    /// Move subfolders within a folder from source indices to a destination index
    func moveSubfolders(in folder: ManuscriptFolder, from source: IndexSet, to destination: Int) {
        var doc = document

        let moveTransform: (ManuscriptFolder) -> ManuscriptFolder = { f in
            var updated = f
            updated.subfolders.move(fromOffsets: source, toOffset: destination)
            // Update order property to match new positions
            for (index, _) in updated.subfolders.enumerated() {
                updated.subfolders[index].order = index
            }
            return updated
        }

        // Determine which folder hierarchy to update
        if let hierarchy = folderHierarchyContaining(folderId: folder.id) {
            switch hierarchy {
            case .root:
                doc.rootFolder = updateFolderRecursively(doc.rootFolder, folderId: folder.id, transform: moveTransform)
            case .research:
                doc.researchFolder = updateFolderRecursively(doc.researchFolder ?? researchFolder, folderId: folder.id, transform: moveTransform)
            case .trash:
                doc.trashFolder = updateFolderRecursively(doc.trashFolder ?? trashFolder, folderId: folder.id, transform: moveTransform)
            }
        }
        document = doc
        if let updated = findFolderInAllFolders(withId: currentFolder.id) {
            currentFolder = updated
        }
    }

    // MARK: - Cross-Folder Movement

    /// Move a document to a different folder
    func moveDocumentToFolder(_ docId: UUID, targetFolderId: UUID) {
        guard let doc = findDocument(withId: docId),
              let sourceFolder = findParentFolder(of: doc),
              sourceFolder.id != targetFolderId else { return }

        // Force UI update notification
        objectWillChange.send()

        var manuscriptDoc = document

        // Remove from source folder
        manuscriptDoc.rootFolder = updateFolderRecursively(manuscriptDoc.rootFolder, folderId: sourceFolder.id) { f in
            var updated = f
            updated.documents.removeAll { $0.id == docId }
            // Reindex remaining documents
            for (index, _) in updated.documents.enumerated() {
                updated.documents[index].order = index
            }
            return updated
        }

        // Add to target folder
        manuscriptDoc.rootFolder = updateFolderRecursively(manuscriptDoc.rootFolder, folderId: targetFolderId) { f in
            var updated = f
            var docToAdd = doc
            docToAdd.order = updated.documents.count
            updated.documents.append(docToAdd)
            return updated
        }

        document = manuscriptDoc
        if let updated = findFolder(withId: currentFolder.id, in: manuscriptDoc.rootFolder) {
            currentFolder = updated
        }
    }

    /// Move a folder to a different parent folder
    func moveFolderToParent(_ folderId: UUID, targetParentId: UUID) {
        // Prevent moving to self or descendant
        guard folderId != targetParentId,
              folderId != document.rootFolder.id,
              !isDescendant(folderId: targetParentId, ofFolderId: folderId) else { return }

        guard let folderToMove = findFolder(withId: folderId, in: document.rootFolder),
              let currentParent = findParentOfFolder(folderId),
              currentParent.id != targetParentId else { return }

        // Force UI update notification
        objectWillChange.send()

        var manuscriptDoc = document

        // Remove from current parent
        manuscriptDoc.rootFolder = updateFolderRecursively(manuscriptDoc.rootFolder, folderId: currentParent.id) { f in
            var updated = f
            updated.subfolders.removeAll { $0.id == folderId }
            for (index, _) in updated.subfolders.enumerated() {
                updated.subfolders[index].order = index
            }
            return updated
        }

        // Add to target parent
        manuscriptDoc.rootFolder = updateFolderRecursively(manuscriptDoc.rootFolder, folderId: targetParentId) { f in
            var updated = f
            var folderCopy = folderToMove
            folderCopy.order = updated.subfolders.count
            updated.subfolders.append(folderCopy)
            return updated
        }

        document = manuscriptDoc
        if let updated = findFolder(withId: currentFolder.id, in: manuscriptDoc.rootFolder) {
            currentFolder = updated
        }
    }

    /// Find parent folder of a given folder
    private func findParentOfFolder(_ folderId: UUID) -> ManuscriptFolder? {
        return findParentOfFolderRecursively(folderId, in: document.rootFolder)
    }

    private func findParentOfFolderRecursively(_ folderId: UUID, in folder: ManuscriptFolder) -> ManuscriptFolder? {
        if folder.subfolders.contains(where: { $0.id == folderId }) {
            return folder
        }
        for subfolder in folder.subfolders {
            if let found = findParentOfFolderRecursively(folderId, in: subfolder) {
                return found
            }
        }
        return nil
    }

    /// Check if a folder is a descendant of another (prevents circular references)
    private func isDescendant(folderId: UUID, ofFolderId ancestorId: UUID) -> Bool {
        guard let ancestor = findFolder(withId: ancestorId, in: document.rootFolder) else { return false }
        return containsFolder(folderId, in: ancestor)
    }

    private func containsFolder(_ folderId: UUID, in folder: ManuscriptFolder) -> Bool {
        if folder.subfolders.contains(where: { $0.id == folderId }) { return true }
        return folder.subfolders.contains { containsFolder(folderId, in: $0) }
    }

    // MARK: - Rename UI Management

    func showRenameAlert(for item: Any) {
        itemToRename = item

        var title = ""
        var name = ""

        if let folder = item as? ManuscriptFolder {
            title = "Rename Folder"
            name = folder.title
        } else if let doc = item as? ManuscriptDocument.Document {
            title = "Rename Document"
            name = doc.title
        } else if let character = item as? ManuscriptCharacter {
            title = "Rename Character"
            name = character.name
        } else if let location = item as? ManuscriptLocation {
            title = "Rename Location"
            name = location.name
        }

        renameAlertTitle = title
        newItemName = name

        // Delay alert presentation on iOS to allow context menu to fully dismiss
        // This prevents the alert from being immediately dismissed due to iOS timing issues
        #if os(iOS)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.isRenameAlertPresented = true
        }
        #else
        isRenameAlertPresented = true
        #endif
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

    // MARK: - Snapshot Management

    /// Take a snapshot of a document
    func takeSnapshotOfDocument(_ doc: ManuscriptDocument.Document, title: String? = nil, type: DocumentSnapshot.SnapshotType = .manual) {
        let snapshot = DocumentSnapshot(
            documentId: doc.id,
            title: title,
            snapshotType: type,
            content: doc.content,
            notes: doc.notes,
            synopsis: doc.synopsis
        )
        addSnapshot(snapshot)

        // Show confirmation feedback
        lastSnapshotDocumentTitle = doc.title.isEmpty ? "Untitled Document" : doc.title
        showSnapshotConfirmation = true
    }

    /// Add a snapshot to the document
    func addSnapshot(_ snapshot: DocumentSnapshot) {
        var doc = document
        doc.documentSnapshots.append(snapshot)
        document = doc

        // Force UI update by incrementing trigger
        snapshotUpdateTrigger += 1
    }

    /// Remove a snapshot from the document
    func removeSnapshot(_ snapshot: DocumentSnapshot) {
        var doc = document
        doc.documentSnapshots.removeAll { $0.id == snapshot.id }
        document = doc

        // Force UI update by incrementing trigger
        snapshotUpdateTrigger += 1
    }

    /// Get all snapshots for a specific document, sorted by date (newest first)
    func snapshotsForDocument(_ documentId: UUID) -> [DocumentSnapshot] {
        document.documentSnapshots
            .filter { $0.documentId == documentId }
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// Restore a document from a snapshot
    func restoreFromSnapshot(_ snapshot: DocumentSnapshot) {
        guard let doc = findDocument(withId: snapshot.documentId) else { return }

        updateDocument(
            doc,
            synopsis: snapshot.synopsis,
            notes: snapshot.notes,
            content: snapshot.content
        )
    }
}
