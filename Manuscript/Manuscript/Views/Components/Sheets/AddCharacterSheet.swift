import SwiftUI

struct AddCharacterSheet: View {
    @ObservedObject var literatiViewModel: LiteratiViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var age = ""
    @State private var gender: LiteratiCharacterGender = .notSpecified
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Character Name", text: $name)
                    TextField("Age", text: $age)
                    #if os(iOS)
                        .keyboardType(.numberPad)
                    #endif
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(LiteratiCharacterGender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }
            }
            .navigationTitle("Add Character")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let ageInt = Int(age)
                        literatiViewModel.addCharacter(name: name, age: ageInt, gender: gender)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .padding()
    }
} 
