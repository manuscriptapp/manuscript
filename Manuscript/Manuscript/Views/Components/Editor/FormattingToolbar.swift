import SwiftUI
import RichTextKit

/// A formatting toolbar that works on both iOS and macOS
/// Provides font selection, size, and basic text styling controls
struct FormattingToolbar: View {
    @ObservedObject var context: RichTextContext
    @State private var selectedLineSpacing: LineSpacingOption = .single
    @State private var selectedHighlightColor: HighlightColor = .none

    /// Converts a PostScript font name (e.g., "Palatino-Roman") to a family name (e.g., "Palatino")
    private var displayFontName: String {
        let fontName = context.fontName
        guard !fontName.isEmpty else { return "Palatino" }

        #if os(macOS)
        // Try to get the family name from the font
        if let font = NSFont(name: fontName, size: 12) {
            return font.familyName ?? fontName
        }
        #else
        if let font = UIFont(name: fontName, size: 12) {
            return font.familyName
        }
        #endif

        // Fallback: split on hyphen and take first part
        if let hyphenIndex = fontName.firstIndex(of: "-") {
            return String(fontName[..<hyphenIndex])
        }
        return fontName
    }

    var body: some View {
        #if os(macOS)
        macOSToolbar
        #else
        EmptyView() // iOS uses keyboard toolbars instead
        #endif
    }

    // MARK: - Shared Types

    private enum LineSpacingOption: String, CaseIterable {
        case single = "1"
        case onePointFifteen = "1.15"
        case onePointFive = "1.5"
        case double = "2"

        var multiplier: CGFloat {
            switch self {
            case .single: return 1.0
            case .onePointFifteen: return 1.15
            case .onePointFive: return 1.5
            case .double: return 2.0
            }
        }
    }

    private enum HighlightColor: String, CaseIterable {
        case none = "None"
        case yellow = "Yellow"
        case green = "Green"
        case blue = "Blue"
        case pink = "Pink"
        case orange = "Orange"

        var color: Color? {
            switch self {
            case .none: return nil
            case .yellow: return .yellow.opacity(0.7)
            case .green: return .green.opacity(0.6)
            case .blue: return .blue.opacity(0.5)
            case .pink: return .pink.opacity(0.6)
            case .orange: return .orange.opacity(0.6)
            }
        }
    }

    // MARK: - macOS Toolbar

    #if os(macOS)
    private let fontSizesMac = [10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72]

    /// Classic literary fonts ideal for prose writing
    private let literaryFonts = [
        "Palatino",
        "Garamond",
        "Baskerville",
        "Georgia",
        "Times New Roman",
        "Hoefler Text",
        "Charter",
        "Cochin",
        "Didot",
        "Bookman Old Style",
        "Cambria"
    ]

