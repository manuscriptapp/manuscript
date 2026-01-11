import SwiftUI

struct ProjectSidebar: View {
    @ObservedObject var documentManager: DocumentManager
    @ObservedObject var literatiViewModel: LiteratiViewModel
    @Binding var detailSelection: DetailSelection?
    @Binding var isAddDocumentSheetPresented: Bool
    @Binding var isAddFolderSheetPresented: Bool
    @Binding var isAddCharacterSheetPresented: Bool
    @Binding var isAddLocationSheetPresented: Bool
    @State private var isCharactersExpanded: Bool = false
    @State private var isLocationsExpanded: Bool = false
    
    var body: some View {
        // Create a typed binding to help with type inference
        let typedSelection: Binding<DetailSelection?> = $detailSelection
        
        // Create the content as a separate variable
        let listContent = Group {
            #if os(iOS)
            Text(documentManager.document.title)
                .font(.title)
                .bold()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            #endif
            
            
            // Folder structure
            Section("Content") {
                FolderItemView(
                    folder: documentManager.document.rootFolder,
                    literatiViewModel: literatiViewModel,
                    detailSelection: typedSelection
                )
                .id(documentManager.document.rootFolder.totalDocumentCount)
            }
            
            // Basic project info
            Section("Project") {
                NavigationLink(value: DetailSelection.projectInfo) {
                    Label("Project Info", systemImage: "info.circle")
                }
                
                // Characters in a disclosure group
                DisclosureGroup(isExpanded: $isCharactersExpanded) {
                    ForEach(documentManager.document.characters) { character in
                        NavigationLink(value: DetailSelection.character(character)) {
                            Label(character.name, systemImage: "person")
                        }
                    }
                    
                    Button {
                        isAddCharacterSheetPresented.toggle()
                    } label: {
                        Label("Add Character", systemImage: "plus")
                            .font(.callout)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.borderless)
                    .padding(.leading, 4)
                    .padding(.top, 4)
                } label: {
                    Label("Characters", systemImage: "person.2")
                        .badge(documentManager.document.characters.count)
                }
                
                // Locations in a disclosure group
                DisclosureGroup(isExpanded: $isLocationsExpanded) {
                    ForEach(documentManager.document.locations) { location in
                        NavigationLink(value: DetailSelection.location(location)) {
                            Label(location.name, systemImage: "mappin")
                        }
                    }
                    
                    Button {
                        isAddLocationSheetPresented.toggle()
                    } label: {
                        Label("Add Location", systemImage: "plus")
                            .font(.callout)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.borderless)
                    .padding(.leading, 4)
                    .padding(.top, 4)
                } label: {
                    Label("Locations", systemImage: "mappin.and.ellipse")
                        .badge(documentManager.document.locations.count)
                }
            }
            
        }
        
        // Use the pre-defined content in the List
        List(selection: typedSelection) {
            listContent
        }
        .listStyle(.sidebar)
        #if os(macOS)
        .navigationTitle(documentManager.document.title.isEmpty ? "Untitled" : documentManager.document.title)
        #endif
        .toolbar {
            #if os(macOS)
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
            #else
            ToolbarItem(placement: .bottomBar) {
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
            #endif
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
