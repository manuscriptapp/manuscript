import SwiftUI
import SwiftData
import Combine

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

    // Selected text tracking
    @Published var selectedText: String = "" {
        didSet {
            // Update hasTextSelection based on whether there's text
            hasTextSelection = !selectedText.isEmpty
            print("selectedText updated: \(selectedText.count) chars, hasTextSelection: \(hasTextSelection)")
        }
    }
    @Published var hasTextSelection: Bool = false

    // Character and location selection
    @Published var selectedCharacters: [UUID] = []
    @Published var selectedLocations: [UUID] = []

    enum GenerationType {
        case outline
        case content
        case notes
    }

    init(document: ManuscriptDocument.Document, documentViewModel: DocumentViewModel) {
        self.document = document
        self.documentViewModel = documentViewModel
        self.editedTitle = document.title
        self.editedOutline = document.outline
        self.editedNotes = document.notes
        self.editedContent = document.content
        self.selectedCharacters = document.characterIds
        self.selectedLocations = document.locationIds
    }

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

        do {
            // Call your AI service here
            // For now, we'll just simulate a delay
            try await Task.sleep(nanoseconds: 2_000_000_000)

            // Simulate generated text
            let result = "This is simulated generated text based on your prompt: \(prompt)"

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
}

enum GenerationStyle {
    case formal
    case casual
    case fastPaced
    case detailed
}
