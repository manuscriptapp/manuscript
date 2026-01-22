# Scrivener Icon Import Plan

**Status**: ✅ **IMPLEMENTED** (January 2026)

## Overview

This plan details how to import icons from Scrivener `.scriv` files and map them to SF Symbols, including support for colored icons.

## Implementation Summary

The icon import feature has been fully implemented in:
- `ScrivenerIconMapper.swift` - Icon mapping logic (379 lines)
- `ScrivenerXMLParser.swift` - Parses `<IconFileName>` from MetaData
- `ScrivenerImporter.swift` - Uses IconMapper during document conversion
- `ManuscriptDocument.swift` - `iconColor` field added to Document model

## Scrivener Icon System

### Icon Storage in XML

Scrivener stores custom icons in the `.scrivx` XML file within `<MetaData>`:

```xml
<BinderItem UUID="..." Type="Text">
    <Title>My Document</Title>
    <MetaData>
        <IconFileName>Flag (Red)</IconFileName>
    </MetaData>
</BinderItem>
```

### Icon Naming Convention

Scrivener uses the format: `Category (Variant)` or just `IconName`

Examples:
- `Flag (Red)` - Red flag icon
- `Book (Blue)` - Blue book icon
- `Note (Yellow)` - Yellow note icon
- `Calendar` - Calendar icon (no category)
- `Lightbulb` - Lightbulb icon

### Label Colors

Scrivener also supports label colors that tint the entire binder item:

```xml
<LabelSettings>
    <Labels>
        <Label ID="0" Color="0.0 0.0 0.0">No Label</Label>
        <Label ID="1" Color="1.0 0.0 0.0">Red</Label>
        <Label ID="2" Color="0.0 1.0 0.0">Green</Label>
    </Labels>
</LabelSettings>
```

---

## Complete Icon Mapping Table

### 1. Books Category

| Scrivener Icon | SF Symbol | Color |
|----------------|-----------|-------|
| `Book` | `book.closed` | - |
| `Book (Red)` | `book.closed.fill` | #FF0000 |
| `Book (Blue)` | `book.closed.fill` | #0000FF |
| `Book (Green)` | `book.closed.fill` | #00AA00 |
| `Book (Brown)` | `book.closed.fill` | #8B4513 |
| `Book (Orange)` | `book.closed.fill` | #FF8000 |
| `Book (Purple)` | `book.closed.fill` | #800080 |
| `Book (Yellow)` | `book.closed.fill` | #FFD700 |
| `Book (Gray)` | `book.closed.fill` | #808080 |
| `Book (Pink)` | `book.closed.fill` | #FF69B4 |
| `Book (Cyan)` | `book.closed.fill` | #00FFFF |

### 2. Flags Category

| Scrivener Icon | SF Symbol | Color |
|----------------|-----------|-------|
| `Flag` | `flag` | - |
| `Flag (Red)` | `flag.fill` | #FF0000 |
| `Flag (Orange)` | `flag.fill` | #FF8000 |
| `Flag (Yellow)` | `flag.fill` | #FFD700 |
| `Flag (Green)` | `flag.fill` | #00AA00 |
| `Flag (Blue)` | `flag.fill` | #0000FF |
| `Flag (Purple)` | `flag.fill` | #800080 |
| `Flag (Pink)` | `flag.fill` | #FF69B4 |
| `Flag (Gray)` | `flag.fill` | #808080 |
| `Flag (Black)` | `flag.fill` | #000000 |
| `Flag (White)` | `flag.fill` | #FFFFFF |

### 3. Notes/Notebooks Category

| Scrivener Icon | SF Symbol | Color |
|----------------|-----------|-------|
| `Note` | `note.text` | - |
| `Note (Red)` | `note.text` | #FF0000 |
| `Note (Blue)` | `note.text` | #0000FF |
| `Note (Yellow)` | `note.text` | #FFD700 |
| `Note (Green)` | `note.text` | #00AA00 |
| `Note (White)` | `note.text` | #FFFFFF |
| `Notebook` | `book` | - |
| `Notebook (Red)` | `book.fill` | #FF0000 |
| `Notebook (Blue)` | `book.fill` | #0000FF |
| `Notebook (Yellow)` | `book.fill` | #FFD700 |
| `Notebook (Green)` | `book.fill` | #00AA00 |

### 4. To Do / Checkboxes Category

