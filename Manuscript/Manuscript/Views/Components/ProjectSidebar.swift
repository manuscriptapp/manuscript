import SwiftUI

struct ProjectSidebar: View {
    @ObservedObject var viewModel: DocumentViewModel
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
            Text(viewModel.document.title)
                .font(.title)
                .bold()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            #endif
            
            
            // Folder structure
            Section("Content") {
                FolderItemView(
                    folder: viewModel.rootFolder,
                    viewModel: viewModel,
                    detailSelection: typedSelection
                )
            }
            
            // Basic project info
            Section("Project") {
                NavigationLink(value: DetailSelection.projectInfo) {
                    Label {
                        Text("Project Info")
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.brown)
                    }
                }

                // Characters in a disclosure group
                DisclosureGroup(isExpanded: $isCharactersExpanded) {
                    ForEach(viewModel.document.characters) { character in
                        NavigationLink(value: DetailSelection.character(character)) {
                            Label {
                                Text(character.name)
                            } icon: {
                                Image(systemName: "person")
                                    .foregroundStyle(.brown)
                            }
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
                    Label {
                        Text("Characters")
                    } icon: {
                        Image(systemName: "person.2")
                            .foregroundStyle(.brown)
                    }
                    .badge(viewModel.document.characters.count)
                }

                // Locations in a disclosure group
                DisclosureGroup(isExpanded: $isLocationsExpanded) {
                    ForEach(viewModel.document.locations) { location in
                        NavigationLink(value: DetailSelection.location(location)) {
                            Label {
                                Text(location.name)
                            } icon: {
                                Image(systemName: "mappin")
                                    .foregroundStyle(.brown)
                            }
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
                    Label {
                        Text("Locations")
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.brown)
                    }
                    .badge(viewModel.document.locations.count)
                }

                // Writing History
                NavigationLink(value: DetailSelection.writingHistory) {
                    Label {
                        Text("Writing History")
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(.brown)
                    }
                    .badge(viewModel.document.writingHistory.entries.count)
                }
            }
            
        }
        
        // Use the pre-defined content in the List
        List(selection: typedSelection) {
            listContent
        }
        .listStyle(.sidebar)
        #if os(macOS)
        .navigationTitle(viewModel.document.title.isEmpty ? "Untitled" : viewModel.document.title)
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
        .alert(viewModel.renameAlertTitle, isPresented: $viewModel.isRenameAlertPresented) {
            TextField("Name", text: $viewModel.newItemName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                viewModel.performRename()
            }
        } message: {
            Text("Enter new name")
        }
    }
} 
