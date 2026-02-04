import SwiftUI

struct KeywordCollectionView: View {
    let keyword: String
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    private var matchingDocuments: [ManuscriptDocument.Document] {
        viewModel.documents(matching: keyword).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var matchingMedia: [ManuscriptDocument.MediaItem] {
        viewModel.mediaItems(matching: keyword).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        List {
            if matchingDocuments.isEmpty && matchingMedia.isEmpty {
                emptyState
            } else {
                if !matchingDocuments.isEmpty {
                    Section("Documents") {
                        ForEach(matchingDocuments) { document in
                            documentRow(document)
                        }
                    }
                }

                if !matchingMedia.isEmpty {
                    Section("Media") {
                        ForEach(matchingMedia) { mediaItem in
                            mediaRow(mediaItem)
                        }
                    }
                }
            }
        }
        .navigationTitle("Keyword: \(keyword)")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tag.slash")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No items found")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("No documents or media items have this keyword yet.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func documentRow(_ document: ManuscriptDocument.Document) -> some View {
        #if os(iOS)
        NavigationLink(value: DetailSelection.document(document)) {
            Label(document.title.isEmpty ? "Untitled" : document.title, systemImage: document.iconName)
        }
        #else
        Button {
            selection = .document(document)
        } label: {
            Label(document.title.isEmpty ? "Untitled" : document.title, systemImage: document.iconName)
        }
        .buttonStyle(.plain)
        #endif
    }

    @ViewBuilder
    private func mediaRow(_ mediaItem: ManuscriptDocument.MediaItem) -> some View {
        #if os(iOS)
        NavigationLink(value: DetailSelection.mediaItem(mediaItem)) {
            Label(mediaItem.title.isEmpty ? "Untitled" : mediaItem.title, systemImage: mediaItem.iconName)
        }
        #else
        Button {
            selection = .mediaItem(mediaItem)
        } label: {
            Label(mediaItem.title.isEmpty ? "Untitled" : mediaItem.title, systemImage: mediaItem.iconName)
        }
        .buttonStyle(.plain)
        #endif
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: DetailSelection? = nil
    let viewModel = DocumentViewModel()
    return KeywordCollectionView(keyword: "Example", viewModel: viewModel, selection: $selection)
}
#endif
