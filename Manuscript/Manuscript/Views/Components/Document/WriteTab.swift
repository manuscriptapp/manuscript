import SwiftUI
import RichTextKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// Debug logging helper
private func debugLog(_ message: String) {
    let logFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("manuscript_debug.log")
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    let logMessage = "[\(timestamp)] \(message)\n"
    if let data = logMessage.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let handle = try? FileHandle(forWritingTo: logFile) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logFile)
        }
    }
    // Also print to console
    print(message)
}

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

    // Custom undo stack for formatting changes (RichTextKit doesn't register them)
    @State private var formattingUndoStack: [NSAttributedString] = []
    @State private var formattingRedoStack: [NSAttributedString] = []
    @State private var lastKnownAttributedString: NSAttributedString?
    @State private var lastChangeWasFormatting = false

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
                                textViewRef = nsTextView
                            }
                        }
                        #else
                        if let uiTextView = textView as? UITextView {
                            DispatchQueue.main.async {
                                textViewRef = uiTextView
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

            // Auto-focus the text editor after a short delay to ensure it's ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                focusTextEditor()
            }
        }
        .onDisappear {
            // Save content when leaving the view
            saveContent()
            #if os(macOS)
            removeKeyMonitor()
            #endif
        }
        .onChange(of: richTextContext.styles) { _, _ in
            // Styles changed (bold, italic, etc.) - track for undo
            NSLog("[UNDO] styles changed!")
            trackStyleChange()
        }
        .onChange(of: richTextContext.fontName) { _, _ in
            // Font changed - track for undo
            NSLog("[UNDO] fontName changed!")
            trackStyleChange()
        }
        .onChange(of: richTextContext.fontSize) { _, _ in
            // Font size changed - track for undo
            NSLog("[UNDO] fontSize changed!")
            trackStyleChange()
        }
        .onChange(of: viewModel.attributedContent) { _, newValue in
            // When content changes (typing), update our tracking reference
            // but only if the string content actually changed (not just formatting)
            if lastKnownAttributedString?.string != newValue.string {
                NSLog("[UNDO] text content changed, updating lastKnownAttributedString")
                lastKnownAttributedString = newValue
                lastChangeWasFormatting = false
            }
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

        richTextContext.setAttributedString(to: contentToSet)

        // Initialize the formatting undo tracking
        lastKnownAttributedString = contentToSet

        // Configure paragraph style via RichTextKit's paragraphStyle property
        configureParagraphStyle()
    }

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

    // MARK: - Formatting Undo/Redo

    /// Tracks style changes for undo functionality
    private func trackStyleChange() {
        #if os(macOS)
        // Get the current state directly from the text view
        guard let textView = textViewRef else {
            NSLog("[UNDO] trackStyleChange: no textView ref")
            return
        }

        // Capture the CURRENT state from the text view (before RichTextKit applies the change)
        let currentTextViewState = NSAttributedString(attributedString: textView.attributedString())
        NSLog("[UNDO] trackStyleChange: currentTextViewState length = \(currentTextViewState.length), string = '\(currentTextViewState.string)'")

        // Don't track if text view is empty
        guard currentTextViewState.length > 0 else {
            NSLog("[UNDO] trackStyleChange: text view is empty, skipping")
            return
        }

        // The lastKnownAttributedString contains the state BEFORE this change
        if let previousState = lastKnownAttributedString {
            NSLog("[UNDO] trackStyleChange: previousState length = \(previousState.length), string = '\(previousState.string)'")

            // Only push if we have valid previous state and states are actually different
            guard previousState.length > 0 else {
                NSLog("[UNDO] trackStyleChange: previousState is empty, just updating to current")
                lastKnownAttributedString = currentTextViewState
                return
            }

            // Only push if the states are actually different
            if !previousState.isEqual(to: currentTextViewState) {
                NSLog("[UNDO] trackStyleChange: states differ, pushing previousState to undo stack")
                formattingUndoStack.append(previousState)
                formattingRedoStack.removeAll()
                lastChangeWasFormatting = true

                // Limit stack size
                if formattingUndoStack.count > 50 {
                    formattingUndoStack.removeFirst()
                }
                NSLog("[UNDO] trackStyleChange: undo stack size = \(formattingUndoStack.count)")
            } else {
                NSLog("[UNDO] trackStyleChange: states are equal, not pushing")
            }
        } else {
            NSLog("[UNDO] trackStyleChange: no previousState, capturing current")
        }

        // Update lastKnownAttributedString to the current text view state
        lastKnownAttributedString = currentTextViewState

        // Also schedule a delayed update to capture state after RichTextKit finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            if let tv = textViewRef {
                let newState = NSAttributedString(attributedString: tv.attributedString())
                if newState.length > 0 && lastKnownAttributedString?.isEqual(to: newState) == false {
                    NSLog("[UNDO] trackStyleChange (delayed): state changed, updating lastKnownAttributedString")
                    lastKnownAttributedString = newState
                }
            }
        }
        #endif
    }

    /// Performs undo for formatting changes
    private func undoFormatting() {
        NSLog("[UNDO] undoFormatting called, stack size: \(formattingUndoStack.count)")
        guard let lastState = formattingUndoStack.popLast() else {
            NSLog("[UNDO]   -> Stack empty, nothing to undo")
            return
        }

        #if os(macOS)
        guard let textView = textViewRef,
              let textStorage = textView.textStorage else {
            NSLog("[UNDO]   -> No textView/textStorage reference!")
            return
        }

        NSLog("[UNDO]   -> lastState.length: \(lastState.length), lastState.string: '\(lastState.string)'")

        // Validate the state we're restoring
        guard lastState.length > 0 else {
            NSLog("[UNDO]   -> ERROR: lastState is empty, aborting undo")
            return
        }

        // Push current state to redo stack
        let currentState = NSAttributedString(attributedString: textView.attributedString())
        formattingRedoStack.append(currentState)

        NSLog("[UNDO]   -> currentState.length: \(currentState.length), currentState.string: '\(currentState.string)'")

        // Only restore if the text content matches (safety check)
        guard lastState.string == currentState.string else {
            NSLog("[UNDO]   -> ERROR: Text content mismatch! Aborting to prevent data loss")
            NSLog("[UNDO]   -> lastState.string: '\(lastState.string)'")
            NSLog("[UNDO]   -> currentState.string: '\(currentState.string)'")
            // Put it back since we're not using it
            formattingUndoStack.append(lastState)
            formattingRedoStack.removeLast()
            return
        }

        if lastState.length > 0 {
            NSLog("[UNDO]   -> Current font: \(currentState.attribute(.font, at: 0, effectiveRange: nil) ?? "nil")")
            NSLog("[UNDO]   -> Restoring to font: \(lastState.attribute(.font, at: 0, effectiveRange: nil) ?? "nil")")
        }

        // Save selection
        let savedSelection = textView.selectedRange()

        // Replace the entire content using replaceCharacters which properly triggers updates
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: fullRange, with: lastState)
        textStorage.endEditing()

        // Restore selection
        let newSelection = NSRange(location: min(savedSelection.location, textStorage.length),
                                   length: min(savedSelection.length, textStorage.length - min(savedSelection.location, textStorage.length)))
        textView.setSelectedRange(newSelection)

        // Force layout update
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        textView.needsDisplay = true

        // Also update the context and viewModel
        richTextContext.setAttributedString(to: lastState)
        viewModel.attributedContent = lastState
        lastKnownAttributedString = lastState
        lastChangeWasFormatting = false

        NSLog("[UNDO]   -> State restored, new length: \(textStorage.length)")
        #endif
    }

    /// Performs redo for formatting changes
    private func redoFormatting() {
        NSLog("[UNDO] redoFormatting called, stack size: \(formattingRedoStack.count)")
        guard let nextState = formattingRedoStack.popLast() else {
            NSLog("[UNDO]   -> Stack empty, nothing to redo")
            return
        }

        #if os(macOS)
        guard let textView = textViewRef,
              let textStorage = textView.textStorage else {
            NSLog("[UNDO]   -> No textView/textStorage reference!")
            return
        }

        // Push current state to undo stack
        let currentState = NSAttributedString(attributedString: textView.attributedString())
        formattingUndoStack.append(currentState)

        // Save selection
        let savedSelection = textView.selectedRange()

        // Replace the entire content
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: fullRange, with: nextState)
        textStorage.endEditing()

        // Restore selection
        let newSelection = NSRange(location: min(savedSelection.location, textStorage.length),
                                   length: min(savedSelection.length, textStorage.length - min(savedSelection.location, textStorage.length)))
        textView.setSelectedRange(newSelection)

        // Force layout update
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        textView.needsDisplay = true

        // Also update the context and viewModel
        richTextContext.setAttributedString(to: nextState)
        viewModel.attributedContent = nextState
        lastKnownAttributedString = nextState
        lastChangeWasFormatting = false

        NSLog("[UNDO]   -> State restored")
        #endif
    }

    // MARK: - Keyboard Handling

    #if os(macOS)
    /// Sets up keyboard monitoring for Shift+Enter (soft line breaks) and Undo/Redo
    private func setupKeyMonitor() {
        NSLog("[UNDO] setupKeyMonitor called")
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Check for Shift+Enter (Return key = keyCode 36) for soft line breaks
            if enableParagraphIndent && event.keyCode == 36 && event.modifierFlags.contains(.shift) {
                if let textView = self.textViewRef, textView.window?.firstResponder == textView {
                    self.insertLineSeparator(in: textView)
                    return nil // Consume the event
                }
            }

            // Check for Cmd+Z (keyCode 6 = Z key) for undo/redo
            if event.keyCode == 6 && event.modifierFlags.contains(.command) {
                NSLog("[UNDO] Cmd+Z detected!")
                if let textView = self.textViewRef, textView.window?.firstResponder == textView {
                    NSLog("[UNDO]   textView is first responder")
                    NSLog("[UNDO]   lastChangeWasFormatting: \(self.lastChangeWasFormatting)")
                    NSLog("[UNDO]   formattingUndoStack.count: \(self.formattingUndoStack.count)")
                    NSLog("[UNDO]   formattingRedoStack.count: \(self.formattingRedoStack.count)")
                    NSLog("[UNDO]   undoManager?.canUndo: \(textView.undoManager?.canUndo ?? false)")
                    NSLog("[UNDO]   undoManager?.canRedo: \(textView.undoManager?.canRedo ?? false)")

                    if event.modifierFlags.contains(.shift) {
                        NSLog("[UNDO]   -> REDO requested")
                        // Cmd+Shift+Z = Redo
                        // If we have formatting redo available, prefer it
                        if !self.formattingRedoStack.isEmpty {
                            NSLog("[UNDO]   -> Using formatting redo")
                            self.redoFormatting()
                        } else if textView.undoManager?.canRedo == true {
                            NSLog("[UNDO]   -> Using NSTextView redo")
                            textView.undoManager?.redo()
                        } else {
                            NSLog("[UNDO]   -> Nothing to redo")
                        }
                    } else {
                        NSLog("[UNDO]   -> UNDO requested")
                        // Cmd+Z = Undo
                        // If the last change was formatting, prefer our formatting undo
                        if self.lastChangeWasFormatting && !self.formattingUndoStack.isEmpty {
                            NSLog("[UNDO]   -> Using formatting undo (last change was formatting)")
                            self.undoFormatting()
                        } else if textView.undoManager?.canUndo == true {
                            NSLog("[UNDO]   -> Using NSTextView undo")
                            textView.undoManager?.undo()
                        } else if !self.formattingUndoStack.isEmpty {
                            NSLog("[UNDO]   -> Using formatting undo (fallback)")
                            self.undoFormatting()
                        } else {
                            NSLog("[UNDO]   -> Nothing to undo")
                        }
                    }
                    return nil // Consume the event
                } else {
                    NSLog("[UNDO]   textView NOT first responder or nil")
                }
            }
            return event
        }
    }

    /// Removes the key monitors when the view disappears
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

    private func focusTextEditor() {
        #if os(macOS)
        if let textView = textViewRef {
            textView.window?.makeFirstResponder(textView)
        }
        #else
        if let textView = textViewRef {
            textView.becomeFirstResponder()
        }
        #endif
    }

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
