import SwiftUI
import SwiftData
import RichTextKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Document Inspector View

struct DocumentInspectorView: View {
    let document: ManuscriptDocument.Document
    let documentViewModel: DocumentViewModel
    @ObservedObject var detailViewModel: DocumentDetailViewModel
    @Binding var editedTitle: String
    @Binding var editedOutline: String
    @Binding var isPromptExpanded: Bool
    @Binding var selectedCharacters: Set<UUID>
    @Binding var selectedLocations: Set<UUID>
    @Binding var isGenerating: Bool
    @Binding var generationType: DocumentDetailViewModel.GenerationType
    @Binding var isGenerateSheetPresented: Bool
    @Binding var generatedText: String
    @Binding var generationError: Error?
    @Binding var isInspectorPresented: Bool
    @Binding var inspectorDetent: PresentationDetent
    @Binding var selectedText: String
    @Binding var hasTextSelection: Bool
    @State private var chatText: String = ""
    @State private var selectedTab: Int = 0
    @StateObject private var notesContext = RichTextContext()
    @State private var selectedStyle: GenerationStyle = .formal
    @State private var isChatExpanded: Bool = true
    @State private var isCustomPromptExpanded: Bool = false
    @State private var chatMessages: [ChatMessage] = []
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    let generateAction: (DocumentDetailViewModel.GenerationType, String?) async -> Void
    let applyAction: () -> Void
    let applyToSelectionAction: (String) -> Void
    
    // Computed property to create a preview of the selected text
    private var selectedTextPreview: String {
        let maxLength = 100
        let text = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > maxLength {
            let index = text.index(text.startIndex, offsetBy: maxLength)
            return String(text[..<index]) + "..."
        }
        return text
    }
    
