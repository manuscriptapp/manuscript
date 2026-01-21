import Foundation
import SwiftUI

/// Maps Scrivener icon names to SF Symbols with optional colors
struct ScrivenerIconMapper {

    // MARK: - Result Type

    /// Result of icon mapping containing SF Symbol name and optional color
    struct IconMapping {
        let sfSymbol: String
        let colorHex: String?

        init(sfSymbol: String, colorHex: String? = nil) {
            self.sfSymbol = sfSymbol
            self.colorHex = colorHex
        }
    }

    // MARK: - Public Methods

    /// Maps a Scrivener icon name to an SF Symbol with optional color
    /// - Parameters:
    ///   - scrivenerIcon: The icon name from Scrivener (e.g., "Flag (Red)")
    ///   - itemType: The Scrivener item type for fallback mapping
    /// - Returns: IconMapping with SF Symbol name and optional hex color
    static func map(scrivenerIcon: String?, itemType: ScrivenerItemType) -> IconMapping {
        // 1. Try to parse "Category (Color)" format
        if let iconName = scrivenerIcon {
            if let mapping = parseIconWithColor(iconName) {
                return mapping
            }

            // 2. Try direct icon name mapping
            let normalized = iconName.lowercased().trimmingCharacters(in: .whitespaces)
            if let symbol = iconNameMapping[normalized] {
                return IconMapping(sfSymbol: symbol)
            }

            // 3. Try partial matching for icon names with variations
            for (key, symbol) in iconNameMapping {
                if normalized.contains(key) || key.contains(normalized) {
                    return IconMapping(sfSymbol: symbol)
                }
            }
        }

        // 4. Fallback to type-based default
        let symbol = typeBasedMapping[itemType] ?? "doc.text"
        return IconMapping(sfSymbol: symbol)
    }

    // MARK: - Private Methods

    /// Parses icon names in "Category (Variant)" format and extracts color
    private static func parseIconWithColor(_ iconName: String) -> IconMapping? {
        // Parse format: "Flag (Red)" -> category="Flag", variant="Red"
        let pattern = #"^(.+?)\s*\((.+?)\)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: iconName, range: NSRange(iconName.startIndex..., in: iconName)),
              let categoryRange = Range(match.range(at: 1), in: iconName),
              let variantRange = Range(match.range(at: 2), in: iconName) else {
            return nil
        }

        let category = String(iconName[categoryRange]).lowercased().trimmingCharacters(in: .whitespaces)
        let variant = String(iconName[variantRange]).lowercased().trimmingCharacters(in: .whitespaces)

        // Get SF Symbol for category (use filled variant for colored icons)
        guard let symbolInfo = categoryToSFSymbol[category] else { return nil }

        // Determine which symbol to use based on whether there's a color
        let symbol: String
        let colorHex: String?

        if let color = colorNameMapping[variant] {
            // Has color - use filled variant
            symbol = symbolInfo.filled
            colorHex = color
        } else if variant == "ticked" || variant == "checked" {
            // Special case for checkmarks
            symbol = symbolInfo.filled
            colorHex = "#00AA00"  // Green for checked
        } else if variant == "unchecked" || variant == "empty" {
            // Special case for unchecked
            symbol = symbolInfo.outline
            colorHex = nil
        } else {
            // Unknown variant - use outline without color
            symbol = symbolInfo.outline
            colorHex = nil
        }

        return IconMapping(sfSymbol: symbol, colorHex: colorHex)
    }

    // MARK: - Mapping Tables

    /// Symbol pair for outline and filled variants
    private struct SymbolPair {
        let outline: String
        let filled: String

        init(_ outline: String, _ filled: String) {
            self.outline = outline
            self.filled = filled
        }

        init(_ both: String) {
            self.outline = both
            self.filled = both
        }
    }

