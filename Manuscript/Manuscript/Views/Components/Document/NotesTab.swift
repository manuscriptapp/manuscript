import SwiftUI
import RichTextKit
#if os(iOS)
import UIKit
#endif

struct NotesTab: View {
    @ObservedObject var viewModel: DocumentDetailViewModel
    @StateObject private var richTextContext = RichTextContext()
    @State private var hasInitialized = false
    #if os(iOS)
    @State private var textViewRef: UITextView? = nil
    #endif

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
                    #else
                    if let uiTextView = textView as? UITextView {
                        DispatchQueue.main.async {
                            textViewRef = uiTextView
                            setupKeyboardToolbar(for: uiTextView)
                        }
                    }
                    #endif
                }
            )
            .focusedValue(\.richTextContext, richTextContext)
            .richTextEditorStyle(RichTextEditorStyle(backgroundColor: .clear))
            .background(.clear)
            .scrollContentBackground(.hidden)
            .padding()
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
        notes: "Sample notes for this chapter.",
        content: "Sample content"
    )
    let viewModel = DocumentViewModel()
    return NotesTab(viewModel: DocumentDetailViewModel(document: docItem, documentViewModel: viewModel))
}
#endif
