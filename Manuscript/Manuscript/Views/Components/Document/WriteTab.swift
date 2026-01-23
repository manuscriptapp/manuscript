import SwiftUI
import RichTextKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct WriteTab: View {
    @ObservedObject var viewModel: DocumentDetailViewModel

    /// External RichTextContext (for split view) - if nil, creates local context
    var externalRichTextContext: RichTextContext?
    /// Callback when this editor gains focus (for split view)
    var onFocusChange: ((Bool) -> Void)?
    /// Whether to hide the formatting toolbar (used in split view where container shows unified toolbar)
    var hideToolbar: Bool = false
    /// External binding for find bar visibility (for split view unified control)
    var externalShowFindBar: Binding<Bool>?

    @StateObject private var localRichTextContext = RichTextContext()
    @StateObject private var findReplaceViewModel = FindReplaceViewModel()
    @State private var hasInitialized = false

    /// Returns the active RichTextContext (external if provided, otherwise local)
    private var richTextContext: RichTextContext {
        externalRichTextContext ?? localRichTextContext
    }

    #if os(macOS)
    @State private var textViewRef: NSTextView? = nil
    @State private var keyMonitor: Any? = nil
    // Formatting undo/redo stacks (RichTextKit doesn't register formatting with NSUndoManager)
    @State private var formattingUndoStack: [NSAttributedString] = []
    @State private var formattingRedoStack: [NSAttributedString] = []
    @State private var lastFormattingSnapshot: NSAttributedString?
    @State private var lastChangeWasFormatting = false
    #else
    @State private var textViewRef: UITextView? = nil
    #endif

    // Formatting defaults from settings
    @AppStorage("defaultFontName") private var defaultFontName: String = "Palatino"
    @AppStorage("defaultFontSize") private var defaultFontSize: Double = 16
    @AppStorage("defaultLineSpacing") private var defaultLineSpacing: String = "single"
    @AppStorage("enableParagraphIndent") private var enableParagraphIndent: Bool = true
    @AppStorage("paragraphIndentSize") private var paragraphIndentSize: Double = 24
    #if os(macOS)
    @AppStorage("showFormattingToolbar") private var showFormattingToolbar: Bool = true
    #endif

    // Maximum width for comfortable prose reading (similar to A4 page)
    private let maxProseWidth: CGFloat = 700

    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            if showFormattingToolbar && !hideToolbar {
                FormattingToolbar(context: richTextContext)
                Divider()
            }
            #endif

            // Find & Replace Bar
            if findReplaceViewModel.isVisible {
                FindReplaceBar(viewModel: findReplaceViewModel)
                Divider()
            }

            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let horizontalPadding = max(24, (availableWidth - maxProseWidth) / 2)

                #if os(macOS)
                HStack(spacing: 0) {
                    // Left margin - clickable area to focus editor
                    Color.clear
                        .frame(width: horizontalPadding)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusTextEditor()
                        }

                    // Center - the actual editor
                    RichTextEditor(
                        text: $viewModel.attributedContent,
                        context: richTextContext,
                        viewConfiguration: { textView in
                            if let nsTextView = textView as? NSTextView {
                                nsTextView.drawsBackground = false
                                nsTextView.enclosingScrollView?.drawsBackground = false
                                nsTextView.enclosingScrollView?.backgroundColor = .clear
                                DispatchQueue.main.async {
                                    textViewRef = nsTextView
                                    findReplaceViewModel.textViewRef = nsTextView
                                }
                            }
                        }
                    )
                    .focusedValue(\.richTextContext, richTextContext)
                    .richTextEditorStyle(RichTextEditorStyle(backgroundColor: .clear))
                    .background(.clear)
                    .scrollContentBackground(.hidden)
                    .frame(maxWidth: maxProseWidth)
                    .padding(.top, 32)
                    .padding(.bottom, 16)

                    // Right margin - clickable area to focus editor
                    Color.clear
                        .frame(width: horizontalPadding)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusTextEditor()
                        }
                }
                #else
                RichTextEditor(
                    text: $viewModel.attributedContent,
                    context: richTextContext,
                    viewConfiguration: { textView in
                        if let uiTextView = textView as? UITextView {
                            DispatchQueue.main.async {
                                textViewRef = uiTextView
                                findReplaceViewModel.textViewRef = uiTextView
                                setupKeyboardToolbar(for: uiTextView)
                            }
                        }
                    }
                )
                .focusedValue(\.richTextContext, richTextContext)
                .richTextEditorStyle(RichTextEditorStyle(backgroundColor: .clear))
                .background(.clear)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 16)
                #endif
            }

        }
        .onAppear {
            if !hasInitialized {
                setupContext()
                hasInitialized = true
            }
            #if os(macOS)
            setupKeyMonitor()
            #endif

            // Connect find/replace view model
            findReplaceViewModel.documentDetailViewModel = viewModel

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                focusTextEditor()
            }
        }
        .onDisappear {
            saveContent()
            #if os(macOS)
            removeKeyMonitor()
            #endif
        }
        #if os(macOS)
        .onChange(of: richTextContext.styles) { _, _ in
            captureFormattingState()
        }
        .onChange(of: richTextContext.fontName) { _, _ in
            captureFormattingState()
        }
        .onChange(of: richTextContext.fontSize) { _, _ in
            captureFormattingState()
        }
        .onChange(of: viewModel.attributedContent) { _, newValue in
            // Update snapshot when text content changes (not just formatting)
            if lastFormattingSnapshot?.string != newValue.string {
                lastFormattingSnapshot = newValue
                lastChangeWasFormatting = false
            }
        }
        #endif
        .onChange(of: richTextContext.selectedRange) { _, newRange in
            updateTextSelection(range: newRange)
            // Notify parent that this editor has focus (user interacted with it)
            onFocusChange?(true)
        }
        .onChange(of: viewModel.tappedComment) { _, tappedComment in
            scrollToComment(tappedComment)
        }
        .onChange(of: viewModel.showFindBar) { _, showFind in
            if showFind {
                findReplaceViewModel.show(replaceMode: false)
                viewModel.showFindBar = false  // Reset trigger
            }
        }
        .onChange(of: viewModel.showFindReplaceBar) { _, showFindReplace in
            if showFindReplace {
                findReplaceViewModel.show(replaceMode: true)
                viewModel.showFindReplaceBar = false  // Reset trigger
            }
        }
        .onChange(of: externalShowFindBar?.wrappedValue) { _, newValue in
            // Sync external find bar binding with local findReplaceViewModel
            if let showFind = newValue {
                if showFind && !findReplaceViewModel.isVisible {
                    findReplaceViewModel.show(replaceMode: false)
                } else if !showFind && findReplaceViewModel.isVisible {
                    findReplaceViewModel.hide()
                }
            }
        }
        .onChange(of: findReplaceViewModel.isVisible) { _, isVisible in
            // Sync local state back to external binding
            if let binding = externalShowFindBar, binding.wrappedValue != isVisible {
                binding.wrappedValue = isVisible
            }
        }
        // Expose find actions for menu commands
        .focusedValue(\.findActions, FindActions(
            showFind: { findReplaceViewModel.show(replaceMode: false) },
            showFindAndReplace: { findReplaceViewModel.show(replaceMode: true) },
            findNext: { findReplaceViewModel.navigateNext() },
            findPrevious: { findReplaceViewModel.navigatePrevious() }
        ))
    }

    // MARK: - Setup

    private func setupContext() {
        var contentToSet = viewModel.attributedContent

        if enableParagraphIndent && contentToSet.length > 0 {
            contentToSet = applyParagraphIndent(to: contentToSet)
        }

        richTextContext.setAttributedString(to: contentToSet)

        #if os(macOS)
        lastFormattingSnapshot = contentToSet
        #endif

        configureParagraphStyle()
    }

    private func configureParagraphStyle() {
        if enableParagraphIndent {
            let indentBinding = richTextContext.paragraphStyleValueBinding(for: \.firstLineHeadIndent)
            indentBinding.wrappedValue = CGFloat(paragraphIndentSize)
        }

        let lineSpacingMultiplier: CGFloat = switch defaultLineSpacing {
        case "1.15": 1.15
        case "1.5": 1.5
        case "double": 2.0
        default: 1.0
        }
        let lineSpacingBinding = richTextContext.paragraphStyleValueBinding(for: \.lineSpacing)
        lineSpacingBinding.wrappedValue = lineSpacingMultiplier * 6
    }

    private func applyParagraphIndent(to attributedString: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutable.length)
        guard fullRange.length > 0 else { return mutable }

        let string = mutable.string as NSString
        var paragraphStart = 0

        while paragraphStart < string.length {
            let paragraphRange = string.paragraphRange(for: NSRange(location: paragraphStart, length: 0))
            let existingStyle = mutable.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle
            let newStyle = (existingStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            newStyle.firstLineHeadIndent = CGFloat(paragraphIndentSize)
            mutable.addAttribute(.paragraphStyle, value: newStyle, range: paragraphRange)
            paragraphStart = paragraphRange.location + paragraphRange.length
        }

        return mutable
    }

    // MARK: - Formatting Undo/Redo (macOS only)

    #if os(macOS)
    /// Captures the current formatting state before a change is applied
    private func captureFormattingState() {
        guard let textView = textViewRef else { return }

        let currentState = NSAttributedString(attributedString: textView.attributedString())
        guard currentState.length > 0 else { return }

        // Push previous snapshot to undo stack if it differs from current
        if let previousSnapshot = lastFormattingSnapshot,
           previousSnapshot.length > 0,
           !previousSnapshot.isEqual(to: currentState) {
            formattingUndoStack.append(previousSnapshot)
            formattingRedoStack.removeAll()
            lastChangeWasFormatting = true

            // Limit stack size to prevent memory issues
            if formattingUndoStack.count > 50 {
                formattingUndoStack.removeFirst()
            }
        }

        // Update snapshot to current state
        lastFormattingSnapshot = currentState

        // Capture state again after RichTextKit finishes applying changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            if let tv = textViewRef {
                let newState = NSAttributedString(attributedString: tv.attributedString())
                if newState.length > 0 && lastFormattingSnapshot?.isEqual(to: newState) == false {
                    lastFormattingSnapshot = newState
                }
            }
        }
    }

    /// Restores the previous formatting state
    private func undoFormatting() {
        guard let previousState = formattingUndoStack.popLast(),
              let textView = textViewRef,
              let textStorage = textView.textStorage,
              previousState.length > 0 else { return }

        let currentState = NSAttributedString(attributedString: textView.attributedString())

        // Safety: only restore if text content matches
        guard previousState.string == currentState.string else { return }

        formattingRedoStack.append(currentState)
        restoreFormattingState(previousState, in: textView, textStorage: textStorage)
    }

    /// Restores a previously undone formatting state
    private func redoFormatting() {
        guard let nextState = formattingRedoStack.popLast(),
              let textView = textViewRef,
              let textStorage = textView.textStorage,
              nextState.length > 0 else { return }

        let currentState = NSAttributedString(attributedString: textView.attributedString())
        formattingUndoStack.append(currentState)
        restoreFormattingState(nextState, in: textView, textStorage: textStorage)
    }

    /// Applies an attributed string state to the text view
    private func restoreFormattingState(_ state: NSAttributedString, in textView: NSTextView, textStorage: NSTextStorage) {
        let savedSelection = textView.selectedRange()

        textStorage.beginEditing()
        textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: state)
        textStorage.endEditing()

        // Restore selection within bounds
        let maxLocation = min(savedSelection.location, textStorage.length)
        let maxLength = min(savedSelection.length, textStorage.length - maxLocation)
        textView.setSelectedRange(NSRange(location: maxLocation, length: maxLength))

        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        textView.needsDisplay = true

        richTextContext.setAttributedString(to: state)
        viewModel.attributedContent = state
        lastFormattingSnapshot = state
        lastChangeWasFormatting = false
    }
    #endif

    // MARK: - Keyboard Handling

    #if os(macOS)
    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Shift+Enter for soft line breaks
            if enableParagraphIndent && event.keyCode == 36 && event.modifierFlags.contains(.shift) {
                if let textView = self.textViewRef, textView.window?.firstResponder == textView {
                    self.insertLineSeparator(in: textView)
                    return nil
                }
            }

            // Cmd+Z / Cmd+Shift+Z for undo/redo
            if event.keyCode == 6 && event.modifierFlags.contains(.command) {
                if let textView = self.textViewRef, textView.window?.firstResponder == textView {
                    if event.modifierFlags.contains(.shift) {
                        // Redo
                        if !self.formattingRedoStack.isEmpty {
                            self.redoFormatting()
                        } else if textView.undoManager?.canRedo == true {
                            textView.undoManager?.redo()
                        }
                    } else {
                        // Undo
                        if self.lastChangeWasFormatting && !self.formattingUndoStack.isEmpty {
                            self.undoFormatting()
                        } else if textView.undoManager?.canUndo == true {
                            textView.undoManager?.undo()
                        } else if !self.formattingUndoStack.isEmpty {
                            self.undoFormatting()
                        }
                    }
                    return nil
                }
            }

            // MARK: - Find & Replace Shortcuts

            // Cmd+F - Open Find
            if event.keyCode == 3 && event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.option) {
                self.findReplaceViewModel.show(replaceMode: false)
                return nil
            }

            // Cmd+Option+F - Open Find & Replace
            if event.keyCode == 3 && event.modifierFlags.contains(.command) && event.modifierFlags.contains(.option) {
                self.findReplaceViewModel.show(replaceMode: true)
                return nil
            }

            // Cmd+G - Find Next
            if event.keyCode == 5 && event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) {
                if self.findReplaceViewModel.isVisible {
                    self.findReplaceViewModel.navigateNext()
                    return nil
                }
            }

            // Cmd+Shift+G - Find Previous
            if event.keyCode == 5 && event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) {
                if self.findReplaceViewModel.isVisible {
                    self.findReplaceViewModel.navigatePrevious()
                    return nil
                }
            }

            // Escape - Close Find Bar
            if event.keyCode == 53 && self.findReplaceViewModel.isVisible {
                self.findReplaceViewModel.hide()
                return nil
            }

            return event
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func insertLineSeparator(in textView: NSTextView) {
        let lineSeparator = "\u{2028}"
        if textView.shouldChangeText(in: textView.selectedRange(), replacementString: lineSeparator) {
            textView.replaceCharacters(in: textView.selectedRange(), with: lineSeparator)
            textView.didChangeText()
        }
    }
    #endif

    // MARK: - Helper Methods

    private func focusTextEditor() {
        #if os(macOS)
        if let textView = textViewRef {
            textView.window?.makeFirstResponder(textView)
            onFocusChange?(true)
        }
        #else
        if let textView = textViewRef {
            textView.becomeFirstResponder()
            onFocusChange?(true)
        }
        #endif
    }

    private func saveContent() {
        viewModel.attributedContent = richTextContext.attributedString
        viewModel.saveChanges()
    }

    private func updateTextSelection(range: NSRange) {
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

        guard nsRange.location >= 0,
              nsRange.location + nsRange.length <= fullString.count else { return }

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

    // MARK: - iOS Keyboard Toolbar

    #if os(iOS)
    private func setupKeyboardToolbar(for textView: UITextView) {
        let toolbar = KeyboardToolbarView(context: richTextContext)
        let hostingController = UIHostingController(rootView: toolbar)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        hostingController.view.backgroundColor = .secondarySystemBackground
        textView.inputAccessoryView = hostingController.view
    }
    #endif
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
