import SwiftUI
import SwiftData

struct CharacterDetailView: View {
    let character: LiteratiCharacter
    @ObservedObject var documentManager: DocumentManager
    @State private var isEditing = false
    @State private var editedName: String
    @State private var editedAge: Int?
    @State private var editedGender: LiteratiCharacterGender
    
    init(character: LiteratiCharacter, documentManager: DocumentManager) {
        self.character = character
        self.documentManager = documentManager
        _editedName = State(initialValue: character.name)
        _editedAge = State(initialValue: character.age)
        _editedGender = State(initialValue: character.gender)
    }
    
    var body: some View {
        FormContainerView {
            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name:")
                            .font(.subheadline)
                        HStack {
                            TextField("Name", text: $editedName)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                // TODO: Implement AI name generation
                            }) {
                                Image(systemName: "wand.and.stars")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age:")
                            .font(.subheadline)
                        TextField("Age", value: $editedAge, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender:")
                            .font(.subheadline)
                        Picker("Gender", selection: $editedGender) {
                            ForEach(LiteratiCharacterGender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } else {
                    Text("Character: \(character.name)")
                        .font(.title)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let age = character.age {
                            Text("Age: \(age)")
                                .font(.body)
                        }
                        Text("Gender: \(character.gender.rawValue)")
                            .font(.body)
                    }
                    
                    if !character.appearsInDocumentIds.isEmpty {
                        Divider()
                        
                        Text("Appears in:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ForEach(character.appearsInDocumentIds, id: \.self) { docId in
                            if let doc = documentManager.findDocument(withId: docId) {
                                HStack {
                                    Image(systemName: doc.iconName)
                                        .foregroundStyle(Color(doc.colorName.lowercased()))
                                    Text(doc.title)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(character.name)
                    .font(.headline)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(isEditing)
    }
    
    private func saveChanges() {
        documentManager.updateCharacter(
            character,
            name: editedName,
            age: editedAge,
            gender: editedGender
        )
        isEditing = false
    }
    
    private func cancelEditing() {
        editedName = character.name
        editedAge = character.age
        editedGender = character.gender
        isEditing = false
    }
}

#if DEBUG
#Preview {
    let documentManager = DocumentManager(document: LiteratiDocument(title: "Test Document", author: "Test"))
    let character = LiteratiCharacter(name: "Aria Windweaver", age: 18, gender: .female)
    
    NavigationStack {
        CharacterDetailView(
            character: character,
            documentManager: documentManager
        )
    }
}
#endif 
