import SwiftUI
import RichTextKit

/// A formatting toolbar that works on both iOS and macOS
/// Provides font selection, size, and basic text styling controls
struct FormattingToolbar: View {
    @ObservedObject var context: RichTextContext

    var body: some View {
        #if os(macOS)
        macOSToolbar
        #else
        iOSToolbar
        #endif
    }

    // MARK: - macOS Toolbar

    #if os(macOS)
    private var macOSToolbar: some View {
        HStack(spacing: 12) {
            // Font family picker - custom implementation showing actual font name
            Menu {
                ForEach(availableFontsMac, id: \.self) { fontName in
                    Button(fontName) {
                        context.fontName = fontName
                    }
                }
            } label: {
                HStack {
                    Text(context.fontName.isEmpty ? "Palatino" : context.fontName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
            }
            .frame(width: 150)

            // Font size picker - custom implementation showing actual size
            HStack(spacing: 4) {
                Button {
                    if context.fontSize > 8 {
                        context.fontSize -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)

                Text("\(Int(context.fontSize))")
                    .monospacedDigit()
                    .frame(width: 30)

                Button {
                    if context.fontSize < 72 {
                        context.fontSize += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)

            Divider()
                .frame(height: 20)

            // Style toggles (Bold, Italic, Underline, Strikethrough)
            RichTextStyle.ToggleGroup(context: context)

            Divider()
                .frame(height: 20)

            // Text alignment
            RichTextAlignment.Picker(selection: $context.textAlignment)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
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
    #endif

    // MARK: - iOS Toolbar

    #if os(iOS)
    private var iOSToolbar: some View {
        HStack(spacing: 16) {
            // Font family picker (compact)
            Menu {
                ForEach(availableFonts, id: \.self) { fontName in
                    Button(fontName) {
                        context.fontName = fontName
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(context.fontName)
                        .lineLimit(1)
                        .frame(maxWidth: 100)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(.subheadline)
            }

            // Font size stepper
            HStack(spacing: 4) {
                Button {
                    if context.fontSize > 8 {
                        context.fontSize -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)

                Text("\(Int(context.fontSize))")
                    .font(.subheadline)
                    .monospacedDigit()
                    .frame(width: 30)

                Button {
                    if context.fontSize < 72 {
                        context.fontSize += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
            }

            Divider()
                .frame(height: 24)

            // Style buttons
            HStack(spacing: 8) {
                styleButton(style: .bold, icon: "bold")
                styleButton(style: .italic, icon: "italic")
                styleButton(style: .underlined, icon: "underline")
                styleButton(style: .strikethrough, icon: "strikethrough")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func styleButton(style: RichTextStyle, icon: String) -> some View {
        Button {
            context.toggleStyle(style)
        } label: {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(context.hasStyle(style) ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 6))
        .tint(context.hasStyle(style) ? Color.accentColor : Color.secondary.opacity(0.3))
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

                // Font size
                HStack {
                    Text("Size")
                    Spacer()
                    Stepper("\(Int(context.fontSize)) pt", value: $context.fontSize, in: 8...72, step: 1)
                }
            }

            Section("Style") {
                styleToggleRow(style: .bold, label: "Bold", icon: "bold")
                styleToggleRow(style: .italic, label: "Italic", icon: "italic")
                styleToggleRow(style: .underlined, label: "Underline", icon: "underline")
                styleToggleRow(style: .strikethrough, label: "Strikethrough", icon: "strikethrough")
            }

            Section("Alignment") {
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

    var body: some View {
        Form {
            Section("Alignment") {
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
                // RichTextKit handles line spacing through the context
                Text("Line spacing controls will be available in a future update.")
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
