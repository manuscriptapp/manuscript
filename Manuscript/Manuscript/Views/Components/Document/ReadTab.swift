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
#Preview {
    let docItem = ManuscriptDocument.Document(
        title: "Sample Document",
        notes: "Sample notes",
        content: "Sample content"
    )
    let viewModel = DocumentViewModel()
    return ReadTab(viewModel: DocumentDetailViewModel(document: docItem, documentViewModel: viewModel))
}
#endif 
