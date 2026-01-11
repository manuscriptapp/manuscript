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
struct NotesTabPreview: PreviewProvider {
    static var previews: some View {
        let document = LiteratiDocument()
        document.title = "Sample Project"
        document.author = "Sample Author"
        let docItem = LiteratiDocument.Document(id: UUID(), title: "Sample Document", notes: "Sample notes", content: "Sample content")
        
        return NotesTab(viewModel: DocumentDetailViewModel(document: docItem, literatiViewModel: LiteratiViewModel(document: document)))
    }
}
#endif 
