import Foundation

extension Folder {
    var totalDocumentCount: Int {
        let documentsInFolder = documents?.count ?? 0
        let documentsInSubfolders = subfolders?.reduce(0) { count, subfolder in
            count + subfolder.totalDocumentCount
        } ?? 0
        return documentsInFolder + documentsInSubfolders
    }
} 