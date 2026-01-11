import SwiftUI

struct FolderItemView: View {
    let folder: LiteratiFolder
    @ObservedObject var literatiViewModel: LiteratiViewModel
    @Binding var detailSelection: DetailSelection?
    
    private struct RecursiveFolderView: View {
        let folder: LiteratiFolder
        @ObservedObject var literatiViewModel: LiteratiViewModel
        @Binding var detailSelection: DetailSelection?
        @State private var isAddFolderSheetPresented = false
        @State private var isAddDocumentSheetPresented = false
        @State private var isExpanded: Bool
        
        init(folder: LiteratiFolder, literatiViewModel: LiteratiViewModel, detailSelection: Binding<DetailSelection?>) {
            self.folder = folder
            self.literatiViewModel = literatiViewModel
            self._detailSelection = detailSelection
            // Only auto-expand if this is the root folder
            _isExpanded = State(initialValue: folder.id == literatiViewModel.document.rootFolder.id)
        }
        
        private func colorForDocument(_ document: LiteratiDocument.Document) -> Color {
            let colorMap: [String: Color] = [
                "Yellow": .yellow,
                "Mint": .mint,
                "Pink": .pink,
                "Orange": .orange,
                "Teal": .teal,
                "Purple": .purple,
                "Green": .green,
                "Blue": .blue,
                "Red": .red,
                "Brown": .brown
            ]
            return colorMap[document.colorName] ?? .brown
        }
        
        private func dominantColor(for folder: LiteratiFolder) -> Color {
            // If it's the root folder, use accent color
            if folder.id == literatiViewModel.document.rootFolder.id {
                return .accent
            }
            
            // Get all documents in this folder and subfolders
            var allDocuments = folder.documents
            for subfolder in folder.subfolders {
                allDocuments.append(contentsOf: subfolder.documents)
            }
            
            // If no documents, use secondary color
            if allDocuments.isEmpty {
                return .secondary
            }
            
            // Count occurrences of each color
            var colorCounts: [Color: Int] = [:]
            for document in allDocuments {
                let color = colorForDocument(document)
                colorCounts[color, default: 0] += 1
            }
            
            // Return the most common color, or secondary if no colors found
            return colorCounts.max(by: { $0.value < $1.value })?.key ?? .secondary
        }
        
        // Helper computed property to check if this folder is selected
        private func isFolderSelected(_ folder: LiteratiFolder) -> Bool {
            if case .folder(let selectedFolder) = detailSelection, selectedFolder.id == folder.id {
                return true
            }
            return false
        }
        
        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                // Documents in this folder
                ForEach(folder.documents) { document in
                    DocumentItemView(
                        document: document,
                        literatiViewModel: literatiViewModel,
                        detailSelection: $detailSelection
                    )
                }
                
                // Subfolders
                ForEach(folder.subfolders) { subfolder in
                    RecursiveFolderView(
                        folder: subfolder,
                        literatiViewModel: literatiViewModel,
                        detailSelection: $detailSelection
                    )
                }
            } label: {
                Label {
                    Text(folder.title)
                } icon: {
                    let color = dominantColor(for: folder)
                    Image(systemName: "folder")
                        .foregroundStyle(isFolderSelected(folder) ? 
                            (color == .accent ? color.darker(by: 0.4) : 
                             color == .brown ? color.darker(by: 0.4) : color) : color)
                }
                .badge(folder.totalDocumentCount)
                .tag(DetailSelection.folder(folder))
                #if os(macOS)
                .contextMenu {
                    Button(action: {
                        literatiViewModel.showRenameAlert(for: folder)
                    }) {
                        Label("Rename Folder", systemImage: "pencil")
                    }
                    
                    if folder.id != literatiViewModel.document.rootFolder.id {
                        Button(role: .destructive, action: {
                            literatiViewModel.deleteFolder(folder)
                        }) {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }
                #else
                .contextMenu {
                    Button(action: {
                        detailSelection = .folder(folder)
                    }) {
                        Label("View Details", systemImage: "info.circle")
                    }
                    
                    Button(action: {
                        isAddFolderSheetPresented = true
                    }) {
                        Label("Add Folder", systemImage: "folder.badge.plus")
                    }
                    
                    Button(action: {
                        isAddDocumentSheetPresented = true
                    }) {
                        Label("Add Document", systemImage: "doc.badge.plus")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        literatiViewModel.showRenameAlert(for: folder)
                    }) {
                        Label("Rename Folder", systemImage: "pencil")
                    }
                    
                    if folder.id != literatiViewModel.document.rootFolder.id {
                        Button(role: .destructive, action: {
                            literatiViewModel.deleteFolder(folder)
                        }) {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(action: {
                        literatiViewModel.showRenameAlert(for: folder)
                    }) {
                        Label("Rename Folder", systemImage: "pencil")
                    }
                    .tint(.blue)
                    
                    if folder.id != literatiViewModel.document.rootFolder.id {
                        Button(role: .destructive, action: {
                            literatiViewModel.deleteFolder(folder)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                #endif
                .sheet(isPresented: $isAddFolderSheetPresented) {
                    AddFolderSheet(
                        document: literatiViewModel.document,
                        initialFolder: folder,
                        literatiViewModel: literatiViewModel
                    )
                }
                .sheet(isPresented: $isAddDocumentSheetPresented) {
                    AddDocumentSheet(
                        document: literatiViewModel.document,
                        initialFolder: folder,
                        literatiViewModel: literatiViewModel
                    )
                }
            }
        }
    }
    
    var body: some View {
        RecursiveFolderView(
            folder: folder,
            literatiViewModel: literatiViewModel,
            detailSelection: $detailSelection
        )
    }
}

// Extension to make colors darker - needed for the UI
extension Color {
    func darker(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
}

