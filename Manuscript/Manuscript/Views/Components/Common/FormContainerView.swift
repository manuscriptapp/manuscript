import SwiftUI

struct FormContainerView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .frame(maxWidth: 600, alignment: .leading)
            .padding()
        }
    }
}

#if DEBUG
#Preview {
    FormContainerView {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Sample Field", text: .constant(""))
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: .constant("Sample text"))
                .frame(height: 100)
                .borderedTextEditor()
        }
    }
    .frame(width: 800, height: 400) // Simulating a large screen
}
#endif 