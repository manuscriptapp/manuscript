import SwiftUI
import SwiftData
import Combine

struct ManuscriptProjectView: View {
    @Binding var document: ManuscriptDocument
    @StateObject private var documentManager: DocumentManager
    @StateObject private var manuscriptViewModel: ManuscriptViewModel
    @State private var detailSelection: DetailSelection?
    @State private var isAddDocumentSheetPresented = false
    @State private var isAddFolderSheetPresented = false
    @State private var isAddCharacterSheetPresented = false
    @State private var isAddLocationSheetPresented = false
    @State private var showOnboarding = false

    init(document: Binding<ManuscriptDocument>) {
        self._document = document
        self._documentManager = StateObject(wrappedValue: DocumentManager(document: document.wrappedValue))
        self._manuscriptViewModel = StateObject(wrappedValue: ManuscriptViewModel(document: document.wrappedValue))
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar with project structure
            ProjectSidebar(
                documentManager: documentManager,
                literatiViewModel: manuscriptViewModel,
                detailSelection: $detailSelection,
                isAddDocumentSheetPresented: $isAddDocumentSheetPresented,
                isAddFolderSheetPresented: $isAddFolderSheetPresented,
                isAddCharacterSheetPresented: $isAddCharacterSheetPresented,
                isAddLocationSheetPresented: $isAddLocationSheetPresented
            )
            #if os(macOS)
            .frame(minWidth: 190)
            #endif
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        } detail: {
            // Detail view based on selection
            if let selection = detailSelection {
                DetailContentView(
                    documentManager: documentManager,
                    selection: selection
                )
            } else {
                // Default empty state or project overview
                ProjectOverview(documentManager: documentManager)
            }
        }
        .sheet(isPresented: $isAddDocumentSheetPresented) {
            AddDocumentSheet(
                document: documentManager.document,
                initialFolder: documentManager.currentFolder,
                literatiViewModel: manuscriptViewModel
            )
        }
        .sheet(isPresented: $isAddFolderSheetPresented) {
            AddFolderSheet(
                document: documentManager.document,
                initialFolder: documentManager.currentFolder,
                literatiViewModel: manuscriptViewModel
            )
        }
        .sheet(isPresented: $isAddCharacterSheetPresented) {
            AddCharacterSheet(
                literatiViewModel: manuscriptViewModel
            )
        }
        .sheet(isPresented: $isAddLocationSheetPresented) {
            AddLocationSheet(
                literatiViewModel: manuscriptViewModel
            )
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled(!UserDefaults.standard.bool(forKey: "hasSeenOnboarding"))
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
        }
        .onAppear {
            checkOnboarding()
        }
        .onChange(of: document) { newDocument in
            documentManager.document = newDocument
            manuscriptViewModel.document = newDocument
            documentManager.navigateToRootFolder()
        }
        .onReceive(manuscriptViewModel.objectWillChange) { _ in
            // Sync changes to DocumentManager (triggers sidebar refresh) and DocumentGroup binding
            DispatchQueue.main.async {
                documentManager.objectWillChange.send()
                document = manuscriptViewModel.document
            }
        }
    }

    private func checkOnboarding() {
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            showOnboarding = true
        }
    }
}

#Preview {
    ManuscriptProjectView(document: .constant(ManuscriptDocument.sampleDocument))
}

// Helper extension to create a sample document for previews
extension ManuscriptDocument {
    static var sampleDocument: ManuscriptDocument {
        let document = ManuscriptDocument()
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

// Type alias for backward compatibility
typealias LiteratiProjectView = ManuscriptProjectView
