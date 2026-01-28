import SwiftUI

/// A row view for displaying a media item in the sidebar
struct MediaItemView: View {
    let mediaItem: ManuscriptDocument.MediaItem
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var selection: DetailSelection?

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: mediaItem.iconName)
                .foregroundColor(iconColor)
                .frame(width: 16)

            // Title
            Text(mediaItem.title.isEmpty ? "Untitled" : mediaItem.title)
                .lineLimit(1)

            Spacer()

            // File type badge
            Text(mediaItem.mediaType.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            contextMenuItems
        }
    }

    private var iconColor: Color {
        if let hexColor = mediaItem.iconColor {
            return Color(hex: hexColor) ?? .accentColor
        }
        return mediaItem.mediaType == .image ? .purple : .orange
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        // View
        Button {
            selection = .mediaItem(mediaItem)
        } label: {
            Label("View", systemImage: "eye")
        }

        Divider()

        // Rename
        Button {
            viewModel.showRenameAlert(for: mediaItem)
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Divider()

        // Trash actions
        if viewModel.isMediaItemInTrash(mediaItem) {
            Button {
                viewModel.restoreMediaItemFromTrash(mediaItem)
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }

            Button(role: .destructive) {
                viewModel.permanentlyDeleteMediaItem(mediaItem)
            } label: {
                Label("Delete Permanently", systemImage: "trash")
            }
        } else {
            Button(role: .destructive) {
                viewModel.moveMediaItemToTrash(mediaItem)
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
        }
    }
}

/// A card view for displaying a media item in folder grid view
struct MediaItemCard: View {
    let mediaItem: ManuscriptDocument.MediaItem
    @ObservedObject var viewModel: DocumentViewModel
    @ObservedObject var assetManager: AssetManager
    @Binding var selection: DetailSelection?

    var body: some View {
        Button {
            viewModel.expandToMediaItem(mediaItem)
            selection = .mediaItem(mediaItem)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                thumbnailView
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)

                // Title and type
                HStack {
                    Image(systemName: mediaItem.iconName)
                        .foregroundColor(iconColor)
                    Text(mediaItem.title.isEmpty ? "Untitled" : mediaItem.title)
                        .font(.headline)
                        .lineLimit(1)
                }

                // Synopsis
                if !mediaItem.synopsis.isEmpty {
                    Text(mediaItem.synopsis)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // File info
                HStack {
                    Text(mediaItem.formattedFileSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(mediaItem.mediaType.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                viewModel.showRenameAlert(for: mediaItem)
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                viewModel.moveMediaItemToTrash(mediaItem)
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
        }
    }

    private var iconColor: Color {
        if let hexColor = mediaItem.iconColor {
            return Color(hex: hexColor) ?? .accentColor
        }
        return mediaItem.mediaType == .image ? .purple : .orange
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail = assetManager.generateThumbnail(for: mediaItem, size: CGSize(width: 200, height: 120)) {
            #if canImport(AppKit)
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
            #else
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
            #endif
        } else {
            Image(systemName: mediaItem.mediaType == .image ? "photo" : "doc.richtext")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        MediaItemView(
            mediaItem: ManuscriptDocument.MediaItem(
                title: "Test Image",
                mediaType: .image,
                filename: "test.png",
                originalFilename: "test.png",
                fileSize: 1024 * 512
            ),
            viewModel: DocumentViewModel(),
            selection: .constant(nil)
        )
        .padding()

        MediaItemCard(
            mediaItem: ManuscriptDocument.MediaItem(
                title: "Test PDF",
                synopsis: "A sample PDF document for testing.",
                mediaType: .pdf,
                filename: "test.pdf",
                originalFilename: "document.pdf",
                fileSize: 1024 * 1024 * 2,
                pageCount: 10
            ),
            viewModel: DocumentViewModel(),
            assetManager: AssetManager(),
            selection: .constant(nil)
        )
        .frame(width: 200, height: 220)
        .padding()
    }
}
#endif
