import SwiftUI

/// Container view that displays one or two document editors based on split state
struct SplitEditorContainerView: View {
    let primaryDocument: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel
    let fileURL: URL?
    @Binding var splitEditorState: SplitEditorState

    var body: some View {
        if splitEditorState.isEnabled, let secondaryDocId = splitEditorState.secondaryDocumentId,
           let secondaryDocument = viewModel.findDocument(withId: secondaryDocId) {
            splitView(primary: primaryDocument, secondary: secondaryDocument)
        } else {
            // Single document view
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

    // MARK: - macOS Split View

    #if os(macOS)
    @ViewBuilder
    private func macOSSplitView(primary: ManuscriptDocument.Document, secondary: ManuscriptDocument.Document) -> some View {
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

    /// Wraps a document view with a small title label
    @ViewBuilder
    private func splitPaneWithLabel(document: ManuscriptDocument.Document, isPrimary: Bool) -> some View {
        VStack(spacing: 0) {
            // Small document name header
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.system(size: 9))
                Text(document.title.isEmpty ? "Untitled" : document.title)
                    .font(.system(size: 11))
                    .lineLimit(1)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))

            DocumentDetailView(document: document, viewModel: viewModel, fileURL: fileURL, splitEditorState: $splitEditorState)
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
