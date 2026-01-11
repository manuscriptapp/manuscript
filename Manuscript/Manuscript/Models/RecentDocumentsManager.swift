import Foundation
import SwiftUI
import Combine

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
        
        // Add to the beginning
        let newDocument = RecentDocument(url: url, title: title, lastOpenedDate: Date())
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
    
    private func loadRecentDocuments() {
        guard let data = UserDefaults.standard.data(forKey: recentDocumentsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            recentDocuments = try decoder.decode([RecentDocument].self, from: data)
        } catch {
            print("Error loading recent documents: \(error)")
        }
    }
    
    private func saveRecentDocuments() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recentDocuments)
            UserDefaults.standard.set(data, forKey: recentDocumentsKey)
        } catch {
            print("Error saving recent documents: \(error)")
        }
    }
}

struct RecentDocument: Codable, Identifiable, Equatable {
    var id: String { url.absoluteString }
    let url: URL
    let title: String
    let lastOpenedDate: Date
    
    enum CodingKeys: String, CodingKey {
        case url, title, lastOpenedDate
    }
    
    init(url: URL, title: String, lastOpenedDate: Date) {
        self.url = url
        self.title = title
        self.lastOpenedDate = lastOpenedDate
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
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url.absoluteString, forKey: .url)
        try container.encode(title, forKey: .title)
        try container.encode(lastOpenedDate, forKey: .lastOpenedDate)
    }
    
    static func == (lhs: RecentDocument, rhs: RecentDocument) -> Bool {
        return lhs.url == rhs.url
    }
} 