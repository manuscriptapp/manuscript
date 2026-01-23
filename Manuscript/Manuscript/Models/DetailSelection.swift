import Foundation
import SwiftUI

// Define selection type for navigation links
enum DetailSelection: Hashable, Identifiable {
    var id: String {
        switch self {
        case .projectInfo: return "projectInfo"
        case .characters: return "characters"
        case .locations: return "locations"
        case .worldMap: return "worldMap"
        case .writingHistory: return "writingHistory"
        case .folder(let folder): return "folder-\(folder.id)"
        case .document(let document): return "document-\(document.id)"
        case .character(let character): return "character-\(character.id)"
        case .location(let location): return "location-\(location.id)"
        }
    }

    case projectInfo
    case characters
    case locations
    case worldMap
    case writingHistory
    case folder(ManuscriptFolder)
    case document(ManuscriptDocument.Document)
    case character(ManuscriptCharacter)
    case location(ManuscriptLocation)
    
    // Custom Hashable implementation
    func hash(into hasher: inout Hasher) {
        switch self {
        case .projectInfo:
            hasher.combine(0) // Use a unique value for each case
        case .characters:
            hasher.combine(1)
        case .locations:
            hasher.combine(2)
        case .worldMap:
            hasher.combine(3)
        case .writingHistory:
            hasher.combine(4)
        case .folder(let folder):
            hasher.combine(5)
            hasher.combine(folder.id)
        case .document(let document):
            hasher.combine(6)
            hasher.combine(document.id)
        case .character(let character):
            hasher.combine(7)
            hasher.combine(character.id)
        case .location(let location):
            hasher.combine(8)
            hasher.combine(location.id)
        }
    }
    
    // Custom Equatable implementation
    static func == (lhs: DetailSelection, rhs: DetailSelection) -> Bool {
        switch (lhs, rhs) {
        case (.projectInfo, .projectInfo):
            return true
        case (.characters, .characters):
            return true
        case (.locations, .locations):
            return true
        case (.worldMap, .worldMap):
            return true
        case (.writingHistory, .writingHistory):
            return true
        case (.folder(let f1), .folder(let f2)):
            return f1.id == f2.id
        case (.document(let d1), .document(let d2)):
            return d1.id == d2.id
        case (.character(let c1), .character(let c2)):
            return c1.id == c2.id
        case (.location(let l1), .location(let l2)):
            return l1.id == l2.id
        default:
            return false
        }
    }
} 