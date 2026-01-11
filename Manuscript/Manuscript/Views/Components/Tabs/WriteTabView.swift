import SwiftUI

struct WriteTabView: View {
    let document: LiteratiDocument.Document
    @Binding var editedContent: String
    @Binding var isGenerating: Bool
    @Binding var generationType: DocumentDetailViewModel.GenerationType
    @Binding var showResult: Bool
    @Binding var generatedText: String
    @Binding var generationError: Error?
    
    var body: some View {
        ScrollView {
            TextEditor(text: $editedContent)
                .frame(maxWidth: .infinity, minHeight: 300)
                .plainTextEditor()
                .padding()
                .padding(.bottom, 120)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                VStack(spacing: 8) {
                    Button(action: {
                        Task {
                            isGenerating = true
                            generationType = .content
                            do {
                                generatedText = try await TextGenerationService.shared
                                    .generateText(
                                        prompt: AIPromptTemplates.Chapter.generateContent(
                                            outline: document.outline,
                                            guidelines: document.outlinePrompt
                                        )
                                    )
                                isGenerating = false
                                showResult = true
                            }
                            catch {
                                generationError = error
                                isGenerating = false
                                showResult = true
                            }
                        }
                    }) {
                        if isGenerating && generationType == .content {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Generating...")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        else {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Generate Chapter")
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isGenerating || document.outline.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .background(.bar)
        }
    }
}

#if DEBUG
struct WriteTabViewPreview: PreviewProvider {
    static var previews: some View {
        let document = LiteratiDocument()
        document.title = "Sample Project"
        document.author = "Sample Author"
        let docItem = LiteratiDocument.Document(id: UUID(), title: "Sample Document", notes: "Sample notes", content: "Sample content")
        
        return WriteTabView(
            document: docItem,
            editedContent: .constant("Sample content"),
            isGenerating: .constant(false),
            generationType: .constant(.content),
            showResult: .constant(false),
            generatedText: .constant(""),
            generationError: .constant(nil)
        )
    }
}
#endif 
