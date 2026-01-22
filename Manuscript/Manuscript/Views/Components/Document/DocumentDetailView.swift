import SwiftUI
import SwiftData

struct DocumentDetailView: View {
    @StateObject private var detailViewModel: DocumentDetailViewModel
    @State private var inspectorDetent: PresentationDetent = .medium
    @State private var isReadMode = false
    @State private var showSettings = false
    #if os(macOS)
    @AppStorage("showFormattingToolbar") private var showFormattingToolbar: Bool = true
    @StateObject private var syncService = ICloudSyncService()
    #endif

    let document: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel
    let fileURL: URL?
    @Binding var splitEditorState: SplitEditorState

    init(document: ManuscriptDocument.Document, viewModel: DocumentViewModel, fileURL: URL? = nil, splitEditorState: Binding<SplitEditorState>? = nil) {
        self.document = document
        self.viewModel = viewModel
        self.fileURL = fileURL
        self._splitEditorState = splitEditorState ?? .constant(SplitEditorState())
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
            .onChange(of: detailViewModel.editedTitle) { oldValue, newValue in
                // Only update if the value actually changed (prevents overwriting on view load)
                guard oldValue != newValue else { return }
                // Don't overwrite a non-empty title with an empty one (prevents stale state overwriting)
                if let currentDoc = viewModel.findDocument(withId: document.id) {
                    if newValue.isEmpty && !currentDoc.title.isEmpty {
                        return  // Don't overwrite existing title with empty
                    }
                    if currentDoc.title != newValue {
                        viewModel.updateDocument(document, title: newValue)
                    }
                }
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
            #if os(macOS)
            .onAppear {
                syncService.startMonitoring(url: fileURL)
            }
            .onDisappear {
                syncService.stopMonitoring()
            }
            #endif
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
        if #available(macOS 26.0, *) {
            ToolbarItem(placement: .navigation) {
                ICloudSyncStatusView(syncService: syncService)
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .navigation) {
                ICloudSyncStatusView(syncService: syncService)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            moreMenu
        }

        // Find button (macOS)
        ToolbarItem(placement: .primaryAction) {
            Button {
                detailViewModel.showFindBar = true
            } label: {
                Label("Find", systemImage: "magnifyingglass")
            }
            .help("Find (⌘F)")
        }
        #else
        ToolbarItem(placement: .secondaryAction) {
            moreMenu
        }

        // Find button (iOS)
        ToolbarItem(placement: .primaryAction) {
            Button {
                detailViewModel.showFindBar = true
            } label: {
                Label("Find", systemImage: "magnifyingglass")
            }
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
            // Split View section
            splitViewMenuSection

            Divider()

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

            #if os(macOS)
            Divider()

            Toggle(isOn: $showFormattingToolbar) {
                Label("Formatting Toolbar", systemImage: "textformat")
            }
            #endif

            #if os(iOS)
            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
            #endif
        } label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }

    @ViewBuilder
    private var splitViewMenuSection: some View {
        if splitEditorState.isEnabled {
            // Close split view option
            Button {
                splitEditorState.isEnabled = false
                splitEditorState.secondaryDocumentId = nil
            } label: {
                Label("Close Split View", systemImage: "rectangle")
            }

            #if os(macOS)
            // Orientation picker (macOS only)
            Menu {
                ForEach(SplitEditorState.SplitOrientation.allCases, id: \.self) { orientation in
                    Button {
                        splitEditorState.orientation = orientation
                    } label: {
                        HStack {
                            Label(orientation.displayName, systemImage: orientation.systemImage)
                            if splitEditorState.orientation == orientation {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Split Orientation", systemImage: splitEditorState.orientation.systemImage)
            }
            #endif

            // Change secondary document
            Menu {
                ForEach(availableDocumentsForSplit, id: \.id) { doc in
                    Button {
                        splitEditorState.secondaryDocumentId = doc.id
                    } label: {
                        HStack {
                            Text(doc.title.isEmpty ? "Untitled" : doc.title)
                            if splitEditorState.secondaryDocumentId == doc.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Change Split Document", systemImage: "doc.on.doc")
            }
        } else {
            // Open in split view
            Menu {
                ForEach(availableDocumentsForSplit, id: \.id) { doc in
                    Button {
                        openInSplitView(doc)
                    } label: {
                        Text(doc.title.isEmpty ? "Untitled" : doc.title)
                    }
                }

                if availableDocumentsForSplit.isEmpty {
                    Text("No other documents available")
                        .foregroundStyle(.secondary)
                }
            } label: {
                #if os(iOS)
                Label("Open in Split View", systemImage: "rectangle.split.1x2")
                #else
                Label("Open in Split View", systemImage: "rectangle.split.2x1")
                #endif
            }
            .disabled(availableDocumentsForSplit.isEmpty)
        }
    }

    /// Documents available for split view (excludes current document)
    private var availableDocumentsForSplit: [ManuscriptDocument.Document] {
        viewModel.getAllDocuments().filter { $0.id != document.id }
    }

    /// Opens the specified document in split view
    private func openInSplitView(_ targetDocument: ManuscriptDocument.Document) {
        splitEditorState.secondaryDocumentId = targetDocument.id
        splitEditorState.isEnabled = true
        #if os(iOS)
        // iOS always uses vertical split
        splitEditorState.orientation = .vertical
        #endif
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
    @State static var splitState = SplitEditorState()

    static var previews: some View {
        var document = ManuscriptDocument()
        document.title = "Sample Project"
        document.author = "Sample Author"
        let docItem = ManuscriptDocument.Document(id: UUID(), title: "Sample Document", notes: "Sample notes", content: "Sample content")

        return DocumentDetailView(document: docItem, viewModel: DocumentViewModel(), splitEditorState: $splitState)
    }
}
#endif
