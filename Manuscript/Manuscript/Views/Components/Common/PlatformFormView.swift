import SwiftUI

struct PlatformFormView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        #if os(iOS)
        Form {
            content
        }
        .formStyle(.grouped)
        #else
        ScrollView {
            Form {
                content
            }
            .formStyle(.grouped)
        }
        #endif
    }
}

#Preview {
    PlatformFormView {
        Section {
            Text("Test Content")
        }
    }
} 