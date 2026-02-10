import SwiftUI

/// Main container view for displaying media items (images and PDFs)
struct MediaDetailView: View {
    let mediaItem: ManuscriptDocument.MediaItem
    @ObservedObject var viewModel: DocumentViewModel
    @ObservedObject var assetManager: AssetManager

    @State private var showInspector: Bool = false

    var body: some View {
        #if os(macOS)
        HSplitView {
            // Main content area
            contentView
                .frame(minWidth: 400)

            // Inspector panel
            if showInspector {
                MediaInspectorView(mediaItem: mediaItem, viewModel: viewModel)
                    .frame(width: 280)
            }
        }
        .navigationTitle(mediaItem.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showInspector.toggle()
                } label: {
                    Image(systemName: "sidebar.right")
                }
                .help(showInspector ? "Hide Inspector" : "Show Inspector")
            }
        }
        #else
        contentView
            .navigationTitle(mediaItem.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showInspector.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showInspector) {
                NavigationStack {
                    MediaInspectorView(mediaItem: mediaItem, viewModel: viewModel)
                        .navigationTitle("Media Info")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                ManuscriptDoneButton {
                                    showInspector = false
                                }
                            }
                        }
                }
            }
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        switch mediaItem.mediaType {
        case .image:
            ImagePreviewView(mediaItem: mediaItem, assetManager: assetManager)
        case .pdf:
            PDFPreviewView(mediaItem: mediaItem, assetManager: assetManager)
        }
    }
}

/// Inspector panel showing media item metadata
struct MediaInspectorView: View {
    let mediaItem: ManuscriptDocument.MediaItem
    @ObservedObject var viewModel: DocumentViewModel

    @State private var editedTitle: String = ""
    @State private var editedSynopsis: String = ""
    @State private var editedKeywords: [String] = []
    @State private var isFavorite: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextField("Title", text: $editedTitle)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            saveTitle()
                        }
                }

                Divider()

                // Synopsis section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Synopsis")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextEditor(text: $editedSynopsis)
                        .frame(minHeight: 100)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        .onChange(of: editedSynopsis) { _, newValue in
                            saveSynopsis()
                        }
                }

                Divider()

                // File info section
                VStack(alignment: .leading, spacing: 8) {
                    Text("File Information")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    infoRow(label: "Type", value: mediaItem.mediaType.displayName)
                    infoRow(label: "Original Name", value: mediaItem.originalFilename)
                    infoRow(label: "Size", value: mediaItem.formattedFileSize)

                    if let dimensions = mediaItem.dimensionsString {
                        infoRow(label: "Dimensions", value: dimensions)
                    }

                    if let pageCount = mediaItem.pageCount {
                        infoRow(label: "Pages", value: "\(pageCount)")
                    }

                    infoRow(label: "Created", value: mediaItem.creationDate.formatted(date: .abbreviated, time: .shortened))
                }

                Divider()

                Toggle("Favorite", isOn: $isFavorite)
                    .toggleStyle(.switch)

                KeywordEditorView(
                    title: "Keywords",
                    keywords: $editedKeywords,
                    suggestions: viewModel.allKeywords
                )

                Spacer()
            }
            .padding()
        }
        .onAppear {
            editedTitle = mediaItem.title
            editedSynopsis = mediaItem.synopsis
            editedKeywords = mediaItem.keywords
            isFavorite = mediaItem.isFavorite
        }
        .onChange(of: mediaItem.id) { _, _ in
            editedTitle = mediaItem.title
            editedSynopsis = mediaItem.synopsis
            editedKeywords = mediaItem.keywords
            isFavorite = mediaItem.isFavorite
        }
        .onChange(of: editedKeywords) { _, newValue in
            viewModel.updateMediaItem(mediaItem, keywords: newValue)
        }
        .onChange(of: isFavorite) { _, newValue in
            viewModel.updateMediaItem(mediaItem, isFavorite: newValue)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .lineLimit(1)
        }
        .font(.caption)
    }

    private func saveTitle() {
        if editedTitle != mediaItem.title {
            viewModel.updateMediaItem(mediaItem, title: editedTitle)
        }
    }

    private func saveSynopsis() {
        if editedSynopsis != mediaItem.synopsis {
            viewModel.updateMediaItem(mediaItem, synopsis: editedSynopsis)
        }
    }
}

/// Simple flow layout for keywords
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, proposal: proposal)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, proposal: proposal)
        for (subview, frame) in zip(subviews, result.frames) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func layout(subviews: Subviews, proposal: ProposedViewSize) -> (size: CGSize, frames: [CGRect]) {
        let width = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxHeight = max(maxHeight, y + size.height)
        }

        return (CGSize(width: width, height: maxHeight), frames)
    }
}

#if DEBUG
#Preview {
    MediaDetailView(
        mediaItem: ManuscriptDocument.MediaItem(
            title: "Test Image",
            synopsis: "A test image for preview purposes.",
            mediaType: .image,
            filename: "test.png",
            originalFilename: "test.png",
            fileSize: 1024 * 1024,
            keywords: ["test", "preview", "image"]
        ),
        viewModel: DocumentViewModel(),
        assetManager: AssetManager()
    )
}
#endif
