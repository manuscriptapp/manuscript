import SwiftUI

struct AddCharacterSheet: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var age = ""
    @State private var gender: ManuscriptCharacterGender = .notSpecified
    
    var body: some View {
        SheetForm(
            title: "Add Character",
            cancelAction: { dismiss() },
            confirmAction: {
                let ageInt = Int(age)
                viewModel.addCharacter(name: name, age: ageInt, gender: gender)
                dismiss()
            },
            isConfirmDisabled: name.isEmpty
        ) {
            Section("Basic Information") {
                TextField("Character Name", text: $name)
                TextField("Age", text: $age)
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif

                Picker("Gender", selection: $gender) {
                    ForEach(ManuscriptCharacterGender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
            }
        }
    }
} 