    private var macOSToolbar: some View {
        HStack(spacing: 10) {
            // Font family picker
            Menu {
                // Literary fonts section
                ForEach(availableLiteraryFonts, id: \.self) { fontName in
                    Button(fontName) {
                        context.fontName = fontName
                    }
                }

                Divider()

                // All other fonts
                ForEach(availableOtherFonts, id: \.self) { fontName in
                    Button(fontName) {
                        context.fontName = fontName
                    }
                }
            } label: {
                HStack {
                    Text(displayFontName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
            }
            .frame(width: 130)

            // Font size dropdown
            Menu {
                ForEach(fontSizesMac, id: \.self) { size in
                    Button {
                        context.fontSize = CGFloat(size)
                    } label: {
                        HStack {
                            Text("\(size)")
                            if Int(context.fontSize) == size {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(Int(context.fontSize))")
                        .monospacedDigit()
                        .frame(width: 20)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
            }

            Divider()
                .frame(height: 20)

            // Style toggles (Bold, Italic, Underline, Strikethrough)
            RichTextStyle.ToggleGroup(context: context)

            Divider()
                .frame(height: 20)

            // Text alignment (no label)
            RichTextAlignment.Picker(selection: $context.textAlignment)
                .labelsHidden()

            Divider()
                .frame(height: 20)

            // Line spacing dropdown
            Menu {
                ForEach(LineSpacingOption.allCases, id: \.self) { option in
                    Button {
                        selectedLineSpacing = option
                        applyLineSpacing(option.multiplier)
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if selectedLineSpacing == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "text.line.first.and.arrowtriangle.forward")
                    .font(.body)
            }
            .help("Line Spacing")

            // Text highlight color dropdown
            Menu {
                ForEach(HighlightColor.allCases, id: \.self) { option in
                    Button {
                        selectedHighlightColor = option
                        applyHighlightColor(option.color)
                    } label: {
                        HStack {
                            if let color = option.color {
                                Circle()
                                    .fill(color)
                                    .frame(width: 12, height: 12)
                            }
                            Text(option.rawValue)
                            if selectedHighlightColor == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "highlighter")
                    .font(.body)
            }
            .help("Text Highlight")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// Literary fonts that are available on this system
    private var availableLiteraryFonts: [String] {
        let allFonts = NSFontManager.shared.availableFontFamilies
        return literaryFonts.filter { allFonts.contains($0) }
    }

    /// All other fonts (excluding literary fonts)
    private var availableOtherFonts: [String] {
        let allFonts = NSFontManager.shared.availableFontFamilies.sorted()
        return allFonts.filter { !literaryFonts.contains($0) }
    }

    private func applyLineSpacing(_ multiplier: CGFloat) {
        let attrString = context.attributedString
        let mutable = NSMutableAttributedString(attributedString: attrString)
        let range = context.selectedRange.length > 0
            ? context.selectedRange
            : NSRange(location: 0, length: mutable.length)

        guard range.location != NSNotFound, range.length > 0 || mutable.length > 0 else { return }

        let effectiveRange = range.length > 0 ? range : NSRange(location: 0, length: mutable.length)

        mutable.enumerateAttribute(.paragraphStyle, in: effectiveRange, options: []) { value, subRange, _ in
            let existingStyle = (value as? NSParagraphStyle) ?? NSParagraphStyle.default
            let newStyle = existingStyle.mutableCopy() as! NSMutableParagraphStyle
            newStyle.lineSpacing = multiplier * 6
            mutable.addAttribute(.paragraphStyle, value: newStyle, range: subRange)
        }

        // If no paragraph style was found, apply to entire range
        if mutable.attribute(.paragraphStyle, at: effectiveRange.location, effectiveRange: nil) == nil {
            let newStyle = NSMutableParagraphStyle()
            newStyle.lineSpacing = multiplier * 6
            mutable.addAttribute(.paragraphStyle, value: newStyle, range: effectiveRange)
        }

        context.setAttributedString(to: mutable)
    }

    private func applyHighlightColor(_ color: Color?) {
        let attrString = context.attributedString
        let mutable = NSMutableAttributedString(attributedString: attrString)
        let range = context.selectedRange

        guard range.location != NSNotFound, range.length > 0 else { return }

        if let color = color {
            let nsColor = NSColor(color)
            mutable.addAttribute(.backgroundColor, value: nsColor, range: range)
        } else {
            mutable.removeAttribute(.backgroundColor, range: range)
        }

        context.setAttributedString(to: mutable)
    }
    #endif
}

// MARK: - iOS Keyboard Toolbar View

#if os(iOS)
/// SwiftUI view for keyboard input accessory
struct KeyboardToolbarView: View {
    @ObservedObject var context: RichTextContext

    var body: some View {
        HStack(spacing: 16) {
            // Text style buttons
            Button {
                context.toggleStyle(.bold)
            } label: {
                Image(systemName: "bold")
                    .foregroundStyle(context.hasStyle(.bold) ? Color.accentColor : Color.primary)
            }

            Button {
                context.toggleStyle(.italic)
            } label: {
                Image(systemName: "italic")
                    .foregroundStyle(context.hasStyle(.italic) ? Color.accentColor : Color.primary)
            }

            Button {
                context.toggleStyle(.underlined)
            } label: {
                Image(systemName: "underline")
                    .foregroundStyle(context.hasStyle(.underlined) ? Color.accentColor : Color.primary)
            }

            Divider()
                .frame(height: 24)

            // Text alignment menu
            Menu {
                Button {
                    context.textAlignment = .left
                } label: {
                    Label("Left", systemImage: "text.alignleft")
                }
                Button {
                    context.textAlignment = .center
                } label: {
                    Label("Center", systemImage: "text.aligncenter")
                }
                Button {
                    context.textAlignment = .right
                } label: {
                    Label("Right", systemImage: "text.alignright")
                }
                Button {
                    context.textAlignment = .justified
                } label: {
                    Label("Justified", systemImage: "text.justify")
                }
            } label: {
                Image(systemName: alignmentIcon)
                    .foregroundStyle(Color.primary)
            }

            Spacer()

            // Dismiss keyboard button
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }

    private var alignmentIcon: String {
        switch context.textAlignment {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        case .justified: return "text.justify"
        default: return "text.alignleft"
        }
    }
}
#endif

// MARK: - Preview

#if DEBUG
#Preview("Formatting Toolbar") {
    FormattingToolbar(context: RichTextContext())
        .frame(width: 500)
}
#endif
