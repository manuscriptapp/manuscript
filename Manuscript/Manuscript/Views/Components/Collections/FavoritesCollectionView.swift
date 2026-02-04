import SwiftUI

struct FavoritesCollectionView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    private var favoriteDocuments: [ManuscriptDocument.Document] {
        viewModel.favoriteDocuments.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var favoriteMedia: [ManuscriptDocument.MediaItem] {
        viewModel.favoriteMediaItems.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        List {
            if favoriteDocuments.isEmpty && favoriteMedia.isEmpty {
                emptyState
            } else {
                if !favoriteDocuments.isEmpty {
                    Section("Documents") {
                        ForEach(favoriteDocuments) { document in
                            documentRow(document)
                        }
                    }
                }

                if !favoriteMedia.isEmpty {
                    Section("Media") {
                        ForEach(favoriteMedia) { mediaItem in
                            mediaRow(mediaItem)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorites")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.slash")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No favorites yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Mark documents or media as favorites to see them here.")
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
    return FavoritesCollectionView(viewModel: viewModel, selection: $selection)
}
#endif
