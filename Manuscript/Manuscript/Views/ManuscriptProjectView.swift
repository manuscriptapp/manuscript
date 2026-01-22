import SwiftUI
import SwiftData

struct ManuscriptProjectView: View {
    @Binding var document: ManuscriptDocument
    @StateObject private var viewModel = DocumentViewModel()
    @State private var detailSelection: DetailSelection?
    @State private var isAddDocumentSheetPresented = false
    @State private var isAddFolderSheetPresented = false
    @State private var isAddCharacterSheetPresented = false
    @State private var isAddLocationSheetPresented = false
    @State private var showOnboarding = false
    @State private var navigationTitle = ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar with project structure
            ProjectSidebar(
                viewModel: viewModel,
                detailSelection: $detailSelection,
                isAddDocumentSheetPresented: $isAddDocumentSheetPresented,
                isAddFolderSheetPresented: $isAddFolderSheetPresented,
                isAddCharacterSheetPresented: $isAddCharacterSheetPresented,
                isAddLocationSheetPresented: $isAddLocationSheetPresented
            )
            #if os(macOS)
            .frame(minWidth: 190)
            #endif
        } detail: {
            // Detail view based on selection
            if detailSelection != nil {
                DetailContentView(
                    viewModel: viewModel,
                    selection: $detailSelection
                )
            } else {
                // Default empty state or project overview
                ProjectOverview(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isAddDocumentSheetPresented) {
            AddDocumentSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $isAddFolderSheetPresented) {
            AddFolderSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $isAddCharacterSheetPresented) {
            AddCharacterSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $isAddLocationSheetPresented) {
            AddLocationSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled(!UserDefaults.standard.bool(forKey: "hasSeenOnboarding"))
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
        }
        .onAppear {
            viewModel.bind(to: $document)
            checkOnboarding()
            updateNavigationTitle()
            updateColumnVisibility()
        }
        .onChange(of: document) { _, newDocument in
            viewModel.syncWithDocument(newDocument)
            updateNavigationTitle()
        }
        .onChange(of: detailSelection) { _, _ in
            updateNavigationTitle()
            updateColumnVisibility()
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
        #if os(iOS)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if detailSelection != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        detailSelection = nil
                        updateColumnVisibility()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                }
            }
        }
        #endif
    }

    private func checkOnboarding() {
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            showOnboarding = true
        }
    }

    private func updateNavigationTitle() {
        switch detailSelection {
        case .projectInfo:
            navigationTitle = "Project Info"
        case .characters:
            navigationTitle = "Characters"
        case .locations:
            navigationTitle = "Locations"
        case .writingHistory:
            navigationTitle = "Writing History"
        case .folder(let folder):
            navigationTitle = folder.title
        case .document(let document):
            let currentTitle = viewModel.findDocument(withId: document.id)?.title ?? document.title
            navigationTitle = currentTitle.isEmpty ? "Untitled Document" : currentTitle
        case .character(let character):
            navigationTitle = character.name
        case .location(let location):
            navigationTitle = location.name
        case .none:
            navigationTitle = viewModel.document.title.isEmpty ? "Untitled Project" : viewModel.document.title
        }
    }

    private func updateColumnVisibility() {
        #if os(iOS)
        columnVisibility = detailSelection == nil ? .automatic : .detailOnly
        #else
        columnVisibility = .all
        #endif
    }
}

#Preview {
    ManuscriptProjectView(document: .constant(ManuscriptDocument.sampleDocument))
}

// Helper extension to create a sample document for previews
extension ManuscriptDocument {
    static var sampleDocument: ManuscriptDocument {
        var document = ManuscriptDocument()
        document.title = "Sample Project"
        document.author = "Sample Author"
        document.metaDescription = "This is a sample project for previews"
        document.genre = "Fiction"
        document.style = "Modern"
        document.synopsis = "A sample synopsis for preview purposes."

        // Add sample characters
        var character1 = ManuscriptCharacter(name: "John Doe", gender: .male)
        character1.age = 35

        var character2 = ManuscriptCharacter(name: "Jane Smith", gender: .female)
        character2.age = 28

        document.characters = [character1, character2]

        // Add sample locations
        let location1 = ManuscriptLocation(name: "New York City", latitude: 40.7128, longitude: -74.0060)
        let location2 = ManuscriptLocation(name: "Paris", latitude: 48.8566, longitude: 2.3522)

        document.locations = [location1, location2]

        // Create a sample folder structure
        var folder1 = ManuscriptFolder(title: "Part 1")
        var folder2 = ManuscriptFolder(title: "Part 2")

        // Add some documents
        let doc1 = ManuscriptDocument.Document(
            title: "Chapter 1",
            outline: "Introduction to the main character",
            content: "It was a dark and stormy night..."
        )

        let doc2 = ManuscriptDocument.Document(
            title: "Chapter 2",
            outline: "The journey begins",
            content: "The morning sun revealed the aftermath..."
        )

        folder1.documents.append(doc1)
        folder2.documents.append(doc2)

        document.rootFolder.subfolders.append(folder1)
        document.rootFolder.subfolders.append(folder2)

        return document
    }
}
