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
        iOSToolbar
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

    private var macOSToolbar: some View {
        HStack(spacing: 10) {
            // Font family picker
            Menu {
                ForEach(availableFontsMac, id: \.self) { fontName in
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

    private var availableFontsMac: [String] {
        let commonFonts = ["Palatino", "Georgia", "Times New Roman", "Helvetica", "Arial", "Courier New", "Menlo", "Monaco"]
        let allFonts = NSFontManager.shared.availableFontFamilies.sorted()

        var result: [String] = []
        for font in commonFonts {
            if allFonts.contains(font) {
                result.append(font)
            }
        }
        for font in allFonts {
            if !result.contains(font) {
                result.append(font)
            }
        }
        return result
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

    // MARK: - iOS Toolbar

    #if os(iOS)
    private var iOSToolbar: some View {
        HStack(spacing: 12) {
            // Font family picker (compact - icon only with menu)
            Menu {
                ForEach(availableFonts, id: \.self) { fontName in
                    Button {
                        context.fontName = fontName
                    } label: {
                        HStack {
                            Text(fontName)
                            if context.fontName == fontName {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "textformat")
                    .font(.body)
            }

            // Font size dropdown
            Menu {
                ForEach([10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72], id: \.self) { size in
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
                Text("\(Int(context.fontSize))")
                    .font(.subheadline)
                    .monospacedDigit()
                    .frame(minWidth: 24)
            }

            Divider()
                .frame(height: 20)

            // Style buttons (compact, no labels)
            HStack(spacing: 6) {
                compactStyleButton(style: .bold, icon: "bold")
                compactStyleButton(style: .italic, icon: "italic")
                compactStyleButton(style: .underlined, icon: "underline")
                compactStyleButton(style: .strikethrough, icon: "strikethrough")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func compactStyleButton(style: RichTextStyle, icon: String) -> some View {
        Button {
            context.toggleStyle(style)
        } label: {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(context.hasStyle(style) ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private var availableFonts: [String] {
        // Return common writing fonts first, then all system fonts
        let commonFonts = ["Palatino", "Georgia", "Times New Roman", "Helvetica", "Arial", "Courier New"]
        let allFonts = UIFont.familyNames.sorted()

        // Put common fonts first, then the rest
        var result: [String] = []
        for font in commonFonts {
            if allFonts.contains(font) {
                result.append(font)
            }
        }
        for font in allFonts {
            if !result.contains(font) {
                result.append(font)
            }
        }
        return result
    }
    #endif
}

// MARK: - Formatting Palette (iOS Full Screen Sheet)

#if os(iOS)
/// A full formatting palette for iOS, matching Scrivener's 3-tab design
struct FormattingPalette: View {
    @ObservedObject var context: RichTextContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Style").tag(0)
                    Text("Paragraph").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Tab content
                TabView(selection: $selectedTab) {
                    StyleTabContent(context: context)
                        .tag(0)
                    ParagraphTabContent(context: context)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Format")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Style Tab

private struct StyleTabContent: View {
    @ObservedObject var context: RichTextContext

    private let fontSizes = [10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72]

    var body: some View {
        Form {
            Section("Font") {
                // Font family
                Picker("Family", selection: $context.fontName) {
                    ForEach(availableFonts, id: \.self) { fontName in
                        Text(fontName)
                            .font(.custom(fontName, size: 16))
                            .tag(fontName)
                    }
                }

                // Font size dropdown
                Picker("Size", selection: Binding(
                    get: { Int(context.fontSize) },
                    set: { context.fontSize = CGFloat($0) }
                )) {
                    ForEach(fontSizes, id: \.self) { size in
                        Text("\(size) pt").tag(size)
                    }
                }
            }

            Section("Style") {
                styleToggleRow(style: .bold, label: "Bold", icon: "bold")
                styleToggleRow(style: .italic, label: "Italic", icon: "italic")
                styleToggleRow(style: .underlined, label: "Underline", icon: "underline")
                styleToggleRow(style: .strikethrough, label: "Strikethrough", icon: "strikethrough")
            }

            Section {
                Picker("", selection: $context.textAlignment) {
                    Label("Left", systemImage: "text.alignleft").tag(NSTextAlignment.left)
                    Label("Center", systemImage: "text.aligncenter").tag(NSTextAlignment.center)
                    Label("Right", systemImage: "text.alignright").tag(NSTextAlignment.right)
                    Label("Justified", systemImage: "text.justify").tag(NSTextAlignment.justified)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }

    private func styleToggleRow(style: RichTextStyle, label: String, icon: String) -> some View {
        Toggle(isOn: Binding(
            get: { context.hasStyle(style) },
            set: { _ in context.toggleStyle(style) }
        )) {
            Label(label, systemImage: icon)
        }
    }

    private var availableFonts: [String] {
        let commonFonts = ["Palatino", "Georgia", "Times New Roman", "Helvetica", "Arial", "Courier New"]
        let allFonts = UIFont.familyNames.sorted()

        var result: [String] = []
        for font in commonFonts {
            if allFonts.contains(font) {
                result.append(font)
            }
        }
        for font in allFonts {
            if !result.contains(font) {
                result.append(font)
            }
        }
        return result
    }
}

// MARK: - Paragraph Tab

private struct ParagraphTabContent: View {
    @ObservedObject var context: RichTextContext
    @State private var selectedLineSpacing: CGFloat = 1.0

    private let lineSpacingOptions: [(String, CGFloat)] = [
        ("1", 1.0),
        ("1.15", 1.15),
        ("1.5", 1.5),
        ("2", 2.0)
    ]

    var body: some View {
        Form {
            Section {
                Picker("", selection: $context.textAlignment) {
                    Label("Left", systemImage: "text.alignleft").tag(NSTextAlignment.left)
                    Label("Center", systemImage: "text.aligncenter").tag(NSTextAlignment.center)
                    Label("Right", systemImage: "text.alignright").tag(NSTextAlignment.right)
                    Label("Justified", systemImage: "text.justify").tag(NSTextAlignment.justified)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Line Spacing") {
                Picker("Spacing", selection: $selectedLineSpacing) {
                    ForEach(lineSpacingOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                .onChange(of: selectedLineSpacing) { _, newValue in
                    context.lineSpacing = newValue * 4
                }
            }

            Section("Text Highlight") {
                Text("Text highlight colors will be available in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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

#if os(iOS)
#Preview("Formatting Palette - iOS") {
    FormattingPalette(context: RichTextContext())
}
#endif
#endif
