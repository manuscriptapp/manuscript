import SwiftUI
import SwiftData

struct ReadTabView: View {
    let document: Document
    
    var body: some View {
        ScrollView {
            Text(document.content)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

#if DEBUG
#Preview {
    let container = PreviewData.container
    let context = container.mainContext
    let book = PreviewData.heroJourneyBook
    let document = book.rootFolder?.documents?.first ?? Document(title: "Preview Document")
    
    return ReadTabView(document: document)
        .modelContainer(container)
}
#endif 