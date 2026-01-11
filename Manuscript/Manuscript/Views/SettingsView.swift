import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultAuthorName") private var defaultAuthorName: String = ""
    
    var body: some View {
        Form {
            Section("Author") {
                TextField("Default Author Name", text: $defaultAuthorName)
                    .textFieldStyle(.automatic)
                #if os(iOS)
                    .textInputAutocapitalization(.words)
                #endif
            }
            
            Section("App Info") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
} 
