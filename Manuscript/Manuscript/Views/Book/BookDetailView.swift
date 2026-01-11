import SwiftUI
import SwiftData

struct BookDetailView: View {
    var book: Book
    @Environment(\.modelContext) private var modelContext
    @State private var editedTitle: String
    @State private var editedAuthor: String
    @State private var editedDescription: String
    
    init(book: Book) {
        self.book = book
        _editedTitle = State(initialValue: book.title)
        _editedAuthor = State(initialValue: book.author)
        _editedDescription = State(initialValue: book.metaDescription)
    }
    
    var body: some View {
        FormContainerView {
            VStack(alignment: .leading, spacing: 24) {
                Group {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        TextField("Title", text: $editedTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Author")
                            .font(.headline)
                        TextField("Author", text: $editedAuthor)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    TextEditor(text: $editedDescription)
                        .borderedTextEditor()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Created")
                        .font(.headline)
                    Text(book.creationDate.formatted())
                        .foregroundStyle(.secondary)
                }
                
                if let templateId = book.templateId,
                   let template = BookTemplate.templates.first(where: { $0.id == templateId }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Template Used")
                            .font(.headline)
                        Text(template.name)
                            .font(.subheadline)
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    saveChanges()
                } label: {
                    Text("Save")
                }
            }
        }
    }
    
    private func saveChanges() {
        book.title = editedTitle
        book.author = editedAuthor
        book.metaDescription = editedDescription
        try? modelContext.save()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        BookDetailView(book: PreviewData.groupedBook)
    }
}
#endif
