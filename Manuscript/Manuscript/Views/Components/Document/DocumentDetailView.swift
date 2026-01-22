import SwiftUI
import SwiftData

struct DocumentDetailView: View {
    @StateObject private var detailViewModel: DocumentDetailViewModel
    @State private var inspectorDetent: PresentationDetent = .medium
    @State private var isReadMode = false
    @State private var showSettings = false

    let document: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel

    init(document: ManuscriptDocument.Document, viewModel: DocumentViewModel) {
        self.document = document
        self.viewModel = viewModel
        self._detailViewModel = StateObject(wrappedValue: DocumentDetailViewModel(document: document, documentViewModel: viewModel))
    }

    var body: some View {
        mainContent
            .inspector(isPresented: $detailViewModel.isInspectorPresented) {
                inspectorView
            }
            #if os(macOS)
            .inspectorColumnWidth(min: 280, ideal: 320, max: 450)
            #endif
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
                toolbarContent
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showSettings = false
                                }
                            }
                        }
                }
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if isReadMode {
            readModeView
        } else {
            WriteTab(viewModel: detailViewModel)
        }
    }

    private var inspectorView: some View {
        DocumentInspectorView(
            document: document,
            documentViewModel: viewModel,
            detailViewModel: detailViewModel,
            editedTitle: $detailViewModel.editedTitle,
            editedOutline: $detailViewModel.editedOutline,
            isPromptExpanded: $detailViewModel.isPromptExpanded,
            selectedCharacters: selectedCharactersBinding,
            selectedLocations: selectedLocationsBinding,
            isGenerating: $detailViewModel.isGenerating,
            generationType: $detailViewModel.generationType,
            isGenerateSheetPresented: $detailViewModel.isGenerateSheetPresented,
            generatedText: $detailViewModel.generatedText,
            generationError: $detailViewModel.generationError,
            isInspectorPresented: $detailViewModel.isInspectorPresented,
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
                print("Apply to selection: \(text)")
            }
        )
        #if os(iOS)
        .presentationDetents([.medium, .large], selection: $inspectorDetent)
        #else
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
        #endif
    }

    private var selectedCharactersBinding: Binding<Set<UUID>> {
        Binding(
            get: { Set(detailViewModel.selectedCharacters) },
            set: { detailViewModel.selectedCharacters = Array($0) }
        )
    }

    private var selectedLocationsBinding: Binding<Set<UUID>> {
        Binding(
            get: { Set(detailViewModel.selectedLocations) },
            set: { detailViewModel.selectedLocations = Array($0) }
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(macOS)
        ToolbarItem(placement: .primaryAction) {
            moreMenu
        }
        #else
        ToolbarItem(placement: .secondaryAction) {
            moreMenu
        }
        #endif

        ToolbarItem(placement: .primaryAction) {
            Button {
                isReadMode.toggle()
            } label: {
                Label(isReadMode ? "Edit" : "Read", systemImage: isReadMode ? "pencil" : "book")
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                detailViewModel.isInspectorPresented.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.right")
            }
        }
    }

    private var moreMenu: some View {
        Menu {
            Button {
                // TODO: Implement share functionality
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Button {
                // TODO: Implement export functionality
            } label: {
                Label("Export", systemImage: "arrow.up.doc")
            }

            Divider()

            Button {
                // TODO: Implement print functionality
            } label: {
                Label("Print", systemImage: "printer")
            }

            Button {
                // TODO: Implement duplicate functionality
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }

            Divider()

            Button {
                detailViewModel.isInspectorPresented = true
            } label: {
                Label("Document Info", systemImage: "info.circle")
            }

            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
        } label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }

    private var readModeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(detailViewModel.editedTitle)
                    .font(.system(size: 28, weight: .light, design: .serif))

                Divider()
                    .padding(.trailing, 60)

                Text(detailViewModel.editedContent)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .lineSpacing(8)
                    .kerning(0.3)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
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
