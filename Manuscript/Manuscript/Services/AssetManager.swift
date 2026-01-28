import Foundation
import SwiftUI
import Combine
import CoreGraphics
import ImageIO

#if canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

/// Manages media assets stored in the .manuscript package's assets/ folder
class AssetManager: ObservableObject {

    // MARK: - Properties

    /// The URL of the current document package
    @Published private(set) var packageURL: URL?

    /// Cache for loaded images (keyed by filename)
    private var imageCache: [String: PlatformImage] = [:]

    /// Cache for generated thumbnails (keyed by filename + size)
    private var thumbnailCache: [String: PlatformImage] = [:]

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Set the package URL when a document is opened
    func setPackageURL(_ url: URL?) {
        if url != packageURL {
            packageURL = url
            // Clear caches when package changes
            imageCache.removeAll()
            thumbnailCache.removeAll()
        }
    }

    /// Get the URL for an asset file
    func assetURL(for mediaItem: ManuscriptDocument.MediaItem) -> URL? {
        guard let packageURL = packageURL else { return nil }
        return packageURL.appendingPathComponent("assets").appendingPathComponent(mediaItem.filename)
    }

    /// Load an image for a media item
    func loadImage(for mediaItem: ManuscriptDocument.MediaItem) -> PlatformImage? {
        guard mediaItem.mediaType == .image else { return nil }

        // Check cache first
        if let cached = imageCache[mediaItem.filename] {
            return cached
        }

        // Load from disk
        guard let url = assetURL(for: mediaItem) else { return nil }

        #if canImport(AppKit)
        guard let image = NSImage(contentsOf: url) else { return nil }
        #else
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        #endif

        // Cache and return
        imageCache[mediaItem.filename] = image
        return image
    }

    /// Generate a thumbnail for a media item
    func generateThumbnail(for mediaItem: ManuscriptDocument.MediaItem, size: CGSize) -> PlatformImage? {
        let cacheKey = "\(mediaItem.filename)_\(Int(size.width))x\(Int(size.height))"

        // Check cache first
        if let cached = thumbnailCache[cacheKey] {
            return cached
        }

        guard let url = assetURL(for: mediaItem) else { return nil }

        var thumbnail: PlatformImage?

        if mediaItem.mediaType == .image {
            thumbnail = generateImageThumbnail(from: url, size: size)
        } else if mediaItem.mediaType == .pdf {
            thumbnail = generatePDFThumbnail(from: url, size: size)
        }

        if let thumbnail = thumbnail {
            thumbnailCache[cacheKey] = thumbnail
        }

        return thumbnail
    }

    /// Import an asset from a source URL to the assets folder
    func importAsset(from sourceURL: URL, filename: String) throws -> URL {
        guard let packageURL = packageURL else {
            throw AssetManagerError.noPackageURL
        }

        let assetsFolder = packageURL.appendingPathComponent("assets")

        // Create assets folder if it doesn't exist
        try FileManager.default.createDirectory(at: assetsFolder, withIntermediateDirectories: true)

        let destinationURL = assetsFolder.appendingPathComponent(filename)

        // Copy file
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        return destinationURL
    }

    /// Delete an asset file
    func deleteAsset(filename: String) throws {
        guard let packageURL = packageURL else {
            throw AssetManagerError.noPackageURL
        }

        let assetURL = packageURL.appendingPathComponent("assets").appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: assetURL.path) {
            try FileManager.default.removeItem(at: assetURL)
        }

        // Clear from caches
        imageCache.removeValue(forKey: filename)
        thumbnailCache = thumbnailCache.filter { !$0.key.hasPrefix(filename) }
    }

    /// Get image dimensions without loading the full image
    func getImageDimensions(for mediaItem: ManuscriptDocument.MediaItem) -> (width: Int, height: Int)? {
        guard mediaItem.mediaType == .image,
              let url = assetURL(for: mediaItem),
              let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return nil
        }

        if let width = properties[kCGImagePropertyPixelWidth] as? Int,
           let height = properties[kCGImagePropertyPixelHeight] as? Int {
            return (width, height)
        }

        return nil
    }

    /// Get PDF page count
    func getPDFPageCount(for mediaItem: ManuscriptDocument.MediaItem) -> Int? {
        guard mediaItem.mediaType == .pdf,
              let url = assetURL(for: mediaItem),
              let document = CGPDFDocument(url as CFURL) else {
            return nil
        }
        return document.numberOfPages
    }

    /// Clear all caches
    func clearCaches() {
        imageCache.removeAll()
        thumbnailCache.removeAll()
    }

    // MARK: - Private Methods

    private func generateImageThumbnail(from url: URL, size: CGSize) -> PlatformImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
        ]

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        #if canImport(AppKit)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #else
        return UIImage(cgImage: cgImage)
        #endif
    }

    private func generatePDFThumbnail(from url: URL, size: CGSize) -> PlatformImage? {
        guard let document = CGPDFDocument(url as CFURL),
              let page = document.page(at: 1) else {
            return nil
        }

        let pageRect = page.getBoxRect(.mediaBox)
        let scale = min(size.width / pageRect.width, size.height / pageRect.height)
        let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

        #if canImport(AppKit)
        let image = NSImage(size: scaledSize)
        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: scaledSize))
            context.scaleBy(x: scale, y: scale)
            context.drawPDFPage(page)
        }
        image.unlockFocus()
        return image
        #else
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: scaledSize))

            context.cgContext.translateBy(x: 0, y: scaledSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            context.cgContext.drawPDFPage(page)
        }
        #endif
    }
}

// MARK: - Errors

enum AssetManagerError: LocalizedError {
    case noPackageURL
    case fileNotFound
    case copyFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noPackageURL:
            return "No document is currently open."
        case .fileNotFound:
            return "The asset file could not be found."
        case .copyFailed(let error):
            return "Failed to copy asset: \(error.localizedDescription)"
        }
    }
}
