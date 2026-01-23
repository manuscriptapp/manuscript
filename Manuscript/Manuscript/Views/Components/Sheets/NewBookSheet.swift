import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct NewBookSheet: View {
    let preSelectedTemplate: BookTemplate?
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultAuthorName") private var defaultAuthorName = ""

    @State private var title = ""
    @State private var author: String
    @State private var metaInfo = ""
    @State private var selectedTemplate: BookTemplate?
    @State private var showingTemplateInfo = false
    @State private var showingSavePanel = false
    @State private var document: ManuscriptDocument?

    var onComplete: (ManuscriptDocument) -> Void

    init(preSelectedTemplate: BookTemplate? = nil, onComplete: @escaping (ManuscriptDocument) -> Void = { _ in }) {
        self.preSelectedTemplate = preSelectedTemplate
        self.onComplete = onComplete
        _selectedTemplate = State(initialValue: preSelectedTemplate)
        _author = State(initialValue: UserDefaults.standard.string(forKey: "defaultAuthorName") ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    projectDetailsSection
                    
                    if preSelectedTemplate == nil {
                        templateSelectionSection
                        
                        if let template = selectedTemplate {
                            selectedTemplateInfoSection(template)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        prepareDocument()
                        #if os(macOS)
                        showingSavePanel = true
                        #else
                        // On iOS, we'll just create the document and call onComplete
                        if let doc = document {
                            onComplete(doc)
                            dismiss()
                        }
                        #endif
                    }
                    .disabled(title.isEmpty || author.isEmpty)
                }
            }
            .sheet(isPresented: $showingTemplateInfo) {
                if let template = selectedTemplate {
                    TemplateDetailSheet(template: template, onCreateBook: {
                        // Just close the sheet, don't create yet
                    })
                }
            }
            #if os(macOS)
            .fileExporter(
                isPresented: $showingSavePanel,
                document: document != nil ? ManuscriptDocumentWrapper(document: document!) : nil,
                contentType: .manuscriptDocument,
                defaultFilename: title.isEmpty ? "Untitled" : title
            ) { result in
                switch result {
                case .success(let url):
                    // Document was saved successfully - open it
                    NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { document, wasAlreadyOpen, error in
                        if let error = error {
                            print("Error opening saved document: \(error.localizedDescription)")
                        }
                    }
                    if let doc = document {
                        onComplete(doc)
                    }
                    dismiss()
                case .failure(let error):
                    print("Error saving document: \(error.localizedDescription)")
                }
            }
            #endif
        }
    }
    
    // MARK: - View Components
    
    private var projectDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Project Details")
                .font(.title2)
                .bold()
            
            VStack(spacing: 12) {
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Author", text: $author)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Description", text: $metaInfo, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
        }
    }
    
    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a Template")
                .font(.title2)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // No template option
                    blankTemplateButton
                    
                    // Template options
                    ForEach(BookTemplate.templates, id: \.id) { template in
                        templateButton(for: template)
                    }
                }
            }
        }
    }
    
    private var blankTemplateButton: some View {
        Button {
            selectedTemplate = nil
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 30))
                    .foregroundColor(.accentColor)
                
                Text("Blank Project")
                    .font(.headline)
            }
            .frame(width: 150, height: 100)
            .background(selectedTemplate == nil ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func templateButton(for template: BookTemplate) -> some View {
        Button {
            selectedTemplate = template
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.accentColor)
                
                Text(template.name)
                    .font(.headline)
                    .lineLimit(1)
            }
            .frame(width: 150, height: 100)
            .background(selectedTemplate?.id == template.id ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func selectedTemplateInfoSection(_ template: BookTemplate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Template: \(template.name)")
                .font(.headline)
            
            Text(template.description)
                .foregroundStyle(.secondary)
            
            Button("View Template Details") {
                showingTemplateInfo = true
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    
    private func prepareDocument() {
        // Create a new document (using var since ManuscriptDocument is now a struct)
        var newDocument = ManuscriptDocument()

        // Update the document properties
        newDocument.title = title
        newDocument.author = author

        // Build description with template info if applicable
        if let template = selectedTemplate {
            let templateInfo = "Created with \(template.name) template."
            if metaInfo.isEmpty {
                newDocument.description = templateInfo
            } else {
                newDocument.description = metaInfo + "\n\n" + templateInfo
            }
            applyTemplate(template, to: &newDocument)
        } else {
            newDocument.description = metaInfo
        }

        // Save default author name
        if !author.isEmpty {
            UserDefaults.standard.set(author, forKey: "defaultAuthorName")
        }

        // Store the document for saving
        self.document = newDocument
    }

    private func applyTemplate(_ template: BookTemplate, to document: inout ManuscriptDocument) {
        // Apply the template structure to the root folder
        for subfolder in template.structure.subfolders {
            createFolderFromTemplate(subfolder, in: &document.rootFolder)
        }
    }

    private func createFolderFromTemplate(_ folderTemplate: FolderTemplate, in parentFolder: inout ManuscriptFolder) {
        // Create a new folder
        var newFolder = ManuscriptFolder(title: folderTemplate.title)
        var documents: [ManuscriptDocument.Document] = []

        // Add documents to the folder
        for docTemplate in folderTemplate.documents {
            let doc = ManuscriptDocument.Document(
                title: docTemplate.title,
                synopsis: docTemplate.synopsis,
                notes: docTemplate.notes,
                content: docTemplate.content,
                order: docTemplate.order
            )
            documents.append(doc)
        }

        // Set the documents
        newFolder.documents = documents

        // Create subfolders
        var subfolders: [ManuscriptFolder] = []

        // Add subfolders recursively
        for subfolder in folderTemplate.subfolders {
            var childFolder = ManuscriptFolder(title: subfolder.title)
            populateFolder(&childFolder, from: subfolder)
            subfolders.append(childFolder)
        }

        // Set the subfolders
        newFolder.subfolders = subfolders

        // Add the new folder to the parent
        parentFolder.subfolders.append(newFolder)
    }
    
    // Helper method to update a folder in the document structure
    private func updateFolder(in parentFolder: inout ManuscriptFolder, with updatedFolder: ManuscriptFolder) {
        for i in 0..<parentFolder.subfolders.count {
            if parentFolder.subfolders[i].id == updatedFolder.id {
                parentFolder.subfolders[i] = updatedFolder
                return
            }
            
            // Recursively search in subfolders
            var subfolder = parentFolder.subfolders[i]
            updateFolder(in: &subfolder, with: updatedFolder)
            parentFolder.subfolders[i] = subfolder
        }
    }
    
    private func populateFolder(_ folder: inout ManuscriptFolder, from template: FolderTemplate) {
        // Add documents
        var documents: [ManuscriptDocument.Document] = []
        for docTemplate in template.documents {
            let document = ManuscriptDocument.Document(
                title: docTemplate.title,
                synopsis: docTemplate.synopsis,
                notes: docTemplate.notes,
                content: docTemplate.content,
                order: docTemplate.order
            )
            documents.append(document)
        }
        folder.documents = documents
        
        // Add subfolders recursively
        var subfolders: [ManuscriptFolder] = []
        for subfolder in template.subfolders {
            var childFolder = ManuscriptFolder(title: subfolder.title)
            populateFolder(&childFolder, from: subfolder)
            subfolders.append(childFolder)
        }
        folder.subfolders = subfolders
    }
}

// Document wrapper for file exporter
#if os(macOS)
struct ManuscriptDocumentWrapper: FileDocument {
    var document: ManuscriptDocument
    
    static var readableContentTypes: [UTType] { [.manuscriptDocument] }
    
    init(document: ManuscriptDocument) {
        self.document = document
    }
    
    init(configuration: ReadConfiguration) throws {
        // This initializer is required but won't be used in this context
        document = ManuscriptDocument()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Use the document's built-in write method since it already conforms to FileDocument
        return try document.fileWrapper(configuration: configuration)
    }
}
#endif

// MARK: - Preview
#Preview {
    NewBookSheet()
}