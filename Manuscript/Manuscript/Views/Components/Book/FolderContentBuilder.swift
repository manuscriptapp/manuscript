import SwiftUI
import SwiftData

struct FolderContentBuilder {
    let document: ManuscriptDocument
    let manuscriptViewModel: ManuscriptViewModel
    
    enum TreeItem: Identifiable, Hashable {
        case folder(ManuscriptFolder, children: [TreeItem])
        case document(ManuscriptDocument.Document)
        
        var id: UUID {
            switch self {
            case .folder(let folder, _):
                return folder.id
            case .document(let document):
                return document.id
            }
        }
        
        var title: String {
            switch self {
            case .folder(let folder, _):
                return folder.title
            case .document(let document):
                return document.title
            }
        }
        
        var children: [TreeItem]? {
            switch self {
            case .folder(_, let children):
                return children.isEmpty ? nil : children
            case .document:
                return nil
            }
        }
        
        var documentCount: Int {
            switch self {
            case .folder(_, let children):
                return children.reduce(0) { count, child in
                    switch child {
                    case .document:
                        return count + 1
                    case .folder:
                        return count + child.documentCount
                    }
                }
            case .document:
                return 1
            }
        }
        
        static func == (lhs: TreeItem, rhs: TreeItem) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        var isFolder: Bool {
            if case .folder = self {
                return true
            }
            return false
        }
        
        var asFolder: (ManuscriptFolder, [TreeItem])? {
            if case .folder(let folder, let children) = self {
                return (folder, children)
            }
            return nil
        }
        
        var asDocument: ManuscriptDocument.Document? {
            if case .document(let document) = self {
                return document
            }
            return nil
        }
    }
    
    func buildTree(from folder: ManuscriptFolder) -> TreeItem {
        // Create a dictionary to track visited folders to prevent cycles
        var visitedFolders: Set<UUID> = []
        return buildTreeSafely(from: folder, visited: &visitedFolders)
    }
    
    private func buildTreeSafely(from folder: ManuscriptFolder, visited: inout Set<UUID>) -> TreeItem {
        // Add current folder to visited set
        visited.insert(folder.id)
        
        // Sort subfolders
        let sortedSubfolders = folder.subfolders.sorted { folder1, folder2 in
            if folder1.order != folder2.order {
                return folder1.order < folder2.order
            }
            return folder1.title < folder2.title
        }
        
        // Sort documents by order first, then by title
        let sortedDocuments = folder.documents.sorted { (doc1, doc2) in
            if doc1.order != doc2.order {
                return doc1.order < doc2.order
            }
            return doc1.title < doc2.title
        }
        
        // Build children array combining folders and documents
        var children: [TreeItem] = []
        
        // Add sorted subfolders first, but only if they haven't been visited
        children.append(contentsOf: sortedSubfolders.compactMap { subfolder in
            guard !visited.contains(subfolder.id) else { return nil }
            return buildTreeSafely(from: subfolder, visited: &visited)
        })
        
        // Add sorted documents
        children.append(contentsOf: sortedDocuments.map { document in
            TreeItem.document(document)
        })
        
        return .folder(folder, children: children)
    }
}

