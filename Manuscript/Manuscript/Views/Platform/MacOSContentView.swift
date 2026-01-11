import SwiftUI

struct MacOSContentView: View {
    @ObservedObject var literatiViewModel: LiteratiViewModel
    @Binding var detailSelection: DetailSelection?
    @Binding var isAddBookSheetPresented: Bool
    
    var body: some View {
        NavigationSplitView {
            VStack {
                BookView(
                    document: $literatiViewModel.document,
                    literatiViewModel: literatiViewModel,
                    detailSelection: $detailSelection
                )
                .frame(minWidth: 190)
            }
        } detail: {
            DetailContentView(selection: detailSelection)
        }
    }
}