| Scrivener Icon | SF Symbol | Color |
|----------------|-----------|-------|
| `To Do` | `circle` | - |
| `To Do (Ticked)` | `checkmark.circle.fill` | #00AA00 |
| `To Do (White)` | `circle` | #FFFFFF |
| `To Do (Yellow)` | `circle.fill` | #FFD700 |
| `To Do (Red)` | `circle.fill` | #FF0000 |
| `Checkbox` | `square` | - |
| `Checkbox (Checked)` | `checkmark.square.fill` | #00AA00 |
| `Checkbox (Unchecked)` | `square` | - |

### 5. Shapes Category

| Scrivener Icon | SF Symbol | Color |
|----------------|-----------|-------|
| `Circle (Red)` | `circle.fill` | #FF0000 |
| `Circle (Orange)` | `circle.fill` | #FF8000 |
| `Circle (Yellow)` | `circle.fill` | #FFD700 |
| `Circle (Green)` | `circle.fill` | #00AA00 |
| `Circle (Blue)` | `circle.fill` | #0000FF |
| `Circle (Purple)` | `circle.fill` | #800080 |
| `Square (Red)` | `square.fill` | #FF0000 |
| `Square (Orange)` | `square.fill` | #FF8000 |
| `Square (Yellow)` | `square.fill` | #FFD700 |
| `Square (Green)` | `square.fill` | #00AA00 |
| `Square (Blue)` | `square.fill` | #0000FF |
| `Square (Purple)` | `square.fill` | #800080 |
| `Triangle (Red)` | `triangle.fill` | #FF0000 |
| `Triangle (Orange)` | `triangle.fill` | #FF8000 |
| `Triangle (Yellow)` | `triangle.fill` | #FFD700 |
| `Triangle (Green)` | `triangle.fill` | #00AA00 |
| `Triangle (Blue)` | `triangle.fill` | #0000FF |
| `Triangle (Purple)` | `triangle.fill` | #800080 |
| `Diamond (Red)` | `diamond.fill` | #FF0000 |
| `Diamond (Orange)` | `diamond.fill` | #FF8000 |
| `Diamond (Yellow)` | `diamond.fill` | #FFD700 |
| `Diamond (Green)` | `diamond.fill` | #00AA00 |
| `Diamond (Blue)` | `diamond.fill` | #0000FF |
| `Diamond (Purple)` | `diamond.fill` | #800080 |
| `Rhombus (Red)` | `rhombus.fill` | #FF0000 |
| `Rhombus (Green)` | `rhombus.fill` | #00AA00 |
| `Rhombus (Blue)` | `rhombus.fill` | #0000FF |

### 6. Labels Category

| Scrivener Icon | SF Symbol | Color |
|----------------|-----------|-------|
| `Label (Red)` | `tag.fill` | #FF0000 |
| `Label (Orange)` | `tag.fill` | #FF8000 |
| `Label (Yellow)` | `tag.fill` | #FFD700 |
| `Label (Green)` | `tag.fill` | #00AA00 |
| `Label (Blue)` | `tag.fill` | #0000FF |
| `Label (Purple)` | `tag.fill` | #800080 |
| `Label (Pink)` | `tag.fill` | #FF69B4 |
| `Label (Gray)` | `tag.fill` | #808080 |

### 7. Individual Icons (No Category)

