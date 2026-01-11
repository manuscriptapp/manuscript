import SwiftUI

struct NotesTab: View {
    @ObservedObject var viewModel: DocumentDetailViewModel
    
    var body: some View {
        ScrollView {
            TextEditor(text: $viewModel.editedNotes)
                .frame(maxWidth: .infinity, minHeight: 300)
                .plainTextEditor()
                .padding()
        }
    }
}

#if DEBUG
#Preview {
    let docItem = ManuscriptDocument.Document(
        title: "Sample Document",
        notes: "Sample notes",
        content: "Sample content"
    )
    let viewModel = DocumentViewModel()
    return NotesTab(viewModel: DocumentDetailViewModel(document: docItem, documentViewModel: viewModel))
}
#endif 
