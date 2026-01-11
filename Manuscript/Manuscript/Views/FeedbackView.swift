import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackType = FeedbackType.bugReport
    @State private var title = ""
    @State private var description = ""
    @State private var email = ""
    @State private var showingConfirmation = false
    
    enum FeedbackType: String, CaseIterable {
        case bugReport = "Bug Report"
        case featureRequest = "Feature Request"
        case generalFeedback = "General Feedback"
    }
    
    var body: some View {
        PlatformFormView {
            Section {
                Picker("Type", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
                
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                
                HStack(alignment: .top) {
                    Text("Description")
                        .padding(.trailing)

                    TextEditor(text: $description)
                        .borderedTextEditor()
                }
                
                Group {
                    TextField("Your Email (optional)", text: $email)
                        .textFieldStyle(.roundedBorder)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
#endif
                }
            } header: {
                Text("Feedback Details")
            } footer: {
                Text("Your feedback helps us improve Manuscript. We appreciate your input!")
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Button(action: submitFeedback) {
                    Label("Submit Feedback", systemImage: "arrowshape.turn.up.right")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || description.isEmpty)
            }
            
        }
        .navigationTitle("Feedback")
        .alert("Thank You!", isPresented: $showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your feedback has been submitted. We'll review it as soon as possible.")
        }
    }
    
    private func submitFeedback() {
        // Here you would typically send the feedback to your backend
        // For now, we'll just show a confirmation
        showingConfirmation = true
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
} 
