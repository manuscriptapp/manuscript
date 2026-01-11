import SwiftUI
import SwiftData

struct CharacterSelectionView: View {
    let characters: [LiteratiCharacter]?
    @Binding var selectedCharacters: Set<UUID>
    @Binding var isExpanded: Bool
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                
                List {
                    if let characters = characters {
                        ForEach(characters) { character in
                            Toggle(
                                isOn: Binding(
                                    get: { selectedCharacters.contains(character.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedCharacters.insert(character.id)
                                        }
                                        else {
                                            selectedCharacters.remove(character.id)
                                        }
                                    }
                                )
                            ) {
                                VStack(alignment: .leading) {
                                    Text(character.name)
                                        .font(.body)
                                    if let age = character.age {
                                        Text("Age: \(age)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    else {
                        Text("No characters available")
                            .foregroundStyle(.secondary)
                    }
                }
                
#if os(macOS)
                .padding(4)
                .toggleStyle(.checkbox)
#endif
            },
            label: {
                HStack {
                    Image(systemName: "person.2")
                        .foregroundStyle(.accent)
                    Text("Characters")
                        .badge(selectedCharacters.count)
                }
            }
        )
    }
    
}

#if DEBUG
#Preview {
    CharacterSelectionView(
        characters: [
            LiteratiCharacter(name: "Aria", age: 17, gender: .female),
            LiteratiCharacter(name: "Master Chen", age: 55, gender: .male)
        ],
        selectedCharacters: .constant(Set<UUID>()),
        isExpanded: .constant(true)
    )
}
#endif
