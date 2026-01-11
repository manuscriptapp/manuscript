import SwiftUI

struct GenerateButtonView: View {
    let title: String
    let systemImage: String
    let isGenerating: Bool
    let isDisabled: Bool?
    @Binding var isGenerateSheetPresented: Bool
    @Binding var generatedText: String
    @Binding var generationError: Error?
    @Binding var generationType: DocumentDetailViewModel.GenerationType
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 8) {
                Button(action: { isGenerateSheetPresented = true }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text(title)
                    }
                    .frame(maxWidth: .infinity)
                }
                .tint(Color.accentSecondary)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isDisabled ?? false || isGenerating)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .background(.bar)
    }
}

#if DEBUG
#Preview {
    GenerateButtonView(
        title: "Generate Chapter",
        systemImage: "doc.text.fill",
        isGenerating: false,
        isDisabled: false,
        isGenerateSheetPresented: .constant(false),
        generatedText: .constant(""),
        generationError: .constant(nil),
        generationType: .constant(.content)
    )
}
#endif 
