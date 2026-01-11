import SwiftUI

struct CharactersView: View {
    @ObservedObject var documentManager: DocumentManager
    
    var body: some View {
        List {
            ForEach(documentManager.document.characters) { character in
                NavigationLink(value: DetailSelection.character(character)) {
                    VStack(alignment: .leading) {
                        Text(character.name)
                            .font(.headline)
                        
                        if let age = character.age {
                            Text("Age: \(age)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Gender: \(character.gender.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .contextMenu {
                    Button {
                        documentManager.showRenameAlert(for: character)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        documentManager.deleteCharacter(character)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Characters")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    documentManager.addCharacter(name: "New Character")
                } label: {
                    Label("Add Character", systemImage: "plus")
                }
            }
        }
    }
} 