import SwiftUI
import UniformTypeIdentifiers

/// Type of item being dragged in the sidebar
enum SidebarItemType: String, Codable {
    case document
    case folder
}

/// Represents a sidebar item (document or folder) that can be dragged and dropped
struct DraggableSidebarItem: Codable, Transferable {
    let id: UUID
    let itemType: SidebarItemType

    /// String representation for drag-and-drop: "type:uuid"
    var stringValue: String {
        "\(itemType.rawValue):\(id.uuidString)"
    }

    /// Initialize from string representation
    init?(from string: String) {
        let parts = string.split(separator: ":")
        guard parts.count == 2,
              let type = SidebarItemType(rawValue: String(parts[0])),
              let uuid = UUID(uuidString: String(parts[1])) else {
            return nil
        }
        self.itemType = type
        self.id = uuid
    }

    init(id: UUID, itemType: SidebarItemType) {
        self.id = id
        self.itemType = itemType
    }

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.stringValue) { string in
            guard let item = DraggableSidebarItem(from: string) else {
                throw CocoaError(.coderValueNotFound)
            }
            return item
        }
    }
}
