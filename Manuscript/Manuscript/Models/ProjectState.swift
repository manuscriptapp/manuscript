import Foundation

/// Persists the UI state of a project (selected document, expanded folders, etc.)
/// Inspired by Scrivener's ui-common.xml approach.
struct ProjectState: Codable, Equatable {
    /// The type of item currently selected in the sidebar
    enum SelectionType: String, Codable {
        case projectInfo
        case characters
        case locations
        case worldMap
        case writingHistory
        case favorites
        case keywordCollection
        case folder
        case document
        case character
        case location
        case mediaItem
    }

    /// The type of the currently selected item
    var selectionType: SelectionType?

    /// The UUID of the selected item (for folder, document, character, location)
    var selectedItemId: UUID?
    /// Selected keyword for keyword collection views
    var selectedKeyword: String?

    /// UUIDs of folders that are expanded in the sidebar
    var expandedFolderIds: [UUID]

    /// Text cursor position in the currently selected document (character offset)
    var textSelectionOffset: Int?

    /// Text selection length (0 for just a cursor position)
    var textSelectionLength: Int?

    /// Split editor state (whether split is enabled, orientation, secondary document)
    var splitEditorState: SplitEditorState = SplitEditorState()

    init() {
        self.selectionType = nil
        self.selectedItemId = nil
        self.selectedKeyword = nil
        self.expandedFolderIds = []
        self.textSelectionOffset = nil
        self.textSelectionLength = nil
        self.splitEditorState = SplitEditorState()
    }

    init(
        selectionType: SelectionType?,
        selectedItemId: UUID?,
        selectedKeyword: String? = nil,
        expandedFolderIds: [UUID],
        textSelectionOffset: Int? = nil,
        textSelectionLength: Int? = nil,
        splitEditorState: SplitEditorState = SplitEditorState()
    ) {
        self.selectionType = selectionType
        self.selectedItemId = selectedItemId
        self.selectedKeyword = selectedKeyword
        self.expandedFolderIds = expandedFolderIds
        self.textSelectionOffset = textSelectionOffset
        self.textSelectionLength = textSelectionLength
        self.splitEditorState = splitEditorState
    }

    /// Creates a ProjectState from a DetailSelection
    static func from(selection: DetailSelection?, expandedFolderIds: Set<UUID>, splitEditorState: SplitEditorState = SplitEditorState()) -> ProjectState {
        var state = ProjectState()
        state.expandedFolderIds = Array(expandedFolderIds)
        state.splitEditorState = splitEditorState

        guard let selection = selection else {
            return state
        }

        switch selection {
        case .projectInfo:
            state.selectionType = .projectInfo
        case .characters:
            state.selectionType = .characters
        case .locations:
            state.selectionType = .locations
        case .worldMap:
            state.selectionType = .worldMap
        case .writingHistory:
            state.selectionType = .writingHistory
        case .favorites:
            state.selectionType = .favorites
        case .keywordCollection(let keyword):
            state.selectionType = .keywordCollection
            state.selectedKeyword = keyword
        case .folder(let folder):
            state.selectionType = .folder
            state.selectedItemId = folder.id
        case .document(let document):
            state.selectionType = .document
            state.selectedItemId = document.id
        case .character(let character):
            state.selectionType = .character
            state.selectedItemId = character.id
        case .location(let location):
            state.selectionType = .location
            state.selectedItemId = location.id
        case .mediaItem(let mediaItem):
            state.selectionType = .mediaItem
            state.selectedItemId = mediaItem.id
        }

        return state
    }

    /// Converts the stored state back to a DetailSelection, if possible
    /// Requires the document to look up the actual objects by ID
    func toDetailSelection(in document: ManuscriptDocument) -> DetailSelection? {
        guard let selectionType = selectionType else {
            return nil
        }

        switch selectionType {
        case .projectInfo:
            return .projectInfo
        case .characters:
            return .characters
        case .locations:
            return .locations
        case .worldMap:
            return .worldMap
        case .writingHistory:
            return .writingHistory
        case .favorites:
            return .favorites
        case .keywordCollection:
            guard let keyword = selectedKeyword else { return nil }
            return .keywordCollection(keyword)
        case .folder:
            guard let id = selectedItemId,
                  let folder = findFolder(withId: id, in: document.rootFolder) else {
                return nil
            }
            return .folder(folder)
        case .document:
            guard let id = selectedItemId,
                  let doc = findDocument(withId: id, in: document.rootFolder) else {
                return nil
            }
            return .document(doc)
        case .character:
            guard let id = selectedItemId,
                  let character = document.characters.first(where: { $0.id == id }) else {
                return nil
            }
            return .character(character)
        case .location:
            guard let id = selectedItemId,
                  let location = document.locations.first(where: { $0.id == id }) else {
                return nil
            }
            return .location(location)
        case .mediaItem:
            guard let id = selectedItemId,
                  let mediaItem = findMediaItem(withId: id, in: document.rootFolder) else {
                return nil
            }
            return .mediaItem(mediaItem)
        }
    }

    // MARK: - Private Helpers

    private func findFolder(withId id: UUID, in folder: ManuscriptFolder) -> ManuscriptFolder? {
        if folder.id == id { return folder }
        for subfolder in folder.subfolders {
            if let found = findFolder(withId: id, in: subfolder) {
                return found
            }
        }
        return nil
    }

    private func findDocument(withId id: UUID, in folder: ManuscriptFolder) -> ManuscriptDocument.Document? {
        if let doc = folder.documents.first(where: { $0.id == id }) {
            return doc
        }
        for subfolder in folder.subfolders {
            if let doc = findDocument(withId: id, in: subfolder) {
                return doc
            }
        }
        return nil
    }

    private func findMediaItem(withId id: UUID, in folder: ManuscriptFolder) -> ManuscriptDocument.MediaItem? {
        if let item = folder.mediaItems.first(where: { $0.id == id }) {
            return item
        }
        for subfolder in folder.subfolders {
            if let item = findMediaItem(withId: id, in: subfolder) {
                return item
            }
        }
        return nil
    }
}
