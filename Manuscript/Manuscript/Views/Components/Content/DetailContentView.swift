import SwiftUI
import SwiftData

struct DetailContentView: View {
    // Make documentManager optional
    var documentManager: DocumentManager?
    let selection: DetailSelection?
    
    // For document-based architecture
    init(documentManager: DocumentManager, selection: DetailSelection?) {
        self.documentManager = documentManager
        self.selection = selection
    }
    
    // For backward compatibility with legacy views
    init(selection: DetailSelection?) {
        self.documentManager = nil
        self.selection = selection
    }
    
    var body: some View {
        if let selection = selection {
            // Check if we're using the document-based architecture
            if let documentManager = documentManager {
                // Document-based architecture view
                newDetailContent(for: selection, documentManager: documentManager)
            } else {
                // Legacy view - show a placeholder
                legacyDetailContent(for: selection)
            }
        } else {
            ContentUnavailableView("Select an Item", systemImage: "sidebar.left")
        }
    }
    
    @ViewBuilder
    private func newDetailContent(for selection: DetailSelection, documentManager: DocumentManager) -> some View {
        switch selection {
        case .projectInfo:
            ProjectInfoView(documentManager: documentManager)
        case .characters:
            CharactersView(documentManager: documentManager)
        case .locations:
            LocationsView(documentManager: documentManager)
        case .folder(let folder):
            FolderDetailView(folder: folder, documentManager: documentManager)
        case .document(let document):
            DocumentDetailView(document: document, literatiViewModel: LiteratiViewModel(document: documentManager.document))
        case .character(let character):
            CharacterDetailView(character: character, documentManager: documentManager)
        case .location(let location):
            LiteratiLocationDetailView(documentManager: documentManager, location: location)
        }
    }
    
    // Add a method to handle legacy DetailSelection cases
    @ViewBuilder
    private func legacyDetailContent(for selection: DetailSelection) -> some View {
        ContentUnavailableView {
            Label("Upgrade Required", systemImage: "exclamationmark.triangle")
        } description: {
            Text("This project is being migrated to use the new document-based architecture.")
        } actions: {
            Text("Please use the Document app structure instead of the old ContentView.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    DetailContentView(
        documentManager: DocumentManager(document: LiteratiDocument()),
        selection: nil
    )
}
#endif 
