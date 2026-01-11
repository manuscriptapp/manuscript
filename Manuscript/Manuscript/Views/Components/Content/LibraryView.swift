import SwiftUI
import SwiftData

struct LibraryView: View {
    @ObservedObject var viewModel: ManuscriptViewModel
    @State private var isSettingsPresented = false
    @Binding var detailSelection: DetailSelection?
    
    init(viewModel: ManuscriptViewModel, detailSelection: Binding<DetailSelection?>) {
        self.viewModel = viewModel
        self._detailSelection = detailSelection
    }
    
    var body: some View {
        VStack {
            // Project Info
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.document.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("By \(viewModel.document.author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if !viewModel.document.metaDescription.isEmpty {
                    Text(viewModel.document.metaDescription)
                        .font(.body)
                        .padding(.top, 4)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Project Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("\(viewModel.document.documentCount) Documents")
                    }
                    
                    HStack {
                        Image(systemName: "person")
                        Text("\(viewModel.document.characters.count) Characters")
                    }
                    
                    HStack {
                        Image(systemName: "mappin")
                        Text("\(viewModel.document.locations.count) Locations")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .navigationTitle("Project")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isSettingsPresented.toggle() }) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
        }
    }
}

// Extension to get document count
extension ManuscriptDocument {
    var documentCount: Int {
        func countDocuments(in folder: ManuscriptFolder) -> Int {
            let documentsInFolder = folder.documents.count
            let documentsInSubfolders = folder.subfolders.reduce(0) { count, subfolder in
                count + countDocuments(in: subfolder)
            }
            return documentsInFolder + documentsInSubfolders
        }
        
        return countDocuments(in: rootFolder)
    }
}
