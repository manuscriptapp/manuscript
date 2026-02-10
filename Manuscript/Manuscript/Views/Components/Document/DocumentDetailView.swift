import SwiftUI
import SwiftData
import RichTextKit

struct DocumentDetailView: View {
    /// Local view model (used when no external is provided)
    @StateObject private var localDetailViewModel: DocumentDetailViewModel
    /// External view model (for split view where container owns view models)
    var externalDetailViewModel: DocumentDetailViewModel?

    @State private var inspectorDetent: PresentationDetent = .medium
    @State private var isReadMode = false
    @State private var showSettings = false
    @State private var isCompositionModeActive = false
    @State private var audioPlayback = AudioPlaybackManager.shared
    @State private var elevenLabsSettings = ElevenLabsSettingsManager.shared
    @State private var showAudioPlayer = false
    @State private var showExportSheet = false
    @EnvironmentObject private var backupManager: BackupManager
    #if os(macOS)
    @AppStorage("showFormattingToolbar") private var showFormattingToolbar: Bool = true
    @StateObject private var syncService = ICloudSyncService()
    #endif

    let document: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel
    let fileURL: URL?
    @Binding var splitEditorState: SplitEditorState

    /// External RichTextContext for split view unified toolbar
    var externalRichTextContext: RichTextContext?
    /// Callback when this editor gains focus (for split view)
    var onFocusChange: ((Bool) -> Void)?
    /// Whether to hide the formatting toolbar (when using external context in split view)
    var hideToolbar: Bool = false
    /// Whether to hide toolbar items (inspector, find, read mode) - used in split view
    var hideToolbarItems: Bool = false
    /// Whether this view is the active pane in split view (nil = not in split mode, true = active, false = inactive)
    var isActiveInSplitView: Bool?
    /// External binding for inspector state (for split view unified control)
    var externalInspectorPresented: Binding<Bool>?
    /// External binding for find bar state (for split view unified control)
    var externalShowFindBar: Binding<Bool>?
    /// External binding for read mode state (for split view unified control)
    var externalIsReadMode: Binding<Bool>?

    /// Returns the active detail view model (external if provided, otherwise local)
    private var detailViewModel: DocumentDetailViewModel {
        externalDetailViewModel ?? localDetailViewModel
    }

    init(document: ManuscriptDocument.Document, viewModel: DocumentViewModel, fileURL: URL? = nil, splitEditorState: Binding<SplitEditorState>? = nil, externalRichTextContext: RichTextContext? = nil, onFocusChange: ((Bool) -> Void)? = nil, hideToolbar: Bool = false, hideToolbarItems: Bool = false, isActiveInSplitView: Bool? = nil, externalDetailViewModel: DocumentDetailViewModel? = nil, externalInspectorPresented: Binding<Bool>? = nil, externalShowFindBar: Binding<Bool>? = nil, externalIsReadMode: Binding<Bool>? = nil) {
        self.document = document
        self.viewModel = viewModel
        self.fileURL = fileURL
        self._splitEditorState = splitEditorState ?? .constant(SplitEditorState())
        self.externalRichTextContext = externalRichTextContext
        self.onFocusChange = onFocusChange
        self.hideToolbar = hideToolbar
        self.hideToolbarItems = hideToolbarItems
        self.isActiveInSplitView = isActiveInSplitView
        self.externalDetailViewModel = externalDetailViewModel
        self.externalInspectorPresented = externalInspectorPresented
        self.externalShowFindBar = externalShowFindBar
        self.externalIsReadMode = externalIsReadMode
        self._localDetailViewModel = StateObject(wrappedValue: DocumentDetailViewModel(document: document, documentViewModel: viewModel))
    }

    /// Computed binding for inspector - uses external if provided, else internal
    private var inspectorPresentedBinding: Binding<Bool> {
        externalInspectorPresented ?? Binding(
            get: { detailViewModel.isInspectorPresented },
            set: { detailViewModel.isInspectorPresented = $0 }
        )
    }

    /// Computed binding for read mode - uses external if provided, else internal
    private var readModeBinding: Binding<Bool> {
        externalIsReadMode ?? $isReadMode
    }

