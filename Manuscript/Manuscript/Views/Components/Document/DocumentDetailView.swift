import SwiftUI
import SwiftData

struct DocumentDetailView: View {
    @StateObject private var detailViewModel: DocumentDetailViewModel
    @State private var isInspectorPresented = false
    @State private var inspectorDetent: PresentationDetent = .medium

    let document: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel

    init(document: ManuscriptDocument.Document, viewModel: DocumentViewModel) {
        self.document = document
        self.viewModel = viewModel
        self._detailViewModel = StateObject(wrappedValue: DocumentDetailViewModel(document: document, documentViewModel: viewModel))
    }

    var body: some View {
        // Create the inspector view separately to reduce complexity
        let inspectorView = DocumentInspectorView(
            document: document,
            documentViewModel: viewModel,
            editedTitle: $detailViewModel.editedTitle,
            editedOutline: $detailViewModel.editedOutline,
            isPromptExpanded: $detailViewModel.isPromptExpanded,
            selectedCharacters: Binding(
                get: { Set(detailViewModel.selectedCharacters) },
                set: { detailViewModel.selectedCharacters = Array($0) }
            ),
            selectedLocations: Binding(
                get: { Set(detailViewModel.selectedLocations) },
                set: { detailViewModel.selectedLocations = Array($0) }
            ),
            isGenerating: $detailViewModel.isGenerating,
            generationType: $detailViewModel.generationType,
            isGenerateSheetPresented: $detailViewModel.isGenerateSheetPresented,
            generatedText: $detailViewModel.generatedText,
            generationError: $detailViewModel.generationError,
            isInspectorPresented: $isInspectorPresented,
            inspectorDetent: $inspectorDetent,
            selectedText: $detailViewModel.selectedText,
            hasTextSelection: $detailViewModel.hasTextSelection,
            generateAction: { type, prompt in
                await detailViewModel.generateText(type: type, prompt: prompt ?? "")
            },
            applyAction: {
                detailViewModel.applyGeneratedText(detailViewModel.generatedText)
            },
            applyToSelectionAction: { text in
                // Implement this method if needed
                print("Apply to selection: \(text)")
            }
        )
        .presentationDetents([.medium, .large], selection: $inspectorDetent)

        // Extract each tab into a separate variable
        let writeTabView = writeTab
            .inspector(isPresented: $isInspectorPresented) {
                inspectorView
            }
            .tabItem {
                Label("Write", systemImage: "pencil")
            }
            .tag(1)

        let readTabView = readTab
            .tabItem {
                Label("Read", systemImage: "book")
            }
            .tag(2)

        let notesTabView = notesTab
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(3)

        return TabView(selection: $detailViewModel.selectedTab) {
            writeTabView
            readTabView
            notesTabView
        }
        .onChange(of: detailViewModel.editedTitle) { _, newValue in
            viewModel.updateDocument(document, title: newValue)
        }
        .onChange(of: detailViewModel.editedOutline) { _, newValue in
            viewModel.updateDocument(document, outline: newValue)
        }
        .onChange(of: detailViewModel.editedNotes) { _, newValue in
            viewModel.updateDocument(document, notes: newValue)
        }
        .onChange(of: detailViewModel.editedContent) { _, newValue in
            viewModel.updateDocument(document, content: newValue)
        }
        .onChange(of: detailViewModel.selectedCharacters) { _, newValue in
            viewModel.updateDocument(document, characterIds: newValue)
        }
        .onChange(of: detailViewModel.selectedLocations) { _, newValue in
            viewModel.updateDocument(document, locationIds: newValue)
        }
        .navigationTitle(detailViewModel.editedTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isInspectorPresented.toggle()
                } label: {
                    Label("Inspector", systemImage: "sidebar.right")
                }
            }
        }
    }

    private var writeTab: some View {
        WriteTab(viewModel: detailViewModel)
    }

    private var readTab: some View {
        ReadTab(viewModel: detailViewModel)
    }

    private var notesTab: some View {
        NotesTab(viewModel: detailViewModel)
    }
}

#if DEBUG
struct DocumentDetailViewPreview: PreviewProvider {
    static var previews: some View {
        var document = ManuscriptDocument()
        document.title = "Sample Project"
        document.author = "Sample Author"
        let docItem = ManuscriptDocument.Document(id: UUID(), title: "Sample Document", notes: "Sample notes", content: "Sample content")

        return DocumentDetailView(document: docItem, viewModel: DocumentViewModel())
    }
}
#endif