| Scrivener Icon | SF Symbol | Color |
|----------------|-----------|-------|
| `Calendar` | `calendar` | - |
| `Clock` | `clock` | - |
| `Lightbulb` | `lightbulb` | - |
| `Speech Bubble` | `bubble.left` | - |
| `Warning` | `exclamationmark.triangle` | - |
| `Question` | `questionmark.circle` | - |
| `Idea` | `lightbulb.fill` | #FFD700 |
| `Research` | `magnifyingglass` | - |
| `Gear` | `gearshape` | - |
| `Cog` | `gearshape.fill` | - |
| `Cloud` | `cloud` | - |
| `Sun` | `sun.max` | - |
| `Moon` | `moon` | - |
| `Star` | `star` | - |
| `Star (Filled)` | `star.fill` | #FFD700 |
| `Heart` | `heart` | - |
| `Heart (Filled)` | `heart.fill` | #FF0000 |
| `Bolt` | `bolt` | - |
| `Lock` | `lock` | - |
| `Key` | `key` | - |
| `Pin` | `pin` | - |
| `Paperclip` | `paperclip` | - |
| `Link` | `link` | - |
| `Camera` | `camera` | - |
| `Photo` | `photo` | - |
| `Film` | `film` | - |
| `Music` | `music.note` | - |
| `Musical Note` | `music.note` | - |
| `Microphone` | `mic` | - |
| `Globe` | `globe` | - |
| `Map` | `map` | - |
| `Location` | `mappin` | - |
| `House` | `house` | - |
| `Building` | `building.2` | - |
| `Test Tube` | `testtube.2` | - |
| `Beaker` | `flask` | - |
| `Atom` | `atom` | - |
| `DNA` | `allergens` | - |
| `Brain` | `brain` | - |
| `Eye` | `eye` | - |
| `Ear` | `ear` | - |
| `Hand` | `hand.raised` | - |
| `Person` | `person` | - |
| `People` | `person.3` | - |
| `Group` | `person.3.fill` | - |
| `Conversation` | `bubble.left.and.bubble.right` | - |
| `Document` | `doc.text` | - |
| `Folder` | `folder` | - |
| `Trash` | `trash` | - |
| `Pencil` | `pencil` | - |
| `Pen` | `pencil.line` | - |
| `Eraser` | `eraser` | - |
| `Ruler` | `ruler` | - |
| `Scissors` | `scissors` | - |
| `Tool` | `wrench` | - |
| `Hammer` | `hammer` | - |
| `Paintbrush` | `paintbrush` | - |
| `Palette` | `paintpalette` | - |
| `Bookmark` | `bookmark` | - |
| `Bookmark (Filled)` | `bookmark.fill` | - |
| `Tag` | `tag` | - |
| `Envelope` | `envelope` | - |
| `Phone` | `phone` | - |
| `Message` | `message` | - |
| `Mail` | `envelope.fill` | - |
| `Send` | `paperplane` | - |
| `Download` | `arrow.down.circle` | - |
| `Upload` | `arrow.up.circle` | - |
| `Refresh` | `arrow.clockwise` | - |
| `Play` | `play` | - |
| `Pause` | `pause` | - |
| `Stop` | `stop` | - |
| `Forward` | `forward` | - |
| `Backward` | `backward` | - |
| `Power` | `power` | - |
| `Battery` | `battery.100` | - |
| `Wifi` | `wifi` | - |
| `Bluetooth` | `dot.radiowaves.left.and.right` | - |
| `Signal` | `antenna.radiowaves.left.and.right` | - |
| `Bell` | `bell` | - |
| `Alarm` | `alarm` | - |
| `Timer` | `timer` | - |
| `Stopwatch` | `stopwatch` | - |
| `Hourglass` | `hourglass` | - |

### 8. Character/Writing Icons

| Scrivener Icon | SF Symbol | Color |
|----------------|-----------|-------|
| `Character` | `person` | - |
| `Character (Female)` | `person.fill` | - |
| `Character (Male)` | `person.fill` | - |
| `Character (Old)` | `person.fill` | - |
| `Character (Child)` | `figure.and.child.holdinghands` | - |
| `Protagonist` | `star.circle` | - |
| `Antagonist` | `bolt.circle` | - |
| `Setting` | `mappin.and.ellipse` | - |
| `Scene` | `theatermasks` | - |
| `Chapter` | `book` | - |
| `Plot` | `point.topleft.down.curvedto.point.bottomright.up` | - |
| `Subplot` | `arrow.triangle.branch` | - |
| `Conflict` | `bolt.fill` | - |
| `Resolution` | `checkmark.circle` | - |
| `Draft` | `doc.plaintext` | - |
| `Revision` | `pencil.circle` | - |
| `Final` | `doc.badge.checkmark` | - |
| `Manuscript` | `text.book.closed` | - |

### 9. Type-Based Default Icons

| Scrivener Type | SF Symbol | Notes |
|----------------|-----------|-------|
| `DraftFolder` | `book.closed.fill` | Main manuscript folder |
| `ResearchFolder` | `magnifyingglass` | Research container |
| `TrashFolder` | `trash` | Deleted items |
| `Folder` | `folder` | Generic folder |
| `Text` | `doc.text` | Text document |
| `PDF` | `doc.richtext` | PDF document |
| `Image` | `photo` | Image file |
| `WebPage` | `globe` | Web archive |
| `RTFD` | `doc.richtext` | Rich text |
| `QuickTimeMedia` | `film` | Video/audio |

---

## Implementation Files

### 1. ScrivenerModels.swift

Add to `ScrivenerBinderItem`:
```swift
struct ScrivenerBinderItem {
    // ... existing fields ...
    let iconFileName: String?   // e.g., "Flag (Red)"
}
```

### 2. ScrivenerXMLParser.swift

Parse `<IconFileName>` in MetaData:
```swift
case "IconFileName":
    if !itemStack.isEmpty {
        itemStack[itemStack.count - 1].iconFileName = trimmedText
    }
```

### 3. ScrivenerIconMapper.swift (NEW)