    // Function to dismiss keyboard
    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    #if os(iOS)
    // Create a toolbar with a dismiss button for the keyboard
    private var keyboardToolbar: some View {
        HStack {
            Spacer()
            Button(action: dismissKeyboard) {
                Text("Done")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
        }
        .frame(height: 44)
        .background(Color(UIColor.systemGray6))
    }
    #endif
    
    private func wrappedGenerateAction(style: GenerationStyle, prompt: String?) async {
        await generateAction(.outline, prompt)
    }
    
    private func handleGenerate() {
        if !chatText.isEmpty {
            // Prepare the prompt, including selected text if available
            var finalPrompt = chatText
            
            // Add selected text to the prompt if available
            if hasTextSelection && !selectedText.isEmpty {
                // Format the selected text nicely in the prompt
                finalPrompt = """
                Working with the following selected text:
                
                ---BEGIN SELECTED TEXT---
                \(selectedText)
                ---END SELECTED TEXT---
                
                \(chatText)
                """
            }
            
            // Add user message
            let userMessage = ChatMessage(content: chatText, isUser: true)
            chatMessages.append(userMessage)
            
            // Show inspector and set to large
            isInspectorPresented = true
            inspectorDetent = .large
            
            // Start generation
            Task {
                let userPrompt = finalPrompt
                chatText = "" // Clear input field
                
                // Show loading indicator
                let loadingMessage = ChatMessage(content: "Generating...", isUser: false)
                DispatchQueue.main.async {
                    chatMessages.append(loadingMessage)
                    // Scroll to bottom
                    scrollToBottom()
                }
                
                // Generate content using the chat generation type
                await generateAction(.notes, userPrompt)
                
                // Remove loading message and add response
                DispatchQueue.main.async {
                    if let index = chatMessages.firstIndex(where: { $0.id == loadingMessage.id }) {
                        chatMessages.remove(at: index)
                    }
                    
                    if let error = generationError {
                        chatMessages.append(ChatMessage(content: "Error: \(error.localizedDescription)", isUser: false))
                    } else if !generatedText.isEmpty {
                        let aiMessage = ChatMessage(content: generatedText, isUser: false, canApply: true)
                        chatMessages.append(aiMessage)
                    }
                    
                    // Scroll to bottom
                    scrollToBottom()
                }
            }
        }
    }
    
    private func generateWithStyle(_ style: GenerationStyle) {
        selectedStyle = style
        
        // Show inspector and set to large
        isInspectorPresented = true
        inspectorDetent = .large
        
        // Create prompt based on style
        var stylePrompt = "Generate content in a "
        switch style {
        case .formal:
            stylePrompt += "formal, professional style with structured language and proper terminology."
        case .casual:
            stylePrompt += "casual, conversational style that feels natural and approachable."
        case .fastPaced:
            stylePrompt += "fast-paced style with dynamic action and concise sentences to create momentum."
        case .detailed:
            stylePrompt += "detailed, descriptive style with rich imagery and thorough explanations."
        }
        
        // Add context about selected text if available
        if hasTextSelection && !selectedText.isEmpty {
            // Format the selected text nicely in the prompt
            stylePrompt = """
            Working with the following selected text:
            
            ---BEGIN SELECTED TEXT---
            \(selectedText)
            ---END SELECTED TEXT---
            
            \(stylePrompt)
            """
        }
        
        // Add context about characters and locations if available
        if !selectedCharacters.isEmpty || !selectedLocations.isEmpty {
            stylePrompt += "\n\nInclude: "
            
            if !selectedCharacters.isEmpty {
                let characterNames = documentViewModel.document.characters.filter { selectedCharacters.contains($0.id) }.map { $0.name }.joined(separator: ", ")
                stylePrompt += "Characters: \(characterNames). "
            }
            
            if !selectedLocations.isEmpty {
                let locationNames = documentViewModel.document.locations.filter { selectedLocations.contains($0.id) }.map { $0.name }.joined(separator: ", ")
                stylePrompt += "Locations: \(locationNames)."
            }
        }
        
        // Set the prompt and generate
        chatText = stylePrompt
        handleGenerate()
    }
    
    private func generateScriptContent(_ type: String) {
        // Show inspector and set to large
        isInspectorPresented = true
        inspectorDetent = .large
        
        // Create prompt based on content type
        var prompt = ""
        
        switch type {
        case "Dialogue":
            prompt = "Write realistic dialogue between characters that reveals personality and advances the plot."
            if !selectedCharacters.isEmpty {
                let characterNames = documentViewModel.document.characters.filter { selectedCharacters.contains($0.id) }.map { $0.name }.joined(separator: ", ")
                prompt += "\n\nInclude these characters in the conversation: \(characterNames)."
            }
            
        case "Environment":
            prompt = "Create a vivid, sensory description of the environment that establishes mood and atmosphere."
            if !selectedLocations.isEmpty {
                let locationNames = documentViewModel.document.locations.filter { selectedLocations.contains($0.id) }.map { $0.name }.joined(separator: ", ")
                prompt += "\n\nDescribe this location in detail: \(locationNames)."
            }
            
        case "Character Development":
            prompt = "Develop character depth through internal thoughts, motivations, and emotional reactions."
            if !selectedCharacters.isEmpty {
                let characterNames = documentViewModel.document.characters.filter { selectedCharacters.contains($0.id) }.map { $0.name }.joined(separator: ", ")
                prompt += "\n\nFocus on developing these characters: \(characterNames)."
            }
            
        case "Action Sequence":
            prompt = "Write a dynamic action sequence with clear, moment-by-moment description that creates tension and excitement."
            
        case "Plot Twist":
            prompt = "Create a surprising but logical plot twist that recontextualizes previous events and raises the stakes."
            
        default:
            prompt = "Generate creative content for the story."
        }
        
        // Add context about selected text if available
        if hasTextSelection && !selectedText.isEmpty {
            // Format the selected text nicely in the prompt
            prompt = """
            Working with the following selected text:
            
            ---BEGIN SELECTED TEXT---
            \(selectedText)
            ---END SELECTED TEXT---
            
            \(prompt)
            """
        }
        
        // Set the prompt and generate
        chatText = prompt
        handleGenerate()
    }
    
    private func applyGeneratedContent(_ content: String) {
        // Set the generated text
        generatedText = content
        
        // Apply the content based on whether text is selected
        if hasTextSelection && !selectedText.isEmpty {
            // Apply to the selected text only
            applyToSelectionAction(content)
            
            // Add confirmation message
            let confirmMessage = ChatMessage(content: "Content applied to selected text.", isUser: false)
            chatMessages.append(confirmMessage)
        } else {
            // Apply to the entire document
            applyAction()
            
            // Add confirmation message
            let confirmMessage = ChatMessage(content: "Content applied to document.", isUser: false)
            chatMessages.append(confirmMessage)
        }
        
        // Ensure we scroll to the bottom after adding the confirmation message
        scrollToBottom()
    }
    
    private func copyToClipboard(_ content: String) {
        #if os(iOS)
        UIPasteboard.general.string = content
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        #endif
        
        // Add confirmation message
        let confirmMessage = ChatMessage(content: "Content copied to clipboard.", isUser: false)
        chatMessages.append(confirmMessage)
        
        // Scroll to bottom
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        // Use DispatchQueue.main.async to ensure UI updates happen after the view has been updated
        DispatchQueue.main.async {
            withAnimation {
                if hasTextSelection && !selectedText.isEmpty {
                    // Scroll to the selected text preview if it exists
                    scrollProxy?.scrollTo("selectedTextPreview", anchor: .bottom)
                } else {
                    // Otherwise scroll to the bottom anchor
                    scrollProxy?.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat Tab
            chatTab
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
                .tag(0)

            // Notes Tab
            notesTab
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(1)

            // Details Tab
            detailsTab
                .tabItem {
                    Label("Details", systemImage: "doc.text")
                }
                .tag(2)
        }
        .padding(.top)
        .frame(minWidth: 300, maxWidth: .infinity)
        .background(.background)
        .onAppear {
            // Initialize notes context with current notes
            notesContext.setAttributedString(to: detailViewModel.attributedNotes)
        }
        .onChange(of: notesContext.attributedString) { _, newValue in
            detailViewModel.attributedNotes = newValue
        }
    }
    
    private var chatTab: some View {
        VStack(spacing: 0) {
            // AI Assistant options
            DisclosureGroup(
                isExpanded: $isChatExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 16) {
                        // Content Type Selection
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([
                                    (type: "Dialogue", icon: "bubble.left.and.bubble.right"),
                                    (type: "Environment", icon: "mountain.2"),
                                    (type: "Character Development", icon: "person.fill.questionmark"),
                                    (type: "Action Sequence", icon: "bolt.fill"),
                                    (type: "Plot Twist", icon: "arrow.up.forward.circle")
                                ], id: \.type) { option in
                                    Button {
                                        generateScriptContent(option.type)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: option.icon)
                                                .font(.system(size: 12))
                                            Text(option.type)
                                                .font(.footnote)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.accentSecondary)
                                }
                            }
                        }
                    }
                },
                label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.accent)
                        Text("Quick Prompts")
                            .font(.headline)
                    }
                }
            )
            .padding()
            
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(chatMessages) { message in
                            VStack(alignment: .leading, spacing: 8) {
                                ChatBubbleView(message: message)
                                
                                // Action buttons for AI-generated content
                                if message.canApply && !message.isUser {
                                    HStack(spacing: 12) {
                                        Button {
                                            applyGeneratedContent(message.content)
                                        } label: {
                                            Label("Use This", systemImage: "checkmark.circle")
                                                .font(.footnote)
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.accent)
                                        
                                        Button {
                                            copyToClipboard(message.content)
                                        } label: {
                                            Label("Copy", systemImage: "doc.on.doc")
                                                .font(.footnote)
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.blue)
                                        
                                        Button {
                                            if let index = chatMessages.firstIndex(where: { $0.id == message.id }) {
                                                chatMessages.remove(at: index)
                                            }
                                        } label: {
                                            Label("Discard", systemImage: "xmark.circle")
                                                .font(.footnote)
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.secondary)
                                    }
                                    .padding(.leading, 16)
                                    .id("buttons-\(message.id)")
                                }
                            }
                            .id(message.id)
                        }
                        
                        // Selected Text Preview (if any) - at the bottom of the chat
                        if hasTextSelection && !selectedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "text.cursor")
                                        .foregroundStyle(.accent)
                                    Text("Selected Text")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    
                                    // Add a badge showing character count
                                    Text("\(selectedText.count) chars")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentSecondary.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                
                                Text(selectedTextPreview)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.accentSecondary.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.accentSecondary, lineWidth: 1)
                                    )
                            }
                            .padding()
                            .background(Color.systemBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentSecondary, lineWidth: 1)
                                    .padding(.horizontal)
                            )
                            .id("selectedTextPreview")
                        } else {
                            // Simple message when no text is selected
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundStyle(.yellow)
                                Text("Tip: Select text in the editor to include it in your prompts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .id("noSelectionInfo")
                        }
                        
                        // Add a spacer view at the bottom to scroll to
                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                    }
                    .padding()
                }
                .background(Color.systemGroupedBackground)
                .onChange(of: chatMessages.count) { _, _ in
                    scrollToBottom()
                }
                .onChange(of: selectedText) { _, _ in
                    // Scroll to the selected text preview when it changes
                    scrollToBottom()
                }
                .onAppear {
                    scrollProxy = proxy
                    // Scroll to bottom when the view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        scrollToBottom()
                    }
                }
                #if os(iOS)
                .onTapGesture {
                    dismissKeyboard()
                }
                #endif
            }
            
            // Input area
            VStack(spacing: 12) {
                DisclosureGroup(
                    isExpanded: $isCustomPromptExpanded,
                    content: {
                        VStack(spacing: 8) {
                            #if os(iOS)
                            TextEditor(text: $chatText)
                                .borderedTextEditor()
                                .frame(height: 100)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            dismissKeyboard()
                                        }
                                    }
                                }
                            #else
                            TextEditor(text: $chatText)
                                .borderedTextEditor()
                                .frame(height: 100)
                            #endif
                            
                            HStack {
                                Spacer()
                                
                                Button {
                                    handleGenerate()
                                } label: {
                                    Label("Generate", systemImage: "arrow.up.circle.fill")
                                        .font(.headline)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.accentSecondary)
                                .disabled(chatText.isEmpty || isGenerating)
                            }
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundStyle(.secondary)
                            Text("Custom Instructions")
                                .foregroundStyle(.secondary)
                        }
                    }
                )
            }
            .padding()
            .background(.bar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var notesTab: some View {
        VStack(spacing: 0) {
            // Compact formatting toolbar
            HStack(spacing: 8) {
                RichTextStyle.ToggleGroup(context: notesContext)

                Divider()
                    .frame(height: 20)

                // Font size controls
                HStack(spacing: 4) {
                    Button {
                        if notesContext.fontSize > 8 {
                            notesContext.fontSize -= 1
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)

                    Text("\(Int(notesContext.fontSize))")
                        .font(.caption)
                        .monospacedDigit()
                        .frame(width: 24)

                    Button {
                        if notesContext.fontSize < 72 {
                            notesContext.fontSize += 1
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            #if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
            #else
            .background(Color(uiColor: .secondarySystemBackground))
            #endif

            Divider()

            // Rich text editor for notes
            RichTextEditor(
                text: $detailViewModel.attributedNotes,
                context: notesContext,
                viewConfiguration: { textView in
                    #if os(macOS)
                    if let nsTextView = textView as? NSTextView {
                        nsTextView.drawsBackground = false
                        nsTextView.enclosingScrollView?.drawsBackground = false
                        nsTextView.enclosingScrollView?.backgroundColor = .clear
                    }
                    #endif
                }
            )
            .focusedValue(\.richTextContext, notesContext)
            .richTextEditorStyle(RichTextEditorStyle(backgroundColor: .clear))
            .background(.clear)
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var detailsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #if os(iOS)
                    TextField("Enter title", text: $editedTitle)
                        .textFieldStyle(.plain)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    dismissKeyboard()
                                }
                            }
                        }
                    #else
                    TextField("Enter title", text: $editedTitle)
                        .textFieldStyle(.plain)
                    #endif
                    Divider()
                }
                .font(.body)
                .padding(.horizontal)
                
                // Outline Section
                VStack(alignment: .leading, spacing: 8) {
                    if !document.outlinePrompt.isEmpty {
                        DisclosureGroup(
                            isExpanded: $isPromptExpanded,
                            content: {
                                Text(document.outlinePrompt)
                                    .font(.subheadline)
                            },
                            label: {
                                HStack {
                                    Image(systemName: "list.clipboard")
                                        .foregroundStyle(.accent)
                                    Text("Chapter Guidelines")
                                }
                            }
                        )
                    }
                    
                    Text("Outline")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #if os(iOS)
                    TextEditor(text: $editedOutline)
                        .plainTextEditor()
                        .frame(minHeight: 150)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    dismissKeyboard()
                                }
                            }
                        }
                    #else
                    TextEditor(text: $editedOutline)
                        .plainTextEditor()
                        .frame(minHeight: 150)
                    #endif
                }
                .padding(.horizontal)
                
                // Characters and Locations
                VStack(alignment: .leading, spacing: 12) {
                    CharacterSelectionView(
                        characters: documentViewModel.document.characters.sorted(by: { $0.name < $1.name }),
                        selectedCharacters: $selectedCharacters,
                        isExpanded: .constant(true)
                    )
                    
                    LocationSelectionView(
                        locations: documentViewModel.document.locations.sorted(by: { $0.name < $1.name }),
                        selectedLocations: $selectedLocations,
                        isExpanded: .constant(true)
                    )
                }
                .padding()
            }
            #if os(iOS)
            .onTapGesture {
                dismissKeyboard()
            }
            #endif
        }
    }
}

// ChatBubbleView is defined in ChatBubbleView.swift

#if DEBUG
#Preview {
    let docItem = ManuscriptDocument.Document(
        title: "Sample Document",
        notes: "Sample notes",
        content: "Sample content"
    )
    let viewModel = DocumentViewModel()
    let detailVM = DocumentDetailViewModel(document: docItem, documentViewModel: viewModel)

    DocumentInspectorView(
        document: docItem,
        documentViewModel: viewModel,
        detailViewModel: detailVM,
        editedTitle: .constant("Sample Title"),
        editedOutline: .constant("Sample Outline"),
        isPromptExpanded: .constant(false),
        selectedCharacters: .constant(Set<UUID>()),
        selectedLocations: .constant(Set<UUID>()),
        isGenerating: .constant(false),
        generationType: .constant(.content),
        isGenerateSheetPresented: .constant(false),
        generatedText: .constant(""),
        generationError: .constant(nil),
        isInspectorPresented: .constant(true),
        inspectorDetent: .constant(.medium),
        selectedText: .constant(""),
        hasTextSelection: .constant(false),
        generateAction: { _, _ in print("generate") },
        applyAction: { print("apply") },
        applyToSelectionAction: { _ in }
    )
}
#endif 
