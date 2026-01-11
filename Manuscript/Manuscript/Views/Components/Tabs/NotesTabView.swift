import SwiftUI

struct NotesTabView: View {
    @Binding var editedNotes: String
    
    var body: some View {
        ScrollView {
            TextEditor(text: $editedNotes)
                .frame(maxWidth: .infinity, minHeight: 300)
                .plainTextEditor()
                .padding()
        }
    }
}

#if DEBUG
#Preview {
    return NotesTabView(editedNotes: .constant("Sample notes content"))
}
#endif 