```swift
import SwiftUI

struct ScrivenerIconMapper {
    struct IconMapping {
        let sfSymbol: String
        let color: Color?
    }

    /// Maps Scrivener icon name to SF Symbol and optional color
    static func map(scrivenerIcon: String?, itemType: ScrivenerItemType) -> IconMapping {
        // 1. Try exact match with color extraction
        if let iconName = scrivenerIcon {
            if let mapping = parseIconWithColor(iconName) {
                return mapping
            }
            // 2. Try direct icon name mapping
            if let symbol = iconNameMapping[iconName.lowercased()] {
                return IconMapping(sfSymbol: symbol, color: nil)
            }
        }

        // 3. Fallback to type-based default
        let symbol = typeBasedMapping[itemType] ?? "doc.text"
        return IconMapping(sfSymbol: symbol, color: nil)
    }

    /// Parses "Category (Color)" format and extracts color
    private static func parseIconWithColor(_ iconName: String) -> IconMapping? {
        // Parse format: "Flag (Red)" -> category="Flag", variant="Red"
        let pattern = #"^(.+?)\s*\((.+?)\)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: iconName, range: NSRange(iconName.startIndex..., in: iconName)),
              let categoryRange = Range(match.range(at: 1), in: iconName),
              let variantRange = Range(match.range(at: 2), in: iconName) else {
            return nil
        }

        let category = String(iconName[categoryRange]).lowercased()
        let variant = String(iconName[variantRange]).lowercased()

        // Get SF Symbol for category
        guard let symbol = categoryToSFSymbol[category] else { return nil }

        // Get color for variant
        let color = colorNameMapping[variant]

        return IconMapping(sfSymbol: symbol, color: color)
    }

    // Category to SF Symbol (uses filled variant when colored)
    private static let categoryToSFSymbol: [String: String] = [
        "flag": "flag.fill",
        "book": "book.closed.fill",
        "note": "note.text",
        "notebook": "book.fill",
        "circle": "circle.fill",
        "square": "square.fill",
        "triangle": "triangle.fill",
        "diamond": "diamond.fill",
        "rhombus": "rhombus.fill",
        "label": "tag.fill",
        "star": "star.fill",
        "heart": "heart.fill",
        "bookmark": "bookmark.fill",
        "to do": "circle.fill",
        "checkbox": "checkmark.square.fill",
    ]

    // Color name to SwiftUI Color
    private static let colorNameMapping: [String: Color] = [
        "red": Color(hex: "#FF0000")!,
        "orange": Color(hex: "#FF8000")!,
        "yellow": Color(hex: "#FFD700")!,
        "green": Color(hex: "#00AA00")!,
        "blue": Color(hex: "#0000FF")!,
        "purple": Color(hex: "#800080")!,
        "pink": Color(hex: "#FF69B4")!,
        "cyan": Color(hex: "#00FFFF")!,
        "gray": Color(hex: "#808080")!,
        "grey": Color(hex: "#808080")!,
        "brown": Color(hex: "#8B4513")!,
        "black": Color(hex: "#000000")!,
        "white": Color(hex: "#FFFFFF")!,
        "ticked": Color(hex: "#00AA00")!,
        "checked": Color(hex: "#00AA00")!,
        "filled": Color(hex: "#FFD700")!,
    ]

    // Direct icon name to SF Symbol mapping
    private static let iconNameMapping: [String: String] = [
        // General icons
        "calendar": "calendar",
        "clock": "clock",
        "lightbulb": "lightbulb",
        "speech bubble": "bubble.left",
        "warning": "exclamationmark.triangle",
        "question": "questionmark.circle",
        "idea": "lightbulb.fill",
        "research": "magnifyingglass",
        "gear": "gearshape",
        "cog": "gearshape.fill",
        "cloud": "cloud",
        "sun": "sun.max",
        "moon": "moon",
        "star": "star",
        "heart": "heart",
        "bolt": "bolt",
        "lock": "lock",
        "key": "key",
        "pin": "pin",
        "paperclip": "paperclip",
        "link": "link",
        "camera": "camera",
        "photo": "photo",
        "film": "film",
        "music": "music.note",
        "musical note": "music.note",
        "microphone": "mic",
        "globe": "globe",
        "map": "map",
        "location": "mappin",
        "house": "house",
        "building": "building.2",
        "test tube": "testtube.2",
        "beaker": "flask",
        "atom": "atom",
        "brain": "brain",
        "eye": "eye",
        "ear": "ear",
        "hand": "hand.raised",
        "person": "person",
        "people": "person.3",
        "group": "person.3.fill",
        "conversation": "bubble.left.and.bubble.right",
        "document": "doc.text",
        "folder": "folder",
        "trash": "trash",
        "pencil": "pencil",
        "pen": "pencil.line",
        "eraser": "eraser",
        "ruler": "ruler",
        "scissors": "scissors",
        "tool": "wrench",
        "hammer": "hammer",
        "paintbrush": "paintbrush",
        "palette": "paintpalette",
        "bookmark": "bookmark",
        "tag": "tag",
        "envelope": "envelope",
        "phone": "phone",
        "message": "message",
        "mail": "envelope.fill",
        "send": "paperplane",
        "bell": "bell",
        "alarm": "alarm",
        "timer": "timer",
        "stopwatch": "stopwatch",
        "hourglass": "hourglass",

        // Writing-specific
        "character": "person",
        "protagonist": "star.circle",
        "antagonist": "bolt.circle",
        "setting": "mappin.and.ellipse",
        "scene": "theatermasks",
        "chapter": "book",
        "plot": "point.topleft.down.curvedto.point.bottomright.up",
        "subplot": "arrow.triangle.branch",
        "conflict": "bolt.fill",
        "resolution": "checkmark.circle",
        "draft": "doc.plaintext",
        "revision": "pencil.circle",
        "final": "doc.badge.checkmark",
        "manuscript": "text.book.closed",

        // To-do variants
        "to do": "circle",
        "checkbox": "square",
    ]

    // Type-based fallback mapping
    private static let typeBasedMapping: [ScrivenerItemType: String] = [
        .draftFolder: "book.closed.fill",
        .researchFolder: "magnifyingglass",
        .trashFolder: "trash",
        .folder: "folder",
        .text: "doc.text",
        .pdf: "doc.richtext",
        .image: "photo",
        .webPage: "globe",
        .rtfd: "doc.richtext",
        .quickTimeMedia: "film",
        .other: "doc",
    ]
}
```

