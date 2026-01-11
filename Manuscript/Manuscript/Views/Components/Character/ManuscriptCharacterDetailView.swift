import SwiftUI

struct ManuscriptCharacterDetailView: View {
    @ObservedObject var documentManager: DocumentManager
    let character: ManuscriptCharacter
    @State private var editedName: String
    @State private var editedAge: Int?
    @State private var editedGender: ManuscriptCharacterGender
    
    init(documentManager: DocumentManager, character: ManuscriptCharacter) {
        self.documentManager = documentManager
        self.character = character
        self._editedName = State(initialValue: character.name)
        self._editedAge = State(initialValue: character.age)
        self._editedGender = State(initialValue: character.gender)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $editedName)
                    .onChange(of: editedName) { updateCharacter() }
                
                Picker("Gender", selection: $editedGender) {
                    ForEach(ManuscriptCharacterGender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .onChange(of: editedGender) { updateCharacter() }
                
                HStack {
                    Text("Age")
                    Spacer()
                    TextField("Age", value: $editedAge, format: .number)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .onChange(of: editedAge) { updateCharacter() }
                }
            } header: {
                Text("Character Details")
            }
            
            Section {
                if character.appearsInDocumentIds.isEmpty {
                    Text("This character doesn't appear in any documents yet.")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(character.appearsInDocumentIds, id: \.self) { docId in
                        if let doc = documentManager.findDocument(withId: docId) {
                            HStack {
                                Image(systemName: doc.iconName)
                                    .foregroundStyle(Color(doc.colorName.lowercased()))
                                Text(doc.title)
                            }
                        }
                    }
                }
            } header: {
                Text("Appears in Documents")
            }
        }
        .navigationTitle(character.name)
    }
    
    private func updateCharacter() {
        // Update the character with edited values
        documentManager.updateCharacter(
            character,
            name: editedName,
            age: editedAge,
            gender: editedGender
        )
    }
} 