import SwiftUI

struct CharactersView: View {
    @ObservedObject var viewModel: DocumentViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.document.characters) { character in
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
                        viewModel.showRenameAlert(for: character)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.deleteCharacter(character)
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
                    viewModel.addCharacter(name: "New Character")
                } label: {
                    Label("Add Character", systemImage: "plus")
                }
            }
        }
    }
} 