import SwiftUI
import RichTextKit

/// Container view that displays one or two document editors based on split state
struct SplitEditorContainerView: View {
    let primaryDocument: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel
    let fileURL: URL?
    @Binding var splitEditorState: SplitEditorState

    /// RichTextContext for the primary (left/top) pane in split view
    @StateObject private var primaryRichTextContext = RichTextContext()
    /// RichTextContext for the secondary (right/bottom) pane in split view
    @StateObject private var secondaryRichTextContext = RichTextContext()

    /// DocumentDetailViewModel for the primary pane (owned by container for inspector access)
    @State private var primaryDetailViewModel: DocumentDetailViewModel?
    /// DocumentDetailViewModel for the secondary pane (owned by container for inspector access)
    @State private var secondaryDetailViewModel: DocumentDetailViewModel?

    /// Shared state for global toggles in split view
    @State private var isInspectorPresented = false
    @State private var showFindBar = false
    @State private var isReadMode = false
    @State private var inspectorDetent: PresentationDetent = .medium

    #if os(macOS)
    @AppStorage("showFormattingToolbar") private var showFormattingToolbar: Bool = true
    #endif

    /// Returns the RichTextContext for the currently focused pane
    private var activeContext: RichTextContext {
        switch splitEditorState.focusedPane {
        case .primary:
            return primaryRichTextContext
        case .secondary:
            return secondaryRichTextContext
        }
    }

    /// Returns the DocumentDetailViewModel for the currently focused pane
    private var activeDetailViewModel: DocumentDetailViewModel? {
        switch splitEditorState.focusedPane {
        case .primary:
            return primaryDetailViewModel
        case .secondary:
            return secondaryDetailViewModel
        }
    }

    var body: some View {
        if splitEditorState.isEnabled {
            if let secondaryDocId = splitEditorState.secondaryDocumentId,
               let secondaryDocument = viewModel.findDocument(withId: secondaryDocId) {
                // Split view with both documents
                splitView(primary: primaryDocument, secondary: secondaryDocument)
            } else {
                // Split view with placeholder for secondary pane
                splitViewWithPlaceholder(primary: primaryDocument)
            }
        } else {
            // Single document view - uses its own local context
            DocumentDetailView(document: primaryDocument, viewModel: viewModel, fileURL: fileURL, splitEditorState: $splitEditorState)
        }
    }

    @ViewBuilder
    private func splitView(primary: ManuscriptDocument.Document, secondary: ManuscriptDocument.Document) -> some View {
        #if os(macOS)
        macOSSplitView(primary: primary, secondary: secondary)
        #else
        iOSSplitView(primary: primary, secondary: secondary)
        #endif
    }

    @ViewBuilder
    private func splitViewWithPlaceholder(primary: ManuscriptDocument.Document) -> some View {
        #if os(macOS)
        macOSSplitViewWithPlaceholder(primary: primary)
        #else
        iOSSplitViewWithPlaceholder(primary: primary)
        #endif
    }

    // MARK: - macOS Split View

