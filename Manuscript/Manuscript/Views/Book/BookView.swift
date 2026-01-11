import SwiftUI

struct BookView: View {
    @Binding var document: LiteratiDocument
    @ObservedObject var literatiViewModel: LiteratiViewModel
    @Binding var detailSelection: DetailSelection?
    @State private var isAddFolderSheetPresented = false
    @State private var isAddDocumentSheetPresented = false
    @State private var isAddCharacterSheetPresented = false
    @State private var isAddLocationSheetPresented = false
    
    init(document: Binding<LiteratiDocument>, literatiViewModel: LiteratiViewModel, detailSelection: Binding<DetailSelection?>) {
        self._document = document
        self.literatiViewModel = literatiViewModel
        self._detailSelection = detailSelection
    }
    
    var body: some View {
        // Create a typed binding to help with type inference
        let typedSelection: Binding<DetailSelection?> = $detailSelection
        
        // Create the content as a separate variable
        let listContent = Group {
            #if os(iOS)
            Text(document.title)
                .font(.title)
                .bold()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            #endif
            
            // Create the folder tree view as a separate component
            FolderItemView(
                folder: document.rootFolder,
                literatiViewModel: literatiViewModel,
                detailSelection: typedSelection
            )
        }
        
        // Use the pre-defined content in the List
        List(selection: typedSelection) {
            listContent
        }
        .listStyle(.sidebar)
        .navigationTitle(Text(document.title))
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Menu {
                    Button(action: { isAddFolderSheetPresented.toggle() }) {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }
                    
                    Button(action: { isAddDocumentSheetPresented.toggle() }) {
                        Label("Add Document", systemImage: "doc.badge.plus")
                    }
                    
                    Divider()
                    
                    Button(action: { isAddCharacterSheetPresented.toggle() }) {
                        Label("Add Character", systemImage: "person.badge.plus")
                    }
                    
                    Button(action: { isAddLocationSheetPresented.toggle() }) {
                        Label("Add Location", systemImage: "mappin.and.ellipse")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddFolderSheetPresented) {
            AddFolderSheet(
                document: document,
                initialFolder: literatiViewModel.currentFolder,
                literatiViewModel: literatiViewModel
            )
        }
        .sheet(isPresented: $isAddDocumentSheetPresented) {
            AddDocumentSheet(
                document: document,
                initialFolder: literatiViewModel.currentFolder,
                literatiViewModel: literatiViewModel
            )
        }
        .sheet(isPresented: $isAddCharacterSheetPresented) {
            AddCharacterSheet(literatiViewModel: literatiViewModel)
        }
        .sheet(isPresented: $isAddLocationSheetPresented) {
            AddLocationSheet(literatiViewModel: literatiViewModel)
        }
        .alert(literatiViewModel.renameAlertTitle, isPresented: $literatiViewModel.isRenameAlertPresented) {
            TextField("Name", text: $literatiViewModel.newItemName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                literatiViewModel.performRename()
            }
        } message: {
            Text("Enter new name")
        }
    }
}