    /// Whether to show the inspector on this view
    /// Show inspector only when NOT in split mode (container handles inspector in split mode)
    private var shouldShowInspector: Bool {
        isActiveInSplitView == nil
    }


    var body: some View {
        contentWithInspector
            .modifier(DocumentChangeObservers(
                detailViewModel: detailViewModel,
                viewModel: viewModel,
                document: document
            ))
            .navigationTitle(detailViewModel.editedTitle)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showSettings) { settingsSheet }
            .sheet(isPresented: $showExportSheet) {
                CompileSheet(document: viewModel.document)
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $isCompositionModeActive) {
                CompositionModeView(viewModel: detailViewModel, isPresented: $isCompositionModeActive)
            }
            #endif
            #if os(macOS)
            .onAppear { syncService.startMonitoring(url: fileURL) }
            .onDisappear { syncService.stopMonitoring() }
            .focusedValue(\.compositionModeBinding, $isCompositionModeActive)
            .onChange(of: isCompositionModeActive) { _, isActive in
                if isActive {
                    CompositionModeWindowController.shared.show(viewModel: detailViewModel) {
                        isCompositionModeActive = false
                    }
                }
            }
            #endif
    }

    @ViewBuilder
    private var contentWithInspector: some View {
        if shouldShowInspector {
            mainContent
                .inspector(isPresented: inspectorPresentedBinding) {
                    inspectorView
                }
                #if os(macOS)
                .inspectorColumnWidth(min: 280, ideal: 320, max: 450)
                #endif
        } else {
            mainContent
        }
    }

    private var settingsSheet: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(backupManager)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showSettings = false }
                    }
                }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !hideToolbarItems {
            toolbarItems
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if readModeBinding.wrappedValue {
            readModeView
        } else {
            WriteTab(
                viewModel: detailViewModel,
                externalRichTextContext: externalRichTextContext,
                onFocusChange: onFocusChange,
                hideToolbar: hideToolbar,
                externalShowFindBar: externalShowFindBar
            )
        }
    }

    private var inspectorView: some View {
        let vm = detailViewModel
        return DocumentInspectorView(
            document: document,
            documentViewModel: viewModel,
            detailViewModel: vm,
            editedTitle: Binding(get: { vm.editedTitle }, set: { vm.editedTitle = $0 }),
            editedSynopsis: Binding(get: { vm.editedSynopsis }, set: { vm.editedSynopsis = $0 }),
            editedKeywords: Binding(get: { vm.editedKeywords }, set: { vm.editedKeywords = $0 }),
            linkedDocumentIds: Binding(get: { vm.linkedDocumentIds }, set: { vm.linkedDocumentIds = $0 }),
            isFavorite: Binding(get: { vm.isFavorite }, set: { vm.isFavorite = $0 }),
            isPromptExpanded: Binding(get: { vm.isPromptExpanded }, set: { vm.isPromptExpanded = $0 }),
            selectedCharacters: selectedCharactersBinding,
            selectedLocations: selectedLocationsBinding,
            isGenerating: Binding(get: { vm.isGenerating }, set: { vm.isGenerating = $0 }),
            generationType: Binding(get: { vm.generationType }, set: { vm.generationType = $0 }),
            isGenerateSheetPresented: Binding(get: { vm.isGenerateSheetPresented }, set: { vm.isGenerateSheetPresented = $0 }),
            generatedText: Binding(get: { vm.generatedText }, set: { vm.generatedText = $0 }),
            generationError: Binding(get: { vm.generationError }, set: { vm.generationError = $0 }),
            isInspectorPresented: Binding(get: { vm.isInspectorPresented }, set: { vm.isInspectorPresented = $0 }),
            inspectorDetent: $inspectorDetent,
            selectedText: Binding(get: { vm.selectedText }, set: { vm.selectedText = $0 }),
            hasTextSelection: Binding(get: { vm.hasTextSelection }, set: { vm.hasTextSelection = $0 }),
            generateAction: { type, prompt in
                await vm.generateText(type: type, prompt: prompt ?? "")
            },
            applyAction: {
                vm.applyGeneratedText(vm.generatedText)
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
    private var toolbarItems: some ToolbarContent {
        #if os(macOS)
        // iCloud sync status (left side)
        if #available(macOS 26.0, *) {
            ToolbarItem(placement: .navigation) {
                ICloudSyncStatusView(syncService: syncService)
                    .scaleEffect(0.85)
            }
            .sharedBackgroundVisibility(.hidden)
        }

        // Center: View modes (Composition, Read)
        ToolbarItemGroup(placement: .principal) {
            Button {
                withAnimation(.spring(duration: 0.4)) {
                    isCompositionModeActive = true
                }
            } label: {
                Label("Composition Mode", systemImage: "rectangle.expand.vertical")
            }
            .help("Enter Composition Mode")

            Button {
                isReadMode.toggle()
            } label: {
                Label(isReadMode ? "Edit" : "Read", systemImage: isReadMode ? "pencil" : "book")
            }
            .help(isReadMode ? "Switch to Edit Mode" : "Switch to Read Mode")

            // Read Aloud button
            readAloudButton
        }

        // Right: Export
        ToolbarItem(placement: .primaryAction) {
            Button {
                showExportSheet = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .help("Export Document")
        }

        // Right: Split View
        ToolbarItem(placement: .primaryAction) {
            splitViewToolbarMenu
        }

        // Right: Inspector toggle (rightmost)
        ToolbarItem(placement: .primaryAction) {
            Button {
                detailViewModel.isInspectorPresented.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.right")
            }
            .help("Toggle Inspector")
        }
        #else
        // iOS: Inspector as primary action
        ToolbarItem(placement: .primaryAction) {
            Button {
                detailViewModel.isInspectorPresented.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.right")
            }
        }

        // iOS: Other actions as secondary
        ToolbarItemGroup(placement: .secondaryAction) {
            Button {
                detailViewModel.showFindBar = true
            } label: {
                Label("Find", systemImage: "magnifyingglass")
            }

            splitViewToolbarMenu

            Button {
                withAnimation(.spring(duration: 0.4)) {
                    isCompositionModeActive = true
                }
            } label: {
                Label("Composition Mode", systemImage: "rectangle.expand.vertical")
            }

            Button {
                isReadMode.toggle()
            } label: {
                Label(isReadMode ? "Edit" : "Read", systemImage: isReadMode ? "pencil" : "book")
            }

            // Read Aloud button
            readAloudButton

            // Export button
            Button {
                showExportSheet = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        }
        #endif
    }

    // MARK: - Read Aloud Button

    /// Text to be read aloud - uses selection if available, otherwise full content
    private var textToRead: String {
        if detailViewModel.hasTextSelection && !detailViewModel.selectedText.isEmpty {
            return detailViewModel.selectedText
        }
        return detailViewModel.editedContent
    }

    /// Whether reading selected text vs full document
    private var isReadingSelection: Bool {
        detailViewModel.hasTextSelection && !detailViewModel.selectedText.isEmpty
    }

    @ViewBuilder
    private var readAloudButton: some View {
        Button {
            showAudioPlayer.toggle()
        } label: {
            if audioPlayback.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if audioPlayback.isPlaying || audioPlayback.isPaused {
                Label("Audio Player", systemImage: "mic.fill")
            } else {
                Label("Read Aloud", systemImage: "mic")
            }
        }
        .help(readAloudHelpText)
        .disabled(detailViewModel.editedContent.isEmpty)
        .popover(isPresented: $showAudioPlayer) {
            AudioPlayerPopover(
                isPresented: $showAudioPlayer,
                text: textToRead,
                isSelection: isReadingSelection
            )
        }
    }

    private var readAloudHelpText: String {
        if !elevenLabsSettings.isConfigured {
            return "Configure ElevenLabs in Settings to enable Read Aloud"
        } else if audioPlayback.isPlaying {
            return "Audio Player"
        } else if isReadingSelection {
            return "Read Selection Aloud"
        } else {
            return "Read Aloud"
        }
    }

    @ViewBuilder
    private var splitViewToolbarMenu: some View {
        Menu {
            #if os(macOS)
            // Horizontal split option
            Button {
                splitEditorState.orientation = .horizontal
                splitEditorState.isEnabled = true
            } label: {
                HStack {
                    Label("Split Horizontal", systemImage: "rectangle.split.2x1")
                    if splitEditorState.isEnabled && splitEditorState.orientation == .horizontal {
                        Image(systemName: "checkmark")
                    }
                }
            }

            // Vertical split option
            Button {
                splitEditorState.orientation = .vertical
                splitEditorState.isEnabled = true
            } label: {
                HStack {
                    Label("Split Vertical", systemImage: "rectangle.split.1x2")
                    if splitEditorState.isEnabled && splitEditorState.orientation == .vertical {
                        Image(systemName: "checkmark")
                    }
                }
            }
            #else
            // iOS: Only vertical split
            Button {
                splitEditorState.orientation = .vertical
                splitEditorState.isEnabled = true
            } label: {
                HStack {
                    Label("Split View", systemImage: "rectangle.split.1x2")
                    if splitEditorState.isEnabled {
                        Image(systemName: "checkmark")
                    }
                }
            }
            #endif

            // Close split view (only when active)
            if splitEditorState.isEnabled {
                Divider()

                Button {
                    splitEditorState.isEnabled = false
                    splitEditorState.secondaryDocumentId = nil
                } label: {
                    Label("Close Split View", systemImage: "rectangle")
                }
            }
        } label: {
            #if os(iOS)
            Label("Split View", systemImage: splitEditorState.isEnabled ? "rectangle.split.1x2.fill" : "rectangle.split.1x2")
            #else
            Label("Split View", systemImage: splitEditorState.isEnabled ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
            #endif
        }
    }



    // Maximum width for comfortable prose reading (similar to A4 page)
    private let maxProseWidth: CGFloat = 700

    private var readModeView: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let horizontalPadding = max(32, (availableWidth - maxProseWidth) / 2)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text(detailViewModel.editedTitle)
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundStyle(.primary)

                    // Subtle divider
                    Rectangle()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 120, height: 1)
                        .padding(.vertical, 8)

                    // Content with paragraph indentation
                    readModeContent
                }
                .frame(maxWidth: maxProseWidth, alignment: .leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 48)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            #if os(macOS)
            .background(Color(nsColor: .textBackgroundColor))
            #else
            .background(Color(uiColor: .systemBackground))
            #endif
        }
    }

    /// Formats the content with proper paragraph indentation for reading mode
    private var readModeContent: some View {
        // Split by newlines (single or double) and filter empty lines
        let paragraphs = detailViewModel.editedContent
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        return VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                let trimmedParagraph = paragraph.trimmingCharacters(in: .whitespaces)

                Text("\u{2003}\u{2003}" + trimmedParagraph)  // Em-space for consistent indent
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .lineSpacing(8)
                    .kerning(0.3)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

}

// MARK: - Document Change Observers ViewModifier

/// ViewModifier to handle document property change observations
/// Extracted to reduce type-checker complexity in the main body
private struct DocumentChangeObservers: ViewModifier {
    @ObservedObject var detailViewModel: DocumentDetailViewModel
    @ObservedObject var viewModel: DocumentViewModel
    let document: ManuscriptDocument.Document

    func body(content: Content) -> some View {
        content
            .onChange(of: detailViewModel.editedTitle) { oldValue, newValue in
                guard oldValue != newValue else { return }
                if let currentDoc = viewModel.findDocument(withId: document.id) {
                    if newValue.isEmpty && !currentDoc.title.isEmpty {
                        return
                    }
                    if currentDoc.title != newValue {
                        viewModel.updateDocument(document, title: newValue)
                    }
                }
            }
            .onChange(of: detailViewModel.editedSynopsis) { _, newValue in
                viewModel.updateDocument(document, synopsis: newValue)
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
            .onChange(of: detailViewModel.editedKeywords) { _, newValue in
                viewModel.updateDocument(document, keywords: newValue)
            }
            .onChange(of: detailViewModel.linkedDocumentIds) { _, newValue in
                viewModel.updateDocument(document, linkedDocumentIds: newValue)
            }
            .onChange(of: detailViewModel.isFavorite) { _, newValue in
                viewModel.updateDocument(document, isFavorite: newValue)
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
