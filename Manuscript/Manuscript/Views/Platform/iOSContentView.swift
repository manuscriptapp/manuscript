import SwiftUI

struct IOSContentView: View {
    @ObservedObject var literatiViewModel: LiteratiViewModel
    @Binding var detailSelection: DetailSelection?
    @Binding var isAddBookSheetPresented: Bool
    @State var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            LibraryView(viewModel: literatiViewModel, detailSelection: $detailSelection)
        } content: {
            TabView {
                BookView(
                    document: $literatiViewModel.document,
                    literatiViewModel: literatiViewModel,
                    detailSelection: $detailSelection
                )
                .tabItem {
                    Label("Plan", systemImage: "map")
                }
                
                // Write tab
                if let firstDocument = literatiViewModel.document.rootFolder.documents.first ?? 
                                      (literatiViewModel.document.rootFolder.subfolders.first?.documents.first) {
                    WriteTab(viewModel: DocumentDetailViewModel(document: firstDocument, literatiViewModel: literatiViewModel))
                        .tabItem {
                            Label("Write", systemImage: "pencil")
                        }
                } else {
                    ContentUnavailableView {
                        Label("No Documents", systemImage: "doc")
                    } description: {
                        Text("Create a document to start writing")
                    }
                    .tabItem {
                        Label("Write", systemImage: "pencil")
                    }
                }
                
                // Read tab
                List {
                    let rootItem = FolderContentBuilder(
                        document: literatiViewModel.document,
                        literatiViewModel: literatiViewModel
                    ).buildTree(from: literatiViewModel.document.rootFolder)
                    ReadContentView(item: rootItem, isRoot: true)
                }
                .listStyle(.plain)
                .tabItem {
                    Label("Read", systemImage: "book")
                }
                
                // Export tab
                ExportView(document: literatiViewModel.document)
                    .tabItem {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
            }
        } detail: {
            if let detailSelection = detailSelection {
                DetailContentView(selection: detailSelection)
            } else {
                ContentUnavailableView {
                    Label("No Details", systemImage: "sidebar.right")
                } description: {
                    Text("Select an item from the sidebar to view details")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
