import SwiftUI
import SwiftData

struct DocumentDetailView: View {
    @StateObject private var viewModel: DocumentDetailViewModel
    @State private var isInspectorPresented = false
    @State private var inspectorDetent: PresentationDetent = .medium
    
    let document: LiteratiDocument.Document
    let literatiViewModel: LiteratiViewModel
    
    init(document: LiteratiDocument.Document, literatiViewModel: LiteratiViewModel) {
        self.document = document
        self.literatiViewModel = literatiViewModel
        self._viewModel = StateObject(wrappedValue: DocumentDetailViewModel(document: document, literatiViewModel: literatiViewModel))
    }
    
    var body: some View {
        // Create the inspector view separately to reduce complexity
        let inspectorView = DocumentInspectorView(
            document: document,
            literatiViewModel: literatiViewModel,
            editedTitle: $viewModel.editedTitle,
            editedOutline: $viewModel.editedOutline,
            isPromptExpanded: $viewModel.isPromptExpanded,
            selectedCharacters: Binding(
                get: { Set(viewModel.selectedCharacters) },
                set: { viewModel.selectedCharacters = Array($0) }
            ),
            selectedLocations: Binding(
                get: { Set(viewModel.selectedLocations) },
                set: { viewModel.selectedLocations = Array($0) }
            ),
            isGenerating: $viewModel.isGenerating,
            generationType: $viewModel.generationType,
            isGenerateSheetPresented: $viewModel.isGenerateSheetPresented,
            generatedText: $viewModel.generatedText,
            generationError: $viewModel.generationError,
            isInspectorPresented: $isInspectorPresented,
            inspectorDetent: $inspectorDetent,
            selectedText: $viewModel.selectedText,
            hasTextSelection: $viewModel.hasTextSelection,
            generateAction: { type, prompt in
                await viewModel.generateText(type: type, prompt: prompt ?? "")
            },
            applyAction: {
                viewModel.applyGeneratedText(viewModel.generatedText)
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
        
        return TabView(selection: $viewModel.selectedTab) {
            writeTabView
            readTabView
            notesTabView
        }
        .onChange(of: viewModel.editedTitle) { _, newValue in
            literatiViewModel.updateDocument(document, title: newValue)
        }
        .onChange(of: viewModel.editedOutline) { _, newValue in
            literatiViewModel.updateDocument(document, outline: newValue)
        }
        .onChange(of: viewModel.editedNotes) { _, newValue in
            literatiViewModel.updateDocument(document, notes: newValue)
        }
        .onChange(of: viewModel.editedContent) { _, newValue in
            literatiViewModel.updateDocument(document, content: newValue)
        }
        .onChange(of: viewModel.selectedCharacters) { _, newValue in
            literatiViewModel.updateDocument(document, characterIds: newValue)
        }
        .onChange(of: viewModel.selectedLocations) { _, newValue in
            literatiViewModel.updateDocument(document, locationIds: newValue)
        }
        .navigationTitle(viewModel.editedTitle)
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
        WriteTab(viewModel: viewModel)
    }
    
    private var readTab: some View {
        ReadTab(viewModel: viewModel)
    }
    
    private var notesTab: some View {
        NotesTab(viewModel: viewModel)
    }
}

#if DEBUG
struct DocumentDetailViewPreview: PreviewProvider {
    static var previews: some View {
        let document = LiteratiDocument()
        document.title = "Sample Project"
        document.author = "Sample Author"
        let docItem = LiteratiDocument.Document(id: UUID(), title: "Sample Document", notes: "Sample notes", content: "Sample content")
        
        return DocumentDetailView(document: docItem, literatiViewModel: LiteratiViewModel(document: document))
    }
}
#endif 
