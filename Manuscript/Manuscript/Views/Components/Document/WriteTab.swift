import SwiftUI
import RichTextKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct WriteTab: View {
    @ObservedObject var viewModel: DocumentDetailViewModel
    @StateObject private var richTextContext = RichTextContext()
    @State private var isFormattingPalettePresented = false
    @State private var hasInitialized = false

    #if os(macOS)
    @State private var textViewRef: NSTextView? = nil
    @State private var keyMonitor: Any? = nil
    #else
    @State private var textViewRef: UITextView? = nil
    #endif

    // Formatting defaults from settings
    @AppStorage("defaultFontName") private var defaultFontName: String = "Palatino"
    @AppStorage("defaultFontSize") private var defaultFontSize: Double = 16
    @AppStorage("defaultLineSpacing") private var defaultLineSpacing: String = "single"
    @AppStorage("enableParagraphIndent") private var enableParagraphIndent: Bool = true
    @AppStorage("paragraphIndentSize") private var paragraphIndentSize: Double = 24

    // Maximum width for comfortable prose reading (similar to A4 page)
    private let maxProseWidth: CGFloat = 700

    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // macOS: Toolbar at the top
            FormattingToolbar(context: richTextContext)
            Divider()
            #endif

            // Rich text editor with centered prose layout
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let horizontalPadding = max(24, (availableWidth - maxProseWidth) / 2)

                RichTextEditor(
                    text: $viewModel.attributedContent,
                    context: richTextContext,
                    viewConfiguration: { textView in
                        #if os(macOS)
                        if let nsTextView = textView as? NSTextView {
                            nsTextView.drawsBackground = false
                            nsTextView.enclosingScrollView?.drawsBackground = false
                            nsTextView.enclosingScrollView?.backgroundColor = .clear
                            // Store reference for scrolling to comments
                            DispatchQueue.main.async {
                                self.textViewRef = nsTextView
                                // Set typing attributes for new empty documents
                                self.configureTypingAttributes(for: nsTextView)
                            }
                        }
                        #else
                        if let uiTextView = textView as? UITextView {
                            DispatchQueue.main.async {
                                self.textViewRef = uiTextView
                                // Set typing attributes for new empty documents
                                self.configureTypingAttributes(for: uiTextView)
                            }
                        }
                        #endif
                    }
                )
                .focusedValue(\.richTextContext, richTextContext)
                .richTextEditorStyle(RichTextEditorStyle(backgroundColor: .clear))
                .background(.clear)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 16)
            }

            #if os(iOS)
            // iOS: Compact toolbar at the bottom with option to expand
            VStack(spacing: 0) {
                Divider()
                HStack {
                    FormattingToolbar(context: richTextContext)

                    Spacer()

                    Button {
                        isFormattingPalettePresented = true
                    } label: {
                        Image(systemName: "textformat")
                            .font(.title3)
                    }
                    .padding(.trailing, 12)
                }
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
            }
            #endif
        }
        .onAppear {
            if !hasInitialized {
                setupContext()
                hasInitialized = true
            }
            #if os(macOS)
            setupKeyMonitor()
            #endif
        }
        .onDisappear {
            // Save content when leaving the view
            saveContent()
            #if os(macOS)
            removeKeyMonitor()
            #endif
        }
        .onChange(of: richTextContext.attributedString) { _, newValue in
            // Sync changes back to viewModel immediately
            viewModel.attributedContent = newValue
        }
        .onChange(of: richTextContext.selectedRange) { _, newRange in
            // Track text selection for comments
            updateTextSelection(range: newRange)
        }
        .onChange(of: viewModel.tappedComment) { _, tappedComment in
            // Scroll to comment's text range when tapped in inspector
            scrollToComment(tappedComment)
        }
        #if os(iOS)
        .sheet(isPresented: $isFormattingPalettePresented) {
            FormattingPalette(context: richTextContext)
        }
        #endif
    }

    private func setupContext() {
        // Initialize context with current content
        var contentToSet = viewModel.attributedContent

        // Apply paragraph styling to existing content if indent is enabled
        if enableParagraphIndent && contentToSet.length > 0 {
            contentToSet = applyParagraphIndent(to: contentToSet)
        }

        // For empty documents, create attributed string with proper defaults
        if contentToSet.string.isEmpty {
            contentToSet = createDefaultAttributedString()
        }

        richTextContext.setAttributedString(to: contentToSet)

        // Set context properties for new typing
        richTextContext.fontName = defaultFontName
        richTextContext.fontSize = CGFloat(defaultFontSize)

        // Set foreground color to label color (adapts to dark/light mode)
        #if os(macOS)
        richTextContext.setColor(.foreground, to: .labelColor)
        #else
        richTextContext.setColor(.foreground, to: .label)
        #endif

        // Configure paragraph style via RichTextKit's paragraphStyle property
        configureParagraphStyle()
    }

    /// Creates an attributed string with default formatting for new documents
    private func createDefaultAttributedString() -> NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [:]

        // Font
        #if os(macOS)
        if let font = NSFont(name: defaultFontName, size: CGFloat(defaultFontSize)) {
            attributes[.font] = font
        }
        attributes[.foregroundColor] = NSColor.labelColor
        #else
        if let font = UIFont(name: defaultFontName, size: CGFloat(defaultFontSize)) {
            attributes[.font] = font
        }
        attributes[.foregroundColor] = UIColor.label
        #endif

        // Paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        if enableParagraphIndent {
            paragraphStyle.firstLineHeadIndent = CGFloat(paragraphIndentSize)
        }
        let lineSpacingMultiplier: CGFloat = switch defaultLineSpacing {
        case "1.15": 1.15
        case "1.5": 1.5
        case "double": 2.0
        default: 1.0
        }
        paragraphStyle.lineSpacing = lineSpacingMultiplier * 6
        attributes[.paragraphStyle] = paragraphStyle

        return NSAttributedString(string: "", attributes: attributes)
    }

    /// Configures typing attributes on the text view for new/empty documents
    #if os(macOS)
    private func configureTypingAttributes(for textView: NSTextView) {
        // Build the paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        if enableParagraphIndent {
            paragraphStyle.firstLineHeadIndent = CGFloat(paragraphIndentSize)
        }
        let lineSpacingMultiplier: CGFloat = switch defaultLineSpacing {
        case "1.15": 1.15
        case "1.5": 1.5
        case "double": 2.0
        default: 1.0
        }
        paragraphStyle.lineSpacing = lineSpacingMultiplier * 6

        // Set the default paragraph style for the text view
        textView.defaultParagraphStyle = paragraphStyle

        // Build typing attributes
        var typingAttributes: [NSAttributedString.Key: Any] = [:]

        // Font
        let font = NSFont(name: defaultFontName, size: CGFloat(defaultFontSize))
            ?? NSFont.userFont(ofSize: CGFloat(defaultFontSize))
            ?? NSFont.systemFont(ofSize: CGFloat(defaultFontSize))
        typingAttributes[.font] = font

        // Foreground color - use label color for dark mode support
        typingAttributes[.foregroundColor] = NSColor.labelColor

        // Paragraph style
        typingAttributes[.paragraphStyle] = paragraphStyle

        // Set typing attributes
        textView.typingAttributes = typingAttributes

        // Also set the font on the text view directly for empty documents
        if textView.string.isEmpty {
            textView.font = font
            textView.textColor = NSColor.labelColor
        }
    }
    #else
    private func configureTypingAttributes(for textView: UITextView) {
        var typingAttributes: [NSAttributedString.Key: Any] = [:]

        // Font
        if let font = UIFont(name: defaultFontName, size: CGFloat(defaultFontSize)) {
            typingAttributes[.font] = font
        } else {
            typingAttributes[.font] = UIFont.systemFont(ofSize: CGFloat(defaultFontSize))
        }

        // Foreground color - use label color for dark mode support
        typingAttributes[.foregroundColor] = UIColor.label

        // Paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        if enableParagraphIndent {
            paragraphStyle.firstLineHeadIndent = CGFloat(paragraphIndentSize)
        }
        let lineSpacingMultiplier: CGFloat = switch defaultLineSpacing {
        case "1.15": 1.15
        case "1.5": 1.5
        case "double": 2.0
        default: 1.0
        }
        paragraphStyle.lineSpacing = lineSpacingMultiplier * 6
        typingAttributes[.paragraphStyle] = paragraphStyle

        textView.typingAttributes = typingAttributes
    }
    #endif

    /// Configures the RichTextContext's paragraph style using RichTextKit's API
    private func configureParagraphStyle() {
        // Set first line indent via RichTextKit binding
        if enableParagraphIndent {
            let indentBinding = richTextContext.paragraphStyleValueBinding(for: \.firstLineHeadIndent)
            indentBinding.wrappedValue = CGFloat(paragraphIndentSize)
        }

        // Set line spacing via RichTextKit binding
        let lineSpacingMultiplier: CGFloat = switch defaultLineSpacing {
        case "1.15": 1.15
        case "1.5": 1.5
        case "double": 2.0
        default: 1.0
        }
        let lineSpacingBinding = richTextContext.paragraphStyleValueBinding(for: \.lineSpacing)
        lineSpacingBinding.wrappedValue = lineSpacingMultiplier * 6
    }

    /// Applies first-line indent to all paragraphs in the attributed string
    private func applyParagraphIndent(to attributedString: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutable.length)
        guard fullRange.length > 0 else { return mutable }

        // Process each paragraph separately to apply indent correctly
        let string = mutable.string as NSString
        var paragraphStart = 0

        while paragraphStart < string.length {
            // Find the paragraph range
            let paragraphRange = string.paragraphRange(for: NSRange(location: paragraphStart, length: 0))

            // Get existing paragraph style or create new one
            let existingStyle = mutable.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle
            let newStyle = (existingStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            newStyle.firstLineHeadIndent = CGFloat(paragraphIndentSize)

            // Apply the style to this paragraph
            mutable.addAttribute(.paragraphStyle, value: newStyle, range: paragraphRange)

            // Move to next paragraph
            paragraphStart = paragraphRange.location + paragraphRange.length
        }

        return mutable
    }

    // MARK: - Shift+Enter Key Handling

    #if os(macOS)
    /// Sets up keyboard monitoring to intercept Shift+Enter for soft line breaks
    private func setupKeyMonitor() {
        guard enableParagraphIndent else { return }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Check for Shift+Enter (Return key = keyCode 36)
            if event.keyCode == 36 && event.modifierFlags.contains(.shift) {
                // Insert line separator instead of newline
                if let textView = self.textViewRef, textView.window?.firstResponder == textView {
                    self.insertLineSeparator(in: textView)
                    return nil // Consume the event
                }
            }
            return event
        }
    }

    /// Removes the key monitor when the view disappears
    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    /// Inserts a line separator character (U+2028) for soft line break
    private func insertLineSeparator(in textView: NSTextView) {
        // Unicode Line Separator character - creates new line without new paragraph
        let lineSeparator = "\u{2028}"

        if textView.shouldChangeText(in: textView.selectedRange(), replacementString: lineSeparator) {
            textView.replaceCharacters(in: textView.selectedRange(), with: lineSeparator)
            textView.didChangeText()
        }
    }
    #endif

    private func saveContent() {
        // Ensure the latest content from the editor is saved
        viewModel.attributedContent = richTextContext.attributedString
        viewModel.saveChanges()
    }

    private func updateTextSelection(range: NSRange) {
        // Update the viewModel with selected text and range
        let attributedString = richTextContext.attributedString
        let fullString = attributedString.string

        if range.length > 0, range.location >= 0, range.location + range.length <= fullString.count {
            let startIndex = fullString.index(fullString.startIndex, offsetBy: range.location)
            let endIndex = fullString.index(startIndex, offsetBy: range.length)
            viewModel.selectedText = String(fullString[startIndex..<endIndex])
            viewModel.selectedTextRange = range
        } else {
            viewModel.selectedText = ""
            viewModel.selectedTextRange = nil

            // When user taps (no selection), check if they tapped on commented text
            // This opens the inspector with comments tab if cursor is in a comment range
            if range.location >= 0 && range.location < fullString.count {
                viewModel.handleTapAtCharacterIndex(range.location)
            }
        }
    }

    private func scrollToComment(_ comment: ManuscriptDocument.DocumentComment?) {
        guard let comment = comment,
              let range = comment.range else { return }

        let nsRange = NSRange(location: range.location, length: range.length)
        let fullString = richTextContext.attributedString.string

        // Validate range is within bounds
        guard nsRange.location >= 0,
              nsRange.location + nsRange.length <= fullString.count else { return }

        // Use the native text view to scroll and select the range
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            #if os(macOS)
            if let textView = textViewRef {
                textView.setSelectedRange(nsRange)
                textView.scrollRangeToVisible(nsRange)
            }
            #else
            if let textView = textViewRef {
                textView.selectedRange = nsRange
                textView.scrollRangeToVisible(nsRange)
            }
            #endif
        }
    }
}

#if DEBUG
#Preview {
    let docItem = ManuscriptDocument.Document(
        title: "Sample Document",
        notes: "Sample notes",
        content: "Sample content with some **bold** text."
    )
    let viewModel = DocumentViewModel()
    return WriteTab(viewModel: DocumentDetailViewModel(document: docItem, documentViewModel: viewModel))
}
#endif