    /// Category to SF Symbol mapping (outline and filled variants)
    private static let categoryToSFSymbol: [String: SymbolPair] = [
        // Basic shapes
        "flag": SymbolPair("flag", "flag.fill"),
        "book": SymbolPair("book.closed", "book.closed.fill"),
        "note": SymbolPair("note.text", "note.text"),
        "notebook": SymbolPair("book", "book.fill"),
        "circle": SymbolPair("circle", "circle.fill"),
        "square": SymbolPair("square", "square.fill"),
        "triangle": SymbolPair("triangle", "triangle.fill"),
        "diamond": SymbolPair("diamond", "diamond.fill"),
        "rhombus": SymbolPair("rhombus", "rhombus.fill"),
        "label": SymbolPair("tag", "tag.fill"),
        "tag": SymbolPair("tag", "tag.fill"),
        "star": SymbolPair("star", "star.fill"),
        "heart": SymbolPair("heart", "heart.fill"),
        "bookmark": SymbolPair("bookmark", "bookmark.fill"),

        // To-do / checkboxes
        "to do": SymbolPair("circle", "checkmark.circle.fill"),
        "todo": SymbolPair("circle", "checkmark.circle.fill"),
        "checkbox": SymbolPair("square", "checkmark.square.fill"),
        "check": SymbolPair("circle", "checkmark.circle.fill"),

        // Document types
        "document": SymbolPair("doc.text", "doc.text.fill"),
        "doc": SymbolPair("doc.text", "doc.text.fill"),
        "folder": SymbolPair("folder", "folder.fill"),
        "text": SymbolPair("doc.text", "doc.text.fill"),

        // People
        "character": SymbolPair("person", "person.fill"),
        "person": SymbolPair("person", "person.fill"),
        "people": SymbolPair("person.3", "person.3.fill"),
        "group": SymbolPair("person.3", "person.3.fill"),

        // Places
        "location": SymbolPair("mappin", "mappin.circle.fill"),
        "place": SymbolPair("mappin", "mappin.circle.fill"),
        "setting": SymbolPair("mappin.and.ellipse", "mappin.and.ellipse"),
        "building": SymbolPair("building.2", "building.2.fill"),
        "house": SymbolPair("house", "house.fill"),

        // Objects
        "lightbulb": SymbolPair("lightbulb", "lightbulb.fill"),
        "idea": SymbolPair("lightbulb", "lightbulb.fill"),
        "gear": SymbolPair("gearshape", "gearshape.fill"),
        "cog": SymbolPair("gearshape", "gearshape.fill"),
        "lock": SymbolPair("lock", "lock.fill"),
        "key": SymbolPair("key", "key.fill"),
        "bell": SymbolPair("bell", "bell.fill"),
        "clock": SymbolPair("clock", "clock.fill"),
        "calendar": SymbolPair("calendar", "calendar"),
        "pin": SymbolPair("pin", "pin.fill"),
        "paperclip": SymbolPair("paperclip", "paperclip"),
        "envelope": SymbolPair("envelope", "envelope.fill"),

        // Media
        "photo": SymbolPair("photo", "photo.fill"),
        "image": SymbolPair("photo", "photo.fill"),
        "camera": SymbolPair("camera", "camera.fill"),
        "film": SymbolPair("film", "film.fill"),
        "music": SymbolPair("music.note", "music.note"),
    ]

    /// Color name to hex color mapping
    private static let colorNameMapping: [String: String] = [
        // Primary colors
        "red": "#FF0000",
        "orange": "#FF8000",
        "yellow": "#FFD700",
        "green": "#00AA00",
        "blue": "#0000FF",
        "purple": "#800080",
        "violet": "#8B00FF",

        // Secondary colors
        "pink": "#FF69B4",
        "cyan": "#00FFFF",
        "teal": "#008080",
        "magenta": "#FF00FF",
        "lime": "#32CD32",
        "indigo": "#4B0082",

        // Neutral colors
        "gray": "#808080",
        "grey": "#808080",
        "brown": "#8B4513",
        "black": "#000000",
        "white": "#FFFFFF",

        // Special variants
        "dark red": "#8B0000",
        "dark green": "#006400",
        "dark blue": "#00008B",
        "light red": "#FF6B6B",
        "light green": "#90EE90",
        "light blue": "#ADD8E6",

        // Status colors
        "ticked": "#00AA00",
        "checked": "#00AA00",
        "done": "#00AA00",
        "filled": "#FFD700",
        "urgent": "#FF0000",
        "important": "#FF8000",
    ]

