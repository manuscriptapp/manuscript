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

    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // macOS: Toolbar at the top
            FormattingToolbar(context: richTextContext)
            Divider()
            #endif

            // Rich text editor
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
            .padding()

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
        }
        .onDisappear {
            // Save content when leaving the view
            saveContent()
        }
        .onChange(of: richTextContext.attributedString) { _, newValue in
            // Sync changes back to viewModel immediately
            viewModel.attributedContent = newValue
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

        // Set default font if content is empty
        if viewModel.attributedContent.string.isEmpty {
            richTextContext.fontName = "Palatino"
            richTextContext.fontSize = 16
        }
    }

    private func saveContent() {
        // Ensure the latest content from the editor is saved
        viewModel.attributedContent = richTextContext.attributedString
        viewModel.saveChanges()
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
