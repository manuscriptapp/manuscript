import SwiftUI
import RichTextKit

struct NotesTab: View {
    @ObservedObject var viewModel: DocumentDetailViewModel
    @StateObject private var richTextContext = RichTextContext()
    @State private var isFormattingPalettePresented = false
    @State private var hasInitialized = false

    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // macOS: Compact toolbar
            HStack(spacing: 8) {
                RichTextStyle.ToggleGroup(context: richTextContext)

                Divider()
                    .frame(height: 20)

                RichTextAlignment.Picker(selection: $richTextContext.textAlignment)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()
            #endif

            // Rich text editor for notes with transparent background
            RichTextEditor(
                text: $viewModel.attributedNotes,
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
            // iOS: Minimal toolbar at the bottom
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 16) {
                    // Quick style buttons
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

                    Spacer()

                    Button {
                        isFormattingPalettePresented = true
                    } label: {
                        Image(systemName: "textformat")
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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
            viewModel.attributedNotes = newValue
        }
        #if os(iOS)
        .sheet(isPresented: $isFormattingPalettePresented) {
            FormattingPalette(context: richTextContext)
        }
        #endif
    }

    private func setupContext() {
        richTextContext.setAttributedString(to: viewModel.attributedNotes)

        if viewModel.attributedNotes.string.isEmpty {
            richTextContext.fontName = "Helvetica"
            richTextContext.fontSize = 14
        }
    }

    private func saveContent() {
        // Ensure the latest content from the editor is saved
        viewModel.attributedNotes = richTextContext.attributedString
        viewModel.saveChanges()
    }
}

#if DEBUG
#Preview {
    let docItem = ManuscriptDocument.Document(
        title: "Sample Document",
        notes: "Sample notes for this chapter.",
        content: "Sample content"
    )
    let viewModel = DocumentViewModel()
    return NotesTab(viewModel: DocumentDetailViewModel(document: docItem, documentViewModel: viewModel))
}
#endif