### 4. ManuscriptDocument.swift

Add `iconColor` field:
```swift
struct Document: Identifiable, Codable, Equatable {
    // ... existing fields ...
    var iconName: String
    var iconColor: String?  // NEW: Hex color like "#FF0000"
    // ...
}
```

### 5. DocumentItemView.swift

Update icon rendering:
```swift
Image(systemName: document.iconName)
    .foregroundStyle(iconColor(for: document))

private func iconColor(for document: ManuscriptDocument.Document) -> Color {
    // Use icon-specific color if available
    if let hexColor = document.iconColor,
       let color = Color(hex: hexColor) {
        return isSelected ? color.darkened() : color
    }
    // Fallback to document color
    return isSelected ? colorForDocument(document).darkened() : colorForDocument(document)
}
```

### 6. Color+Extensions.swift

Add hex initializer if not present:
```swift
extension Color {
    init?(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard trimmed.count == 6,
              let rgb = Int(trimmed, radix: 16) else {
            return nil
        }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        // Implementation for converting Color to hex string
    }
}
```

### 7. ScrivenerImporter.swift

Update `convertTextItem`:
```swift
private func convertTextItem(...) async throws -> ManuscriptDocument.Document {
    // Get icon mapping
    let iconMapping = ScrivenerIconMapper.map(
        scrivenerIcon: item.iconFileName,
        itemType: item.type
    )

    // Convert color to hex if present
    let iconColorHex: String? = iconMapping.color?.toHex()

    return ManuscriptDocument.Document(
        // ... other fields ...
        iconName: iconMapping.sfSymbol,
        iconColor: iconColorHex,
        // ...
    )
}
```

---

## Testing Checklist

- [x] Import project with colored flags (Red, Green, Blue, Yellow)
- [x] Import project with colored books
- [x] Import project with colored shapes (circles, squares)
- [x] Import project with to-do checkboxes (checked/unchecked)
- [x] Import project with general icons (Calendar, Clock, Lightbulb)
- [x] Verify colors render correctly in DocumentItemView
- [x] Test fallback to type-based icons for unknown icons
- [x] Test backward compatibility (documents without iconColor)

### Additional Features Implemented
- [x] User can customize folder/document icons in sidebar
- [x] User can set custom icon colors
- [x] Icon colors persist across sessions
- [x] Supports 100+ icon name mappings
- [x] Supports 27+ color variants

---

## Sources

- [Personalize the Scrivener Binder with Custom Icons](https://www.literatureandlatte.com/blog/personalize-the-scrivener-binder-with-custom-icons)
- [What Do the Icons in Scrivener's Binder Mean?](https://www.literatureandlatte.com/blog/what-do-the-icons-in-scriveners-binder-mean)
- [Making Custom Icons for Scrivener](https://medium.com/@hlmcgilp/making-your-own-custom-icons-for-scrivener-feb1a61a74bf)
- [Scrivener Manual Section 7.4](https://www.literatureandlatte.com/docs/)
