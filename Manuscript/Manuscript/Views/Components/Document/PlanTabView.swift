import SwiftUI
import SwiftData

struct PlanTabView: View {
    let document: Document
    let book: Book
    @Binding var editedTitle: String
    @Binding var editedOutline: String
    @Binding var isPromptExpanded: Bool
    @Binding var isOutlineExpanded: Bool
    @Binding var isCharactersExpanded: Bool
    @Binding var isLocationsExpanded: Bool
    @Binding var selectedCharacters: Set<UUID>
    @Binding var selectedLocations: Set<UUID>
    @Binding var isGenerating: Bool
    @Binding var generationType: DocumentDetailViewModel.GenerationType
    @Binding var isGenerateSheetPresented: Bool
    @Binding var generatedText: String
    @Binding var generationError: Error?
    let generateAction: (DocumentDetailViewModel.GenerationType, GenerationStyle, String?) async -> Void
    let applyAction: () -> Void
    
    var body: some View {
        PlatformFormView {
            if !document.outlinePrompt.isEmpty {
                Section {
                    DisclosureGroup(
                        isExpanded: $isPromptExpanded,
                        content: {
                            Text(document.outlinePrompt)
                                .font(.subheadline)
                        },
                        label: {
                            HStack {
                                Image(systemName: "list.clipboard")
                                    .foregroundStyle(.accent)
                                Text("Chapter Guidelines")
                            }
                        }
                    )
                }
            }
            
            Section {
                TextEditor(text: $editedOutline)
                    .plainTextEditor()
                    .frame(minHeight: 150)
            } header: {
                Text("Outline")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            GenerateButtonView(
                title: editedOutline.isEmpty ? "Write Outline" : "Rewrite Outline",
                systemImage: "list.bullet",
                isGenerating: isGenerating && generationType == .outline,
                isDisabled: false,
                isGenerateSheetPresented: $isGenerateSheetPresented,
                generatedText: $generatedText,
                generationError: $generationError,
                generationType: $generationType
            )
        }
        .sheet(isPresented: $isGenerateSheetPresented) {
            GenerateOptionsSheet(
                title: editedOutline.isEmpty ? "Write Outline" : "Rewrite Outline",
                isGenerating: isGenerating,
                generationType: generationType,
                selectedCharacters: book.characters?.filter { selectedCharacters.contains($0.id) } ?? [],
                selectedLocations: book.locations?.filter { selectedLocations.contains($0.id) } ?? [],
                isPresented: $isGenerateSheetPresented,
                generatedText: $generatedText,
                generationError: $generationError,
                generateAction: { style, prompt in
                    await generateAction(.outline, style, prompt)
                },
                applyAction: applyAction
            )
        }
    }
}

#if DEBUG
#Preview {
    let book = Book(title: "Test Book")
    let document = Document(title: "Test Document")
    
    PlanTabView(
        document: document,
        book: book,
        editedTitle: .constant("Test Title"),
        editedOutline: .constant("Test Outline"),
        isPromptExpanded: .constant(true),
        isOutlineExpanded: .constant(true),
        isCharactersExpanded: .constant(false),
        isLocationsExpanded: .constant(false),
        selectedCharacters: .constant([]),
        selectedLocations: .constant([]),
        isGenerating: .constant(false),
        generationType: .constant(.outline),
        isGenerateSheetPresented: .constant(false),
        generatedText: .constant(""),
        generationError: .constant(nil),
        generateAction: { _, _, _ in },
        applyAction: {}
    )
}
#endif
