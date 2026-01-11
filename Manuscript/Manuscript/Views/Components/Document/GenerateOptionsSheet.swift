import SwiftUI

struct GenerateOptionsSheet: View {
    let title: String
    let isGenerating: Bool
    let generationType: DocumentDetailViewModel.GenerationType
    let selectedCharacters: [Character]
    let selectedLocations: [Location]
    @Binding var isPresented: Bool
    @Binding var generatedText: String
    @Binding var generationError: Error?
    let generateAction: (GenerationStyle, String?) async -> Void
    let applyAction: () -> Void
    @State private var selectedStyle: GenerationStyle = .formal
    @State private var prompt: String = ""
    @State private var hasAttemptedGeneration = false
    @State private var isCustomInstructionsExpanded = false
    
    private var characterNames: String {
        selectedCharacters.map { $0.name }.joined(separator: ", ")
    }
    
    private var locationNames: String {
        selectedLocations.map { $0.name }.joined(separator: ", ")
    }
    
    private var contextPrompt: String {
        var context = ""
        if !selectedCharacters.isEmpty {
            context += "\nFeatured Characters: \(characterNames)"
        }
        if !selectedLocations.isEmpty {
            context += "\nFeatured Locations: \(locationNames)"
        }
        return context
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isGenerating {
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Generating \(generationType == .outline ? "outline" : "chapter")...")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        if !hasAttemptedGeneration {
                            // Initial Generation UI
                            VStack(spacing: 16) {
                                // Prompt Input
                                DisclosureGroup(
                                    isExpanded: $isCustomInstructionsExpanded,
                                    content: {
                                        TextEditor(text: $prompt)
                                            .frame(height: 100)
                                            .padding(8)
                                            .background(Color.secondary.opacity(0.1))
                                            .cornerRadius(8)
                                    },
                                    label: {
                                        HStack {
                                            Image(systemName: "text.alignleft")
                                                .foregroundStyle(.accent)
                                            Text("Custom Instructions")
                                                .font(.headline)
                                        }
                                    }
                                )
                                .padding(.horizontal)
                                
                                // Compact Style Selection
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Style")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach([
                                                (style: GenerationStyle.formal, title: "Formal", icon: "person.text.rectangle"),
                                                (style: GenerationStyle.casual, title: "Casual", icon: "person"),
                                                (style: GenerationStyle.fastPaced, title: "Fast-Paced", icon: "speedometer"),
                                                (style: GenerationStyle.detailed, title: "Detailed", icon: "text.magnifyingglass")
                                            ], id: \.title) { option in
                                                Button {
                                                    selectedStyle = option.style
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: option.icon)
                                                            .font(.system(size: 12))
                                                        Text(option.title)
                                                            .font(.footnote)
                                                    }
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                }
                                                .buttonStyle(.bordered)
                                                .tint(selectedStyle == option.style ? .accentColor : .secondary)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                
                                // Generate Button
                                Button {
                                    Task {
                                        hasAttemptedGeneration = true
                                        let fullPrompt = prompt.isEmpty ? contextPrompt : prompt + contextPrompt
                                        await generateAction(selectedStyle, fullPrompt.isEmpty ? nil : fullPrompt)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                        Text(generatedText.isEmpty ? "Write" : "Rewrite")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .tint(Color.accentSecondary)
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            }
                        } else {
                            // Results View
                            VStack(alignment: .leading, spacing: 16) {
                                if let error = generationError {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label(
                                            "Generation Failed",
                                            systemImage: "exclamationmark.triangle"
                                        )
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                        
                                        Text(error.localizedDescription)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                } else if generatedText.isEmpty {
                                    ContentUnavailableView(
                                        "No Results Yet",
                                        systemImage: "doc.text.magnifyingglass",
                                        description: Text("Try generating some content")
                                    )
                                    .padding(.top, 40)
                                } else {
                                    Text(generatedText)
                                        .font(.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                
                                // Regenerate Options
                                VStack(spacing: 12) {
                                    Button {
                                        hasAttemptedGeneration = false
                                        generatedText = ""
                                        generationError = nil
                                    } label: {
                                        Label("Try Different Options", systemImage: "arrow.counterclockwise")
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button {
                                        Task {
                                            let fullPrompt = prompt.isEmpty ? contextPrompt : prompt + contextPrompt
                                            await generateAction(selectedStyle, fullPrompt.isEmpty ? nil : fullPrompt)
                                        }
                                    } label: {
                                        Label("Generate Again", systemImage: "arrow.triangle.2.circlepath")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(title)
            .toolbar {
                if !isGenerating {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    if !generatedText.isEmpty {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Use This") {
                                applyAction()
                            }
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(isGenerating)
    }
}

struct StyleOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    GenerateOptionsSheet(
        title: "Generate Chapter",
        isGenerating: false,
        generationType: .content,
        selectedCharacters: [],
        selectedLocations: [],
        isPresented: .constant(true),
        generatedText: .constant(""),
        generationError: .constant(nil),
        generateAction: { _, _ in },
        applyAction: {}
    )
}
#endif 