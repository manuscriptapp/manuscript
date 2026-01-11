import SwiftUI
import UniformTypeIdentifiers

struct FolderTemplateView: View {
    let folder: FolderTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(folder.title)
                .font(.title3)
                .bold()
            
            Text(folder.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Chapters in the folder
            if !folder.documents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.accent)
                        Text("Chapters")
                            .font(.headline)
                    }
                    .padding(.top, 8)
                    
                    ForEach(folder.documents.sorted(by: { $0.order < $1.order }), id: \.title) { document in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "text.book.closed")
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(document.title)
                                    .font(.headline)
                                Text(document.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.leading)
                    }
                }
            }
            
            // Acts (formerly Subfolders)
            if !folder.subfolders.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "theatermasks.fill")
                            .foregroundStyle(.accent)
                        Text("Acts")
                            .font(.headline)
                    }
                    .padding(.top, 8)
                    
                    ForEach(folder.subfolders.sorted(by: { $0.order < $1.order }), id: \.title) { subfolder in
                        FolderTemplateView(folder: subfolder)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.1))
        )
    }
}

struct TemplateDetailSheet: View {
    let template: BookTemplate
    let onCreateBook: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewBookSheet = false
    
    private var symbol: String {
        switch template.name {
        case "Hero's Journey":
            return "figure.walk.motion"
        case "Romance Outline":
            return "heart.fill"
        // Add more cases for future templates
        default:
            return "doc.badge.plus"
        }
    }
    
    private var gradient: LinearGradient {
        switch template.name {
        case "Hero's Journey":
            return LinearGradient(
                colors: [.brown.opacity(0.8), Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Romance Outline":
            return LinearGradient(
                colors: [.pink.opacity(0.8), .red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: symbol)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            
            Text(template.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }
    
    private var structureView: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            FolderTemplateView(folder: template.structure)
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    structureView
                }
            }
            .navigationTitle(template.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create Book") {
                        showingNewBookSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingNewBookSheet) {
                NewBookSheet(
                    manuscriptViewModel: ManuscriptViewModel(document: ManuscriptDocument()),
                    preSelectedTemplate: template
                ) { _ in
                    // Call the completion handler
                    onCreateBook()
                    dismiss()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    TemplateDetailSheet(template: .heroJourney, onCreateBook: {})
        .frame(width: 600, height: 800)
}
#endif 
