import SwiftUI
import UniformTypeIdentifiers

/// A sheet for adding media files to a folder via file picker
struct AddMediaSheet: View {
    @ObservedObject var viewModel: DocumentViewModel
    let targetFolder: ManuscriptFolder
    @Environment(\.dismiss) private var dismiss

    @State private var isFileImporterPresented = false

    /// Supported media file types
    private let supportedTypes: [UTType] = [
        .image,
        .png,
        .jpeg,
        .gif,
        .heic,
        .webP,
        .tiff,
        .bmp,
        .pdf
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                Text("Add Media to \(targetFolder.title)")
                    .font(.headline)

                Text("Select images or PDF files to add to this folder.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Choose Files", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .manuscriptPrimaryButton()
                .padding(.horizontal, 40)

                Spacer()

                VStack(spacing: 4) {
                    Text("Supported formats:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("PNG, JPEG, GIF, HEIC, WebP, TIFF, BMP, PDF")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Add Media")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: supportedTypes,
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }
                defer { url.stopAccessingSecurityScopedResource() }

                do {
                    let mediaItem = try createMediaItem(from: url)
                    viewModel.addMediaItem(to: targetFolder, mediaItem: mediaItem)
                } catch {
                    print("Failed to import media: \(error)")
                }
            }
            dismiss()

        case .failure(let error):
            print("File import failed: \(error)")
        }
    }

    private func createMediaItem(from url: URL) throws -> ManuscriptDocument.MediaItem {
        let fileExtension = url.pathExtension.lowercased()
        guard let mediaType = MediaType.from(extension: fileExtension) else {
            throw MediaImportError.unsupportedType
        }

        // Get file attributes
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes[.size] as? Int64) ?? 0
        let originalFilename = url.lastPathComponent

        // Generate UUID-based filename
        let newFilename = "\(UUID().uuidString).\(fileExtension)"

        // Get image dimensions if applicable
        var imageWidth: Int?
        var imageHeight: Int?
        var pageCount: Int?

        if mediaType == .image {
            if let dimensions = getImageDimensions(from: url) {
                imageWidth = dimensions.width
                imageHeight = dimensions.height
            }
        } else if mediaType == .pdf {
            pageCount = getPDFPageCount(from: url)
        }

        // Copy file to pending assets
        viewModel.document.pendingAssetFiles[newFilename] = url

        return ManuscriptDocument.MediaItem(
            title: url.deletingPathExtension().lastPathComponent,
            mediaType: mediaType,
            filename: newFilename,
            originalFilename: originalFilename,
            fileSize: fileSize,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            pageCount: pageCount
        )
    }

    private func getImageDimensions(from url: URL) -> (width: Int, height: Int)? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        return (width, height)
    }

    private func getPDFPageCount(from url: URL) -> Int? {
        guard let document = CGPDFDocument(url as CFURL) else {
            return nil
        }
        return document.numberOfPages
    }
}

enum MediaImportError: LocalizedError {
    case unsupportedType
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedType:
            return "This file type is not supported."
        case .copyFailed:
            return "Failed to copy the file."
        }
    }
}

#if DEBUG
#Preview {
    AddMediaSheet(
        viewModel: DocumentViewModel(),
        targetFolder: ManuscriptFolder(title: "Research")
    )
}
#endif
