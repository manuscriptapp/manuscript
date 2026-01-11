import SwiftUI

struct ProjectOverview: View {
    @ObservedObject var documentManager: DocumentManager
    
    var body: some View {
        VStack {
            Image(systemName: "doc.text")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
                .padding()
            
            Text(documentManager.document.title.isEmpty ? "Untitled Project" : documentManager.document.title)
                .font(.title)
            
            Text("Select an item from the sidebar to begin editing")
                .foregroundColor(.secondary)
                .padding()
            
            // Project stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Documents:")
                    Spacer()
                    Text("\(documentManager.document.rootFolder.totalDocumentCount)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Characters:")
                    Spacer()
                    Text("\(documentManager.document.characters.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Locations:")
                    Spacer()
                    Text("\(documentManager.document.locations.count)")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: 300)
            
            Spacer()
            
            // Help and Feedback links
            HStack(spacing: 20) {
                NavigationLink(destination: HowItWorksView()) {
                    Label("How It Works", systemImage: "questionmark.circle")
                }
                
                NavigationLink(destination: FeedbackView()) {
                    Label("Feedback", systemImage: "envelope")
                }
            }
            .padding()
            .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 