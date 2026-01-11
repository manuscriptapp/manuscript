import Foundation
import SwiftUI

// Define selection type for navigation links
enum DetailSelection: Hashable {
    case projectInfo
    case characters
    case locations
    case folder(LiteratiFolder)
    case document(LiteratiDocument.Document)
    case character(LiteratiCharacter)
    case location(LiteratiLocation)
    
    // Custom Hashable implementation
    func hash(into hasher: inout Hasher) {
        switch self {
        case .projectInfo:
            hasher.combine(0) // Use a unique value for each case
        case .characters:
            hasher.combine(1)
        case .locations:
            hasher.combine(2)
        case .folder(let folder):
            hasher.combine(3)
            hasher.combine(folder.id)
        case .document(let document):
            hasher.combine(4)
            hasher.combine(document.id)
        case .character(let character):
            hasher.combine(5)
            hasher.combine(character.id)
        case .location(let location):
            hasher.combine(6)
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