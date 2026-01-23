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
    @State private var isContentExpanded: Bool = true
    @State private var isProgressExpanded: Bool = true
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
            // Binder - everything related to your story
            Section(isExpanded: $isContentExpanded) {
                // Draft folder
                FolderItemView(
                    folder: viewModel.rootFolder,
                    viewModel: viewModel,
                    detailSelection: typedSelection
                )

                // Characters in a disclosure group
                DisclosureGroup(isExpanded: $isCharactersExpanded) {
                    ForEach(viewModel.characters) { character in
                        NavigationLink(value: DetailSelection.character(character)) {
                            Label {
                                Text(character.name)
                            } icon: {
                                Image(systemName: "person")
                                    .foregroundStyle(Color(red: 0.7, green: 0.2, blue: 0.3)) // Rose/maroon
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
                            .foregroundStyle(Color(red: 0.7, green: 0.2, blue: 0.3)) // Rose/maroon
                    }
                    .badge(viewModel.characters.count)
                }

                // Locations in a disclosure group
                DisclosureGroup(isExpanded: $isLocationsExpanded) {
                    ForEach(viewModel.locations) { location in
                        NavigationLink(value: DetailSelection.location(location)) {
                            Label {
                                Text(location.name)
                            } icon: {
                                Image(systemName: "mappin")
                                    .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.35))
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

                    NavigationLink(value: DetailSelection.worldMap) {
                        Label("World Map", systemImage: "map")
                            .font(.callout)
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2)) // Brown
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                    .padding(.top, 2)
                } label: {
                    Label {
                        Text("Locations")
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Color(red: 0.2, green: 0.55, blue: 0.35))
                    }
                    .badge(viewModel.locations.count)
                }

                // Research folder
                FolderItemView(
                    folder: viewModel.researchFolder,
                    viewModel: viewModel,
                    detailSelection: typedSelection
                )

                // Trash folder
                FolderItemView(
                    folder: viewModel.trashFolder,
                    viewModel: viewModel,
                    detailSelection: typedSelection
                )
            } header: {
                Text("Binder")
            }

            // Progress - tracking your writing
            Section(isExpanded: $isProgressExpanded) {
                // Calendar (Writing History)
                NavigationLink(value: DetailSelection.writingHistory) {
                    Label {
                        Text("Calendar")
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.brown)
                    }
                }

                // Writing targets (if set)
                if let draftTarget = viewModel.document.targets.draftWordCount {
                    WritingTargetProgressView(
                        title: "Draft Progress",
                        currentWords: viewModel.rootFolder.totalWordCount,
                        targetWords: draftTarget,
                        style: .linear
                    )
                }
                if let sessionTarget = viewModel.document.targets.sessionWordCount {
                    WritingTargetProgressView(
                        title: "Session Progress",
                        currentWords: viewModel.document.writingHistory.todayEntry?.wordsWritten ?? 0,
                        targetWords: sessionTarget,
                        style: .linear
                    )
                }

                // Stats
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
            } header: {
                Text("Progress")
            }
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

                    Divider()

                    NavigationLink(value: DetailSelection.projectInfo) {
                        Label("Project Info", systemImage: "info.circle")
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

                    NavigationLink(value: DetailSelection.projectInfo) {
                        Label("Project Info", systemImage: "info.circle")
                    }

                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
            #endif
        }
        .alert("Snapshot Created", isPresented: $viewModel.showSnapshotConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A snapshot of \"\(viewModel.lastSnapshotDocumentTitle)\" has been saved. View it in the Snapshots tab of the document inspector.")
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