    #if os(macOS)
    @ViewBuilder
    private func macOSSplitView(primary: ManuscriptDocument.Document, secondary: ManuscriptDocument.Document) -> some View {
        VStack(spacing: 0) {
            // Unified formatting toolbar at the top
            if showFormattingToolbar {
                HStack(spacing: 0) {
                    FormattingToolbar(context: activeContext)
                    Spacer()
                    if let vm = activeDetailViewModel {
                        DocumentIndicatorsView(detailViewModel: vm)
                            .padding(.trailing, 12)
                    }
                }
                Divider()
            }

            // Split editor panes
            GeometryReader { geometry in
                if splitEditorState.orientation == .horizontal {
                    // Side by side
                    HStack(spacing: 0) {
                        splitPaneWithLabel(document: primary, isPrimary: true)
                            .frame(width: geometry.size.width * splitEditorState.splitRatio)

                        MacOSSplitDivider(
                            isVertical: true,
                            splitRatio: $splitEditorState.splitRatio,
                            totalSize: geometry.size.width
                        )

                        splitPaneWithLabel(document: secondary, isPrimary: false)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    // Top and bottom
                    VStack(spacing: 0) {
                        splitPaneWithLabel(document: primary, isPrimary: true)
                            .frame(height: geometry.size.height * splitEditorState.splitRatio)

                        MacOSSplitDivider(
                            isVertical: false,
                            splitRatio: $splitEditorState.splitRatio,
                            totalSize: geometry.size.height
                        )

                        splitPaneWithLabel(document: secondary, isPrimary: false)
                            .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .inspector(isPresented: $isInspectorPresented) {
            splitInspectorView(primary: primary, secondary: secondary)
        }
        .inspectorColumnWidth(min: 280, ideal: 320, max: 450)
        .navigationTitle(activeDocumentTitle(primary: primary, secondary: secondary))
        .toolbar {
            splitViewToolbar(primary: primary, secondary: secondary)
        }
        .onAppear {
            // Initialize view models for both documents
            primaryDetailViewModel = DocumentDetailViewModel(document: primary, documentViewModel: viewModel)
            secondaryDetailViewModel = DocumentDetailViewModel(document: secondary, documentViewModel: viewModel)
        }
        .onChange(of: primary.id) { _, _ in
            primaryDetailViewModel = DocumentDetailViewModel(document: primary, documentViewModel: viewModel)
        }
        .onChange(of: secondary.id) { _, _ in
            secondaryDetailViewModel = DocumentDetailViewModel(document: secondary, documentViewModel: viewModel)
        }
    }

    /// Inspector view for split mode - shows the active document's full inspector
    @ViewBuilder
    private func splitInspectorView(primary: ManuscriptDocument.Document, secondary: ManuscriptDocument.Document) -> some View {
        let activeDoc = splitEditorState.focusedPane == .primary ? primary : secondary

        if let detailVM = activeDetailViewModel {
            DocumentInspectorView(
                document: activeDoc,
                documentViewModel: viewModel,
                detailViewModel: detailVM,
                editedTitle: Binding(
                    get: { detailVM.editedTitle },
                    set: { detailVM.editedTitle = $0 }
                ),
                editedSynopsis: Binding(
                    get: { detailVM.editedSynopsis },
                    set: { detailVM.editedSynopsis = $0 }
                ),
                editedKeywords: Binding(
                    get: { detailVM.editedKeywords },
                    set: { detailVM.editedKeywords = $0 }
                ),
                linkedDocumentIds: Binding(
                    get: { detailVM.linkedDocumentIds },
                    set: { detailVM.linkedDocumentIds = $0 }
                ),
                isPromptExpanded: Binding(
                    get: { detailVM.isPromptExpanded },
                    set: { detailVM.isPromptExpanded = $0 }
                ),
                selectedCharacters: Binding(
                    get: { Set(detailVM.selectedCharacters) },
                    set: { detailVM.selectedCharacters = Array($0) }
                ),
                selectedLocations: Binding(
                    get: { Set(detailVM.selectedLocations) },
                    set: { detailVM.selectedLocations = Array($0) }
                ),
                isGenerating: Binding(
                    get: { detailVM.isGenerating },
                    set: { detailVM.isGenerating = $0 }
                ),
                generationType: Binding(
                    get: { detailVM.generationType },
                    set: { detailVM.generationType = $0 }
                ),
                isGenerateSheetPresented: Binding(
                    get: { detailVM.isGenerateSheetPresented },
                    set: { detailVM.isGenerateSheetPresented = $0 }
                ),
                generatedText: Binding(
                    get: { detailVM.generatedText },
                    set: { detailVM.generatedText = $0 }
                ),
                generationError: Binding(
                    get: { detailVM.generationError },
                    set: { detailVM.generationError = $0 }
                ),
                isInspectorPresented: $isInspectorPresented,
                inspectorDetent: $inspectorDetent,
                selectedText: Binding(
                    get: { detailVM.selectedText },
                    set: { detailVM.selectedText = $0 }
                ),
                hasTextSelection: Binding(
                    get: { detailVM.hasTextSelection },
                    set: { detailVM.hasTextSelection = $0 }
                ),
                generateAction: { type, prompt in
                    await detailVM.generateText(type: type, prompt: prompt ?? "")
                },
                applyAction: {
                    detailVM.applyGeneratedText(detailVM.generatedText)
                },
                applyToSelectionAction: { text in
                    print("Apply to selection: \(text)")
                }
            )
            .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
        } else {
            // Fallback while view models are being created
            VStack {
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
        }
    }

    /// Returns the title of the active document
    private func activeDocumentTitle(primary: ManuscriptDocument.Document, secondary: ManuscriptDocument.Document) -> String {
        let activeDoc = splitEditorState.focusedPane == .primary ? primary : secondary
        return activeDoc.title.isEmpty ? "Untitled" : activeDoc.title
    }

    /// Unified toolbar for split view
    @ToolbarContentBuilder
    private func splitViewToolbar(primary: ManuscriptDocument.Document, secondary: ManuscriptDocument.Document) -> some ToolbarContent {
        // Center: View modes (Composition, Read)
        ToolbarItemGroup(placement: .principal) {
            Button {
                // Open composition mode with focused document's view model
                if let vm = splitEditorState.focusedPane == .primary ? primaryDetailViewModel : secondaryDetailViewModel {
                    CompositionModeWindowController.shared.show(viewModel: vm) { }
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
        }

        // Right: Split View menu
        ToolbarItem(placement: .primaryAction) {
            splitViewMoreMenu
        }

        // Right: Find & Replace
        ToolbarItem(placement: .primaryAction) {
            Button {
                showFindBar.toggle()
            } label: {
                Label("Find", systemImage: "magnifyingglass")
            }
            .help("Find (⌘F)")
        }

        // Right: Inspector toggle
        ToolbarItem(placement: .primaryAction) {
            Button {
                isInspectorPresented.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.right")
            }
            .help("Toggle Inspector")
        }
    }

    /// More menu for split view
    private var splitViewMoreMenu: some View {
        Menu {
            // Close split view option
            Button {
                splitEditorState.isEnabled = false
                splitEditorState.secondaryDocumentId = nil
            } label: {
                Label("Close Split View", systemImage: "rectangle")
            }

            // Orientation picker
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
        } label: {
            Label("Split View", systemImage: "rectangle.split.2x1.fill")
        }
    }

    /// Wraps a document view with a small title label
    @ViewBuilder
    private func splitPaneWithLabel(document: ManuscriptDocument.Document, isPrimary: Bool) -> some View {
        let context = isPrimary ? primaryRichTextContext : secondaryRichTextContext
        let detailVM = isPrimary ? primaryDetailViewModel : secondaryDetailViewModel
        let isActive = isPrimary ? (splitEditorState.focusedPane == .primary) : (splitEditorState.focusedPane == .secondary)

        VStack(spacing: 0) {
            // Clickable document name header - click to make this pane active
            Button {
                splitEditorState.focusedPane = isPrimary ? .primary : .secondary
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 9))
                    Text(document.title.isEmpty ? "Untitled" : document.title)
                        .font(.system(size: 11, weight: isActive ? .medium : .regular))
                        .lineLimit(1)
                    Spacer()
                    // Active indicator
                    if isActive {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                    }
                }
                .foregroundStyle(isActive ? Color.white : Color.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? Color.accentColor.opacity(0.3) : Color(nsColor: .windowBackgroundColor).opacity(0.8))
            }
            .buttonStyle(.plain)

            DocumentDetailView(
                document: document,
                viewModel: viewModel,
                fileURL: fileURL,
                splitEditorState: $splitEditorState,
                externalRichTextContext: context,
                onFocusChange: { focused in
                    if focused {
                        splitEditorState.focusedPane = isPrimary ? .primary : .secondary
                    }
                },
                hideToolbar: true,
                hideToolbarItems: true,
                isActiveInSplitView: isActive,
                externalDetailViewModel: detailVM,
                externalInspectorPresented: $isInspectorPresented,
                externalShowFindBar: $showFindBar,
                externalIsReadMode: $isReadMode
            )
            .id(document.id) // Force view recreation when document changes
        }
    }

    /// Divider for macOS split view with drag support
    private struct MacOSSplitDivider: View {
        let isVertical: Bool
        @Binding var splitRatio: CGFloat
        let totalSize: CGFloat

        @State private var isDragging = false

        var body: some View {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: isVertical ? 1 : nil, height: isVertical ? nil : 1)
                .overlay {
                    // Larger hit area for easier dragging
                    Color.clear
                        .frame(width: isVertical ? 8 : nil, height: isVertical ? nil : 8)
                        .contentShape(Rectangle())
                }
                .onHover { hovering in
                    if hovering {
                        if isVertical {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.resizeUpDown.push()
                        }
                    } else {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let delta = isVertical ? value.translation.width : value.translation.height
                            let newRatio = splitRatio + (delta / totalSize) * 0.1

                            // Clamp to valid range
                            splitRatio = min(max(newRatio, SplitEditorState.minimumRatio), 1.0 - SplitEditorState.minimumRatio)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
        }
    }

    @ViewBuilder
    private func macOSSplitViewWithPlaceholder(primary: ManuscriptDocument.Document) -> some View {
        VStack(spacing: 0) {
            // Unified formatting toolbar at the top
            if showFormattingToolbar {
                HStack(spacing: 0) {
                    FormattingToolbar(context: primaryRichTextContext)
                    Spacer()
                    if let vm = primaryDetailViewModel {
                        DocumentIndicatorsView(detailViewModel: vm)
                            .padding(.trailing, 12)
                    }
                }
                Divider()
            }

            // Split editor panes
            GeometryReader { geometry in
                if splitEditorState.orientation == .horizontal {
                    // Side by side
                    HStack(spacing: 0) {
                        splitPaneWithLabel(document: primary, isPrimary: true)
                            .frame(width: geometry.size.width * splitEditorState.splitRatio)

                        MacOSSplitDivider(
                            isVertical: true,
                            splitRatio: $splitEditorState.splitRatio,
                            totalSize: geometry.size.width
                        )

                        placeholderPane
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    // Top and bottom
                    VStack(spacing: 0) {
                        splitPaneWithLabel(document: primary, isPrimary: true)
                            .frame(height: geometry.size.height * splitEditorState.splitRatio)

                        MacOSSplitDivider(
                            isVertical: false,
                            splitRatio: $splitEditorState.splitRatio,
                            totalSize: geometry.size.height
                        )

                        placeholderPane
                            .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .navigationTitle(primary.title.isEmpty ? "Untitled" : primary.title)
        .toolbar {
            placeholderToolbar(primary: primary)
        }
        .onAppear {
            primaryDetailViewModel = DocumentDetailViewModel(document: primary, documentViewModel: viewModel)
        }
    }

    /// Placeholder pane shown when no document is selected for split view
    private var placeholderPane: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Select a document")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Choose a document from the binder to view it here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
    }

    @ToolbarContentBuilder
    private func placeholderToolbar(primary: ManuscriptDocument.Document) -> some ToolbarContent {
        // Center: View modes (Composition, Read)
        ToolbarItemGroup(placement: .principal) {
            Button {
                // Open composition mode with primary document
                if let vm = primaryDetailViewModel {
                    CompositionModeWindowController.shared.show(viewModel: vm) { }
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
        }

        // Right: Split View menu
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    splitEditorState.orientation = .horizontal
                } label: {
                    HStack {
                        Label("Split Horizontal", systemImage: "rectangle.split.2x1")
                        if splitEditorState.orientation == .horizontal {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    splitEditorState.orientation = .vertical
                } label: {
                    HStack {
                        Label("Split Vertical", systemImage: "rectangle.split.1x2")
                        if splitEditorState.orientation == .vertical {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                Button {
                    splitEditorState.isEnabled = false
                    splitEditorState.secondaryDocumentId = nil
                } label: {
                    Label("Close Split View", systemImage: "rectangle")
                }
            } label: {
                Label("Split View", systemImage: "rectangle.split.2x1.fill")
            }
        }

        // Right: Find & Replace
        ToolbarItem(placement: .primaryAction) {
            Button {
                showFindBar.toggle()
            } label: {
                Label("Find", systemImage: "magnifyingglass")
            }
            .help("Find (⌘F)")
        }

        // Right: Inspector toggle
        ToolbarItem(placement: .primaryAction) {
            Button {
                isInspectorPresented.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.right")
            }
            .help("Toggle Inspector")
        }
    }
    #endif

    // MARK: - iOS Split View

    #if os(iOS)
    @ViewBuilder
    private func iOSSplitView(primary: ManuscriptDocument.Document, secondary: ManuscriptDocument.Document) -> some View {
        GeometryReader { geometry in
            // iOS always uses vertical split (top/bottom)
            VStack(spacing: 0) {
                DocumentDetailView(document: primary, viewModel: viewModel, fileURL: fileURL, splitEditorState: $splitEditorState)
                    .frame(height: geometry.size.height * splitEditorState.splitRatio)

                SplitDividerView(
                    splitRatio: $splitEditorState.splitRatio,
                    totalHeight: geometry.size.height
                )

                DocumentDetailView(document: secondary, viewModel: viewModel, fileURL: fileURL, splitEditorState: $splitEditorState)
                    .frame(maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func iOSSplitViewWithPlaceholder(primary: ManuscriptDocument.Document) -> some View {
        GeometryReader { geometry in
            // iOS always uses vertical split (top/bottom)
            VStack(spacing: 0) {
                DocumentDetailView(document: primary, viewModel: viewModel, fileURL: fileURL, splitEditorState: $splitEditorState)
                    .frame(height: geometry.size.height * splitEditorState.splitRatio)

                SplitDividerView(
                    splitRatio: $splitEditorState.splitRatio,
                    totalHeight: geometry.size.height
                )

                iOSPlaceholderPane
                    .frame(maxHeight: .infinity)
            }
        }
    }

    /// Placeholder pane shown when no document is selected for split view (iOS)
    private var iOSPlaceholderPane: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Select a document")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Choose a document from the binder to view it here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground).opacity(0.5))
    }
    #endif
}

#if DEBUG
struct SplitEditorContainerView_Previews: PreviewProvider {
    static var previews: some View {
        let doc = ManuscriptDocument.Document(title: "Test", content: "Content")
        SplitEditorContainerView(
            primaryDocument: doc,
            viewModel: DocumentViewModel(),
            fileURL: nil,
            splitEditorState: .constant(SplitEditorState())
        )
    }
}
#endif
