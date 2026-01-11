import SwiftUI

struct ReadTab: View {
    @ObservedObject var viewModel: DocumentDetailViewModel
    
    var body: some View {
        ScrollView {
            Text(viewModel.document.content)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

#if DEBUG
struct ReadTabPreview: PreviewProvider {
    static var previews: some View {
        let document = LiteratiDocument()
        document.title = "Sample Project"
        document.author = "Sample Author"
        let docItem = LiteratiDocument.Document(id: UUID(), title: "Sample Document", notes: "Sample notes", content: "Sample content")
        
        return ReadTab(viewModel: DocumentDetailViewModel(document: docItem, literatiViewModel: LiteratiViewModel(document: document)))
    }
}
#endif 
