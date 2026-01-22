import SwiftUI
import SwiftData

#if os(iOS)
/// Hides the parent navigation bar from DocumentGroup's implicit NavigationStack
struct NavigationBarHider: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = NavigationBarHiderController()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? NavigationBarHiderController)?.hideNavigationBar()
    }
}

class NavigationBarHiderController: UIViewController {
    private var observer: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hideNavigationBar()

        // Keep checking periodically
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.hideNavigationBar()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.hideNavigationBar()
        }
    }

    func hideNavigationBar() {
        // Try to find and hide all parent navigation controllers
        var current: UIViewController? = self
        while let vc = current {
            if let nav = vc.navigationController {
                nav.setNavigationBarHidden(true, animated: false)
                nav.navigationBar.isHidden = true
            }
            current = vc.parent
        }

        // Also try via responder chain
        var responder: UIResponder? = self
        while let r = responder {
            if let nav = r as? UINavigationController {
                nav.setNavigationBarHidden(true, animated: false)
                nav.navigationBar.isHidden = true
            }
            responder = r.next
        }
    }
}
#endif

struct ManuscriptProjectView: View {
    @Binding var document: ManuscriptDocument
    @StateObject private var viewModel = DocumentViewModel()
    @State private var detailSelection: DetailSelection?
    @State private var isAddDocumentSheetPresented = false
    @State private var isAddFolderSheetPresented = false
    @State private var isAddCharacterSheetPresented = false
    @State private var isAddLocationSheetPresented = false
    @State private var showOnboarding = false
    @State private var showSettings = false
    @State private var showReadingMode = false

    var body: some View {
        mainContent
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
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showSettings = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showReadingMode) {
                NavigationStack {
                    ProjectReadingView(viewModel: viewModel)
                        .navigationTitle(viewModel.document.title.isEmpty ? "Untitled" : viewModel.document.title)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showReadingMode = false
                                }
                            }
                        }
                }
            }
            .onAppear {
                viewModel.bind(to: $document)
                checkOnboarding()
            }
            .onChange(of: document) { _, newDocument in
                viewModel.syncWithDocument(newDocument)
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

    @ViewBuilder
    private var mainContent: some View {
        #if os(iOS)
        NavigationStack {
            ProjectSidebar(
                viewModel: viewModel,
                detailSelection: $detailSelection,
                isAddDocumentSheetPresented: $isAddDocumentSheetPresented,
                isAddFolderSheetPresented: $isAddFolderSheetPresented,
                isAddCharacterSheetPresented: $isAddCharacterSheetPresented,
                isAddLocationSheetPresented: $isAddLocationSheetPresented,
                showSettings: $showSettings,
                showReadingMode: $showReadingMode
            )
            .navigationDestination(for: DetailSelection.self) { selection in
                DetailContentView(
                    viewModel: viewModel,
                    selection: .constant(selection)
                )
            }
        }
        .background(NavigationBarHider())
        #else
        NavigationSplitView {
            ProjectSidebar(
                viewModel: viewModel,
                detailSelection: $detailSelection,
                isAddDocumentSheetPresented: $isAddDocumentSheetPresented,
                isAddFolderSheetPresented: $isAddFolderSheetPresented,
                isAddCharacterSheetPresented: $isAddCharacterSheetPresented,
                isAddLocationSheetPresented: $isAddLocationSheetPresented
            )
            .navigationSplitViewColumnWidth(min: 190, ideal: 250, max: 400)
        } detail: {
            if detailSelection != nil {
                DetailContentView(
                    viewModel: viewModel,
                    selection: $detailSelection
                )
            } else {
                ProjectOverview(viewModel: viewModel)
            }
        }
        #endif
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
