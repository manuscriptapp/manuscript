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

    // Formatting defaults from settings
    @AppStorage("defaultFontName") private var defaultFontName: String = "Palatino"
    @AppStorage("defaultFontSize") private var defaultFontSize: Double = 16
    @AppStorage("defaultLineSpacing") private var defaultLineSpacing: String = "single"

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
                #if os(iOS)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button {
                            richTextContext.toggleStyle(.bold)
                        } label: {
                            Image(systemName: "bold")
                                .foregroundStyle(richTextContext.hasStyle(.bold) ? Color.accentColor : Color.primary)
                        }

                        Button {
                            richTextContext.toggleStyle(.italic)
                        } label: {
                            Image(systemName: "italic")
                                .foregroundStyle(richTextContext.hasStyle(.italic) ? Color.accentColor : Color.primary)
                        }

                        Button {
                            richTextContext.toggleStyle(.underlined)
                        } label: {
                            Image(systemName: "underline")
                                .foregroundStyle(richTextContext.hasStyle(.underlined) ? Color.accentColor : Color.primary)
                        }

                        Spacer()

                        Button {
                            isFormattingPalettePresented = true
                        } label: {
                            Image(systemName: "textformat")
                        }
                    }
                }
                #endif
            }
        }
        .onAppear {
            if !hasInitialized {
                setupContext()
                hasInitialized = true
            }
        }
        .onDisappear {
            // Save content when leaving the view
            saveContent()
        }
        .onChange(of: richTextContext.attributedString) { _, newValue in
            // Sync changes back to viewModel immediately
            viewModel.attributedContent = newValue
        }
        .onChange(of: richTextContext.selectedRange) { _, newRange in
            // Track text selection for comments
            updateTextSelection(range: newRange)
        }
        #if os(iOS)
        .sheet(isPresented: $isFormattingPalettePresented) {
            FormattingPalette(context: richTextContext)
        }
        #endif
    }

    private func setupContext() {
        // Initialize context with current content
        richTextContext.setAttributedString(to: viewModel.attributedContent)

        // Set default formatting if content is empty
        if viewModel.attributedContent.string.isEmpty {
            richTextContext.fontName = defaultFontName
            richTextContext.fontSize = CGFloat(defaultFontSize)

            // Apply default line spacing
            let lineSpacingMultiplier: CGFloat = switch defaultLineSpacing {
            case "1.15": 1.15
            case "1.5": 1.5
            case "double": 2.0
            default: 1.0
            }
            richTextContext.lineSpacing = lineSpacingMultiplier * 6
        }
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