    /// Direct icon name to SF Symbol mapping
    private static let iconNameMapping: [String: String] = [
        // General icons
        "calendar": "calendar",
        "clock": "clock",
        "lightbulb": "lightbulb",
        "speech bubble": "bubble.left",
        "bubble": "bubble.left",
        "warning": "exclamationmark.triangle",
        "question": "questionmark.circle",
        "idea": "lightbulb.fill",
        "research": "magnifyingglass",
        "search": "magnifyingglass",
        "gear": "gearshape",
        "cog": "gearshape.fill",
        "cloud": "cloud",
        "sun": "sun.max",
        "moon": "moon",
        "star": "star",
        "heart": "heart",
        "bolt": "bolt",
        "lightning": "bolt",
        "lock": "lock",
        "key": "key",
        "pin": "pin",
        "paperclip": "paperclip",
        "link": "link",
        "camera": "camera",
        "photo": "photo",
        "image": "photo",
        "film": "film",
        "video": "film",
        "music": "music.note",
        "musical note": "music.note",
        "microphone": "mic",
        "globe": "globe",
        "world": "globe",
        "map": "map",
        "location": "mappin",
        "house": "house",
        "home": "house",
        "building": "building.2",
        "test tube": "testtube.2",
        "beaker": "flask",
        "flask": "flask",
        "atom": "atom",
        "brain": "brain",
        "eye": "eye",
        "ear": "ear",
        "hand": "hand.raised",
        "person": "person",
        "people": "person.3",
        "group": "person.3.fill",
        "conversation": "bubble.left.and.bubble.right",
        "chat": "bubble.left.and.bubble.right",
        "document": "doc.text",
        "doc": "doc.text",
        "folder": "folder",
        "trash": "trash",
        "pencil": "pencil",
        "pen": "pencil.line",
        "eraser": "eraser",
        "ruler": "ruler",
        "scissors": "scissors",
        "tool": "wrench",
        "wrench": "wrench",
        "hammer": "hammer",
        "paintbrush": "paintbrush",
        "palette": "paintpalette",
        "bookmark": "bookmark",
        "tag": "tag",
        "envelope": "envelope",
        "mail": "envelope.fill",
        "email": "envelope",
        "phone": "phone",
        "message": "message",
        "send": "paperplane",
        "bell": "bell",
        "alarm": "alarm",
        "timer": "timer",
        "stopwatch": "stopwatch",
        "hourglass": "hourglass",

        // Writing-specific icons
        "character": "person",
        "protagonist": "star.circle",
        "antagonist": "bolt.circle",
        "villain": "bolt.circle",
        "hero": "star.circle",
        "setting": "mappin.and.ellipse",
        "scene": "theatermasks",
        "chapter": "book",
        "plot": "point.topleft.down.curvedto.point.bottomright.up",
        "subplot": "arrow.triangle.branch",
        "conflict": "bolt.fill",
        "resolution": "checkmark.circle",
        "climax": "arrow.up.to.line",
        "draft": "doc.plaintext",
        "revision": "pencil.circle",
        "final": "doc.badge.checkmark",
        "manuscript": "text.book.closed",
        "notes": "note.text",
        "note": "note.text",
        "outline": "list.bullet",

        // To-do / status icons
        "to do": "circle",
        "todo": "circle",
        "done": "checkmark.circle.fill",
        "complete": "checkmark.circle.fill",
        "completed": "checkmark.circle.fill",
        "in progress": "clock",
        "pending": "clock",
        "checkbox": "square",
        "checkmark": "checkmark",

        // Flags
        "flag": "flag",

        // Symbols
        "exclamation": "exclamationmark.triangle",
        "important": "exclamationmark.triangle",
        "info": "info.circle",
        "information": "info.circle",
        "help": "questionmark.circle",
        "target": "target",
        "bullseye": "target",
    ]

    /// Type-based fallback mapping for Scrivener item types
    private static let typeBasedMapping: [ScrivenerItemType: String] = [
        .draftFolder: "book.closed.fill",
        .researchFolder: "magnifyingglass",
        .trashFolder: "trash",
        .folder: "folder",
        .text: "doc.text",
        .pdf: "doc.richtext",
        .image: "photo",
        .webPage: "globe",
        .root: "folder",
        .other: "doc",
    ]
}
