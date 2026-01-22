import SwiftUI

struct ProjectSidebar: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Binding var detailSelection: DetailSelection?
    @Binding var isAddDocumentSheetPresented: Bool
    @Binding var isAddFolderSheetPresented: Bool
    @Binding var isAddCharacterSheetPresented: Bool
    @Binding var isAddLocationSheetPresented: Bool
    @Binding var showSettings: Bool
    @Binding var showReadingMode: Bool
    @State private var isCharactersExpanded: Bool = false
    @State private var isLocationsExpanded: Bool = false

    init(
        viewModel: DocumentViewModel,
        detailSelection: Binding<DetailSelection?>,
        isAddDocumentSheetPresented: Binding<Bool>,
        isAddFolderSheetPresented: Binding<Bool>,
        isAddCharacterSheetPresented: Binding<Bool>,
        isAddLocationSheetPresented: Binding<Bool>,
        showSettings: Binding<Bool> = .constant(false),
        showReadingMode: Binding<Bool> = .constant(false)
    ) {
        self.viewModel = viewModel
        self._detailSelection = detailSelection
        self._isAddDocumentSheetPresented = isAddDocumentSheetPresented
        self._isAddFolderSheetPresented = isAddFolderSheetPresented
        self._isAddCharacterSheetPresented = isAddCharacterSheetPresented
        self._isAddLocationSheetPresented = isAddLocationSheetPresented
        self._showSettings = showSettings
        self._showReadingMode = showReadingMode
    }
    
    var body: some View {
        // Create a typed binding to help with type inference
        let typedSelection: Binding<DetailSelection?> = $detailSelection

        // Create the content as a separate variable
        let listContent = Group {
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

                // Calendar
                NavigationLink(value: DetailSelection.writingHistory) {
                    Label {
                        Text("Calendar")
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.brown)
                    }
                }
            }

            // Progress Section
            #if os(iOS)
            Section("Progress") {
                ZStack {
                    NavigationLink(value: DetailSelection.writingHistory) {
                        EmptyView()
                    }
                    .opacity(0)

                    VStack(spacing: 10) {
                        SidebarStatRow(
                            icon: "character.cursor.ibeam",
                            color: .blue,
                            title: "Total Words",
                            value: viewModel.rootFolder.totalWordCount.formatted()
                        )
                        SidebarStatRow(
                            icon: "calendar.badge.clock",
                            color: .green,
                            title: "Days Written",
                            value: "\(viewModel.document.writingHistory.daysWritten)"
                        )
                        SidebarStatRow(
                            icon: "flame.fill",
                            color: viewModel.document.writingHistory.currentStreak > 0 ? .orange : .secondary,
                            title: "Current Streak",
                            value: "\(viewModel.document.writingHistory.currentStreak) days"
                        )
                        SidebarStatRow(
                            icon: "trophy.fill",
                            color: .yellow,
                            title: "Longest Streak",
                            value: "\(viewModel.document.writingHistory.longestStreak) days"
                        )
                        SidebarStatRow(
                            icon: "chart.line.uptrend.xyaxis",
                            color: .purple,
                            title: "Avg Words/Day",
                            value: viewModel.document.writingHistory.averageWordsPerDay.formatted()
                        )
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 4)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            #else
            Section("Progress") {
                SidebarStatRow(
                    icon: "character.cursor.ibeam",
                    color: .blue,
                    title: "Total Words",
                    value: viewModel.rootFolder.totalWordCount.formatted()
                )

                SidebarStatRow(
                    icon: "calendar.badge.clock",
                    color: .green,
                    title: "Days Written",
                    value: "\(viewModel.document.writingHistory.daysWritten)"
                )

                SidebarStatRow(
                    icon: "flame.fill",
                    color: viewModel.document.writingHistory.currentStreak > 0 ? .orange : .secondary,
                    title: "Current Streak",
                    value: "\(viewModel.document.writingHistory.currentStreak) days"
                )

                SidebarStatRow(
                    icon: "trophy.fill",
                    color: .yellow,
                    title: "Longest Streak",
                    value: "\(viewModel.document.writingHistory.longestStreak) days"
                )

                SidebarStatRow(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple,
                    title: "Avg Words/Day",
                    value: viewModel.document.writingHistory.averageWordsPerDay.formatted()
                )
            }
            #endif
        }
        
        // Use the pre-defined content in the List
        // On iOS with NavigationStack, don't use selection binding - NavigationLinks handle navigation
        // On macOS with NavigationSplitView, use selection binding for sidebar selection
        sidebarList(content: listContent, selection: typedSelection)
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .navigation) {
                Menu {
                    Button(action: { isAddFolderSheetPresented.toggle() }) {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }

                    Button(action: { addDocumentToSelectedFolder() }) {
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
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }

            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }

            ToolbarItem(placement: .bottomBar) {
                Button {
                    showReadingMode = true
                } label: {
                    Label("Read", systemImage: "book")
                }
            }

            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showReadingMode = true }) {
                        Label("Read Mode", systemImage: "book")
                    }

                    Divider()

                    Button(action: { isAddFolderSheetPresented.toggle() }) {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }

                    Button(action: { addDocumentToSelectedFolder() }) {
                        Label("Add Document", systemImage: "doc.badge.plus")
                    }

                    Divider()

                    Button(action: { isAddCharacterSheetPresented.toggle() }) {
                        Label("Add Character", systemImage: "person.badge.plus")
                    }

                    Button(action: { isAddLocationSheetPresented.toggle() }) {
                        Label("Add Location", systemImage: "mappin.and.ellipse")
                    }

                    Divider()

                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
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

    /// Creates a new untitled document in the currently selected folder, or root folder if none selected
    private func addDocumentToSelectedFolder() {
        // Determine target folder based on current selection
        let targetFolder: ManuscriptFolder
        if case .folder(let folder) = detailSelection {
            targetFolder = folder
        } else if case .document(let doc) = detailSelection {
            // If a document is selected, find its parent folder
            targetFolder = viewModel.findParentFolder(of: doc) ?? viewModel.rootFolder
        } else {
            targetFolder = viewModel.rootFolder
        }
        viewModel.addUntitledDocument(to: targetFolder)
    }

    @ViewBuilder
    private func sidebarList<Content: View>(content: Content, selection: Binding<DetailSelection?>) -> some View {
        #if os(iOS)
        List {
            content
        }
        .listStyle(.sidebar)
        #else
        List(selection: selection) {
            content
        }
        .listStyle(.sidebar)
        .navigationTitle(viewModel.documentTitle.isEmpty ? "Untitled" : viewModel.documentTitle)
        #endif
    }
}

// MARK: - Sidebar Stat Row

struct SidebarStatRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
} 
