import Foundation
import SwiftUI
import Combine
import OSLog

class RecentDocumentsManager: ObservableObject {
    private let maxRecentDocuments = 10
    private let recentDocumentsKey = "recentDocuments"

    @Published var recentDocuments: [RecentDocument] = []

    init() {
        loadRecentDocuments()
    }

    func addDocument(url: URL, title: String) {
        // Remove if already exists
        recentDocuments.removeAll { $0.url == url }

        // Create bookmark data for security-scoped access
        #if os(macOS)
        let bookmarkOptions: URL.BookmarkCreationOptions = .withSecurityScope
        #else
        let bookmarkOptions: URL.BookmarkCreationOptions = []
        #endif
        let bookmarkData = try? url.bookmarkData(
            options: bookmarkOptions,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        // Add to the beginning
        let newDocument = RecentDocument(
            url: url,
            title: title,
            lastOpenedDate: Date(),
            bookmarkData: bookmarkData
        )
        recentDocuments.insert(newDocument, at: 0)

        // Trim if needed
        if recentDocuments.count > maxRecentDocuments {
            recentDocuments = Array(recentDocuments.prefix(maxRecentDocuments))
        }

        saveRecentDocuments()
    }

    func removeDocument(at url: URL) {
        recentDocuments.removeAll { $0.url == url }
        saveRecentDocuments()
    }

    func clearRecentDocuments() {
        recentDocuments.removeAll()
        saveRecentDocuments()
    }

    /// Resolves the security-scoped bookmark and returns an accessible URL
    /// Returns nil if the bookmark cannot be resolved
    func resolveBookmark(for document: RecentDocument) -> URL? {
        guard let bookmarkData = document.bookmarkData else {
            // No bookmark data - try the URL directly (may fail for sandboxed files)
            return document.url
        }

        var isStale = false
        do {
            #if os(macOS)
            let resolveOptions: URL.BookmarkResolutionOptions = .withSecurityScope
            #else
            let resolveOptions: URL.BookmarkResolutionOptions = []
            #endif
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: resolveOptions,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            // If bookmark is stale, try to update it
            if isStale {
                updateBookmark(for: document, with: resolvedURL)
            }

            return resolvedURL
        } catch {
            Log.document.error("Error resolving bookmark for \(document.title): \(error.localizedDescription)")
            return nil
        }
    }

    private func updateBookmark(for document: RecentDocument, with url: URL) {
        guard let index = recentDocuments.firstIndex(where: { $0.url == document.url }) else { return }

        #if os(macOS)
        let bookmarkOptions: URL.BookmarkCreationOptions = .withSecurityScope
        #else
        let bookmarkOptions: URL.BookmarkCreationOptions = []
        #endif
        let newBookmarkData = try? url.bookmarkData(
            options: bookmarkOptions,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        recentDocuments[index] = RecentDocument(
            url: url,
            title: document.title,
            lastOpenedDate: document.lastOpenedDate,
            bookmarkData: newBookmarkData
        )

        saveRecentDocuments()
    }

    private func loadRecentDocuments() {
        guard let data = UserDefaults.standard.data(forKey: recentDocumentsKey) else { return }

        do {
            let decoder = JSONDecoder()
            recentDocuments = try decoder.decode([RecentDocument].self, from: data)
        } catch {
            Log.app.error("Error loading recent documents: \(error.localizedDescription)")
        }
    }

    private func saveRecentDocuments() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recentDocuments)
            UserDefaults.standard.set(data, forKey: recentDocumentsKey)
        } catch {
            Log.app.error("Error saving recent documents: \(error.localizedDescription)")
        }
    }
}

struct RecentDocument: Codable, Identifiable, Equatable {
    var id: String { url.absoluteString }
    let url: URL
    let title: String
    let lastOpenedDate: Date
    let bookmarkData: Data?

    enum CodingKeys: String, CodingKey {
        case url, title, lastOpenedDate, bookmarkData
    }

    init(url: URL, title: String, lastOpenedDate: Date, bookmarkData: Data? = nil) {
        self.url = url
        self.title = title
        self.lastOpenedDate = lastOpenedDate
        self.bookmarkData = bookmarkData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let urlString = try container.decode(String.self, forKey: .url)

        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .url,
                in: container,
                debugDescription: "Invalid URL string"
            )
        }

        self.url = url
        self.title = try container.decode(String.self, forKey: .title)
        self.lastOpenedDate = try container.decode(Date.self, forKey: .lastOpenedDate)
        self.bookmarkData = try container.decodeIfPresent(Data.self, forKey: .bookmarkData)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url.absoluteString, forKey: .url)
        try container.encode(title, forKey: .title)
        try container.encode(lastOpenedDate, forKey: .lastOpenedDate)
        try container.encodeIfPresent(bookmarkData, forKey: .bookmarkData)
    }

    static func == (lhs: RecentDocument, rhs: RecentDocument) -> Bool {
        return lhs.url == rhs.url
    }
} 