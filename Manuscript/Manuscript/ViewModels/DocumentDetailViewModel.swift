import SwiftUI
import SwiftData
import Combine
#if os(iOS)
import UIKit
#else
import AppKit
#endif

@MainActor
class DocumentDetailViewModel: ObservableObject {
    let document: ManuscriptDocument.Document
    let documentViewModel: DocumentViewModel
    @Published var editedTitle: String
    @Published var editedOutline: String
    @Published var editedNotes: String
    @Published var editedContent: String
    @Published var isGenerating: Bool = false
    @Published var selectedTab: Int = 0  // 0 = Plan, 1 = Write, 2 = Read, 3 = Notes
    @Published var isPromptExpanded: Bool = true
    @Published var isOutlineExpanded: Bool = true
    @Published var isCharactersExpanded: Bool = false
    @Published var isLocationsExpanded: Bool = false
    @Published var generationError: Error?
    @Published var generatedText: String = ""
    @Published var generationType: GenerationType = .outline
    @Published var isGenerateSheetPresented: Bool = false

    // Rich text content (NSAttributedString for RichTextKit)
    @Published var attributedContent: NSAttributedString {
        didSet {
            // Convert attributed string back to markdown for persistence
            editedContent = MarkdownParser.markdown(from: attributedContent)
        }
    }
    @Published var attributedNotes: NSAttributedString {
        didSet {
            // Convert attributed string back to markdown for persistence
            editedNotes = MarkdownParser.markdown(from: attributedNotes)
        }
    }

    // Selected text tracking
    @Published var selectedText: String = "" {
        didSet {
            // Update hasTextSelection based on whether there's text
            hasTextSelection = !selectedText.isEmpty
            print("selectedText updated: \(selectedText.count) chars, hasTextSelection: \(hasTextSelection)")
        }
    }
    @Published var hasTextSelection: Bool = false
    @Published var selectedTextRange: NSRange? = nil  // Track the range for comments

    // Comments
    @Published var comments: [ManuscriptDocument.DocumentComment] = []

    // Inspector state (controlled from ViewModel so WriteTab can trigger it)
    @Published var isInspectorPresented: Bool = false
    @Published var inspectorSelectedTab: Int = 0  // 0 = Chat, 1 = Comments, 2 = Details
    @Published var tappedComment: ManuscriptDocument.DocumentComment? = nil

    // Character and location selection
    @Published var selectedCharacters: [UUID] = []
    @Published var selectedLocations: [UUID] = []

    enum GenerationType {
        case outline
        case content
        case notes
    }

    /// Zero-width space used as placeholder for empty documents to preserve font attributes
    /// This ensures RichTextKit reads the correct font when the document appears empty
    static let emptyDocumentPlaceholder = "\u{200B}"

    init(document: ManuscriptDocument.Document, documentViewModel: DocumentViewModel) {
        self.document = document
        self.documentViewModel = documentViewModel
        self.editedTitle = document.title
        self.editedOutline = document.outline
        self.editedNotes = document.notes
        self.editedContent = document.content
        self.selectedCharacters = document.characterIds
        self.selectedLocations = document.locationIds
        self.comments = document.comments

        // Initialize attributed strings by parsing markdown content
        // This converts markdown formatting (bold, italic, etc.) to NSAttributedString
        let contentFont = Self.defaultContentFont
        let notesFont = Self.defaultNotesFont

        // For empty content, use a zero-width space placeholder with correct font attributes
        // This ensures RichTextKit reads the correct font instead of falling back to system font
        let contentToProcess = document.content.isEmpty ? Self.emptyDocumentPlaceholder : document.content

        let baseContent = MarkdownParser.attributedString(
            from: contentToProcess,
            baseFont: contentFont,
            textColor: Self.defaultTextColor
        )

        // Apply comment highlights to the content (brown background with dark border)
        let commentRanges = document.comments.compactMap { comment -> NSRange? in
            guard let range = comment.range else { return nil }
            return NSRange(location: range.location, length: range.length)
        }

        self.attributedContent = MarkdownParser.applyCommentHighlights(
            to: baseContent,
            comments: commentRanges
        )

        // For empty notes, also use the placeholder
        let notesToProcess = document.notes.isEmpty ? Self.emptyDocumentPlaceholder : document.notes

        self.attributedNotes = MarkdownParser.attributedString(
            from: notesToProcess,
            baseFont: notesFont,
            textColor: Self.defaultTextColor
        )
    }

    // MARK: - Default Fonts

    #if os(iOS)
    private static var defaultContentFont: UIFont {
        UIFont(name: "Palatino", size: 16) ?? UIFont.systemFont(ofSize: 16)
    }
    private static var defaultNotesFont: UIFont {
        UIFont.systemFont(ofSize: 14)
    }
    private static var defaultTextColor: UIColor {
        UIColor.label
    }
    #else
    private static var defaultContentFont: NSFont {
        NSFont(name: "Palatino", size: 16) ?? NSFont.systemFont(ofSize: 16)
    }
    private static var defaultNotesFont: NSFont {
        NSFont.systemFont(ofSize: 14)
    }
    private static var defaultTextColor: NSColor {
        NSColor.textColor
    }
    #endif

    var characters: [ManuscriptCharacter] {
        return documentViewModel.document.characters.filter { selectedCharacters.contains($0.id) }
    }

    var locations: [ManuscriptLocation] {
        return documentViewModel.document.locations.filter { selectedLocations.contains($0.id) }
    }

    var availableCharacters: [ManuscriptCharacter] {
        return documentViewModel.document.characters
    }

    var availableLocations: [ManuscriptLocation] {
        return documentViewModel.document.locations
    }

    func saveChanges() {
        documentViewModel.updateDocument(
            document,
            title: editedTitle,
            outline: editedOutline,
            notes: editedNotes,
            content: editedContent,
            characterIds: selectedCharacters,
            locationIds: selectedLocations
        )
    }

    func toggleCharacter(_ character: ManuscriptCharacter) {
        if selectedCharacters.contains(character.id) {
            selectedCharacters.removeAll { $0 == character.id }
        } else {
            selectedCharacters.append(character.id)
        }
        saveChanges()
    }

    func toggleLocation(_ location: ManuscriptLocation) {
        if selectedLocations.contains(location.id) {
            selectedLocations.removeAll { $0 == location.id }
        } else {
            selectedLocations.append(location.id)
        }
        saveChanges()
    }

    // MARK: - Text Generation

    func generateText(type: GenerationType, prompt: String) async -> String {
        isGenerating = true
        generationType = type
        generationError = nil

        do {
            let result = try await TextGenerationService.shared.generateText(prompt: prompt)

            await MainActor.run {
                generatedText = result
                isGenerating = false
            }

            return result
        } catch {
            await MainActor.run {
                generationError = error
                isGenerating = false
            }
            return ""
        }
    }

    func applyGeneratedText(_ text: String) {
        switch generationType {
        case .content:
            if !selectedText.isEmpty {
                // Replace selected text
                let currentContent = editedContent
                if let range = currentContent.range(of: selectedText) {
                    editedContent = currentContent.replacingCharacters(in: range, with: text)
                } else {
                    // If we can't find the exact selection, append
                    editedContent += "\n\n" + text
                }
            } else {
                // Append to content
                editedContent += "\n\n" + text
            }
        case .outline:
            editedOutline += "\n\n" + text
        case .notes:
            editedNotes += "\n\n" + text
        }

        saveChanges()
        generatedText = ""
    }

    // MARK: - Comment Management

    /// Add a new comment, optionally linked to the currently selected text range
    func addComment(text: String, color: String = "#FFFF00") {
        var range: ManuscriptDocument.DocumentComment.Range? = nil

        // If text is selected, capture the range
        if let selectedRange = selectedTextRange, !selectedText.isEmpty {
            range = ManuscriptDocument.DocumentComment.Range(
                location: selectedRange.location,
                length: selectedRange.length
            )
        }

        let comment = ManuscriptDocument.DocumentComment(
            id: UUID(),
            text: text,
            color: color,
            range: range,
            creationDate: Date()
        )

        comments.append(comment)
        saveComments()
    }

    /// Update an existing comment
    func updateComment(_ comment: ManuscriptDocument.DocumentComment, text: String, color: String? = nil) {
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }

        var updatedComment = comments[index]
        updatedComment.text = text
        if let color = color {
            updatedComment.color = color
        }
        comments[index] = updatedComment
        saveComments()
    }

    /// Delete a comment
    func deleteComment(_ comment: ManuscriptDocument.DocumentComment) {
        comments.removeAll { $0.id == comment.id }
        saveComments()
    }

    /// Get the text that a comment refers to
    func getCommentedText(for comment: ManuscriptDocument.DocumentComment) -> String? {
        guard let range = comment.range else { return nil }

        let content = editedContent
        guard range.location >= 0,
              range.location + range.length <= content.count else {
            return nil
        }

        let startIndex = content.index(content.startIndex, offsetBy: range.location)
        let endIndex = content.index(startIndex, offsetBy: range.length)
        return String(content[startIndex..<endIndex])
    }

    /// Check if a character position is within a comment range and open inspector if so
    /// - Parameter characterIndex: The character index that was tapped
    /// - Returns: True if a comment was found and inspector opened
    @discardableResult
    func handleTapAtCharacterIndex(_ characterIndex: Int) -> Bool {
        // Find comment that contains this character index
        for comment in comments {
            guard let range = comment.range else { continue }
            let nsRange = NSRange(location: range.location, length: range.length)
            if characterIndex >= nsRange.location && characterIndex < nsRange.location + nsRange.length {
                // Found a comment at this position - open inspector with comments tab
                tappedComment = comment
                inspectorSelectedTab = 1  // Comments tab
                isInspectorPresented = true
                return true
            }
        }
        return false
    }

    /// Save comments to the document
    private func saveComments() {
        documentViewModel.updateDocument(document, comments: comments)
    }
}

enum GenerationStyle {
    case formal
    case casual
    case fastPaced
    case detailed
}
