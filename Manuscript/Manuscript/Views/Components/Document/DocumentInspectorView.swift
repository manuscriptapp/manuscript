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
    @Binding var editedSynopsis: String
    @Binding var editedKeywords: [String]
    @Binding var linkedDocumentIds: [UUID]
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
    @StateObject private var notesContext = RichTextContext()
    @State private var selectedStyle: GenerationStyle = .formal
    @State private var isChatExpanded: Bool = true
    @State private var isCustomPromptExpanded: Bool = false
    @State private var chatMessages: [ChatMessage] = []
    @State private var scrollProxy: ScrollViewProxy? = nil

    /// Warm brown color for chat UI elements
    private var warmBrown: Color {
        Color(red: 0.55, green: 0.4, blue: 0.3)
    }

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

    private var linkedDocuments: [ManuscriptDocument.Document] {
        linkedDocumentIds.compactMap { documentViewModel.findDocument(withId: $0) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var availableLinkTargets: [ManuscriptDocument.Document] {
        documentViewModel.getAllDocuments(includeResearch: true, includeTrash: false)
            .filter { $0.id != document.id && !linkedDocumentIds.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
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

    private func addLinkedDocument(_ target: ManuscriptDocument.Document) {
        guard !linkedDocumentIds.contains(target.id) else { return }
        linkedDocumentIds.append(target.id)
    }

    private func removeLinkedDocument(_ target: ManuscriptDocument.Document) {
        linkedDocumentIds.removeAll { $0 == target.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon-based tab picker
            inspectorTabPicker
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            // Tab content
            Group {
                switch detailViewModel.inspectorSelectedTab {
                case 0:
                    chatTab
                case 1:
                    commentsTab
                case 2:
                    SnapshotsTabView(document: document, documentViewModel: documentViewModel)
                case 3:
                    detailsTab
                default:
                    chatTab
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 280, maxWidth: 400)
        #else
        .frame(minWidth: 300, maxWidth: .infinity)
        #endif
        .background(.background)
        .onAppear {
            // Initialize notes context with current notes
            notesContext.setAttributedString(to: detailViewModel.attributedNotes)
        }
        .onChange(of: notesContext.attributedString) { _, newValue in
            detailViewModel.attributedNotes = newValue
        }
    }

    /// Icon-based tab picker for the inspector
    private var inspectorTabPicker: some View {
        HStack(spacing: 2) {
            inspectorTabButton(icon: "sparkles", tab: 0)
            inspectorTabButton(icon: "text.bubble", tab: 1)
            inspectorTabButton(icon: "clock", tab: 2)
            inspectorTabButton(icon: "doc.text", tab: 3)
        }
        .padding(3)
        .background(Color.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func inspectorTabButton(icon: String, tab: Int) -> some View {
        let isSelected = detailViewModel.inspectorSelectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                detailViewModel.inspectorSelectedTab = tab
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .contentShape(Rectangle())
                .background(isSelected ? Color.accentColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    private var chatTab: some View {
        VStack(spacing: 0) {
            // AI Assistant options
            DisclosureGroup(
                isExpanded: $isChatExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 12) {
                        // Content Type Selection
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([
                                    (type: "Dialogue", icon: "bubble.left.and.bubble.right"),
                                    (type: "Environment", icon: "mountain.2"),
                                    (type: "Character", icon: "person.fill.questionmark"),
                                    (type: "Action", icon: "bolt.fill"),
                                    (type: "Plot Twist", icon: "arrow.up.forward.circle")
                                ], id: \.type) { option in
                                    Button {
                                        generateScriptContent(option.type == "Character" ? "Character Development" : (option.type == "Action" ? "Action Sequence" : option.type))
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: option.icon)
                                                .font(.system(size: 11))
                                            Text(option.type)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.accentColor)
                                }
                            }
                        }
                    }
                },
                label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(warmBrown)
                        Text("Quick Prompts")
                            .font(.subheadline.weight(.medium))
                    }
                }
            )
            .padding(.horizontal)
            .padding(.vertical, 12)
            
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
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .center) {
                                    Image(systemName: "text.quote")
                                        .font(.system(size: 12))
                                        .foregroundStyle(warmBrown)
                                    Text("Selected")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(selectedText.count)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(warmBrown.opacity(0.8))
                                }

                                Text(selectedTextPreview)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary.opacity(0.9))
                                    .lineSpacing(3)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(warmBrown.opacity(0.08))
                                    .cornerRadius(6)
                            }
                            .padding(12)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                            .id("selectedTextPreview")
                        } else {
                            // Simple message when no text is selected
                            HStack(spacing: 8) {
                                Image(systemName: "text.cursor")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                Text("Select text in the editor to include it in prompts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 12)
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
                                .tint(.accentColor)
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
    
    @State private var isAddingComment: Bool = false
    @State private var newCommentText: String = ""
    @State private var editingComment: ManuscriptDocument.DocumentComment? = nil
    @State private var editCommentText: String = ""

    private var commentsTab: some View {
        VStack(spacing: 0) {
            // Add comment button
            HStack {
                if hasTextSelection && !selectedText.isEmpty {
                    Text("Selected: \"\(selectedText.prefix(30))\(selectedText.count > 30 ? "..." : "")\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    isAddingComment = true
                    newCommentText = ""
                } label: {
                    Label("Add Comment", systemImage: "plus.bubble")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.accent)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if detailViewModel.comments.isEmpty && !isAddingComment {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No Comments")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Select text and tap 'Add Comment' to create a comment linked to that text.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Comments list with scroll-to support
                ScrollViewReader { scrollProxy in
                    List {
                        // New comment input
                        if isAddingComment {
                            VStack(alignment: .leading, spacing: 8) {
                                if hasTextSelection && !selectedText.isEmpty {
                                    HStack {
                                        Image(systemName: "link")
                                            .font(.caption)
                                            .foregroundStyle(.accent)
                                        Text("Linked to: \"\(selectedText.prefix(50))\(selectedText.count > 50 ? "..." : "")\"")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    .padding(8)
                                    .background(Color.accent.opacity(0.1))
                                    .cornerRadius(6)
                                }

                                TextField("Enter comment...", text: $newCommentText, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .lineLimit(3...6)

                                HStack {
                                    Button("Cancel") {
                                        isAddingComment = false
                                        newCommentText = ""
                                    }
                                    .buttonStyle(.bordered)

                                    Spacer()

                                    Button("Save") {
                                        if !newCommentText.isEmpty {
                                            detailViewModel.addComment(text: newCommentText)
                                            newCommentText = ""
                                            isAddingComment = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(newCommentText.isEmpty)
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        // Existing comments
                        ForEach(detailViewModel.comments) { comment in
                            commentRow(comment)
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: detailViewModel.tappedComment) { _, tappedComment in
                        // Scroll to the tapped comment with animation
                        if let comment = tappedComment {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scrollProxy.scrollTo(comment.id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $editingComment) { comment in
            editCommentSheet(comment)
        }
    }

    @ViewBuilder
    private func commentRow(_ comment: ManuscriptDocument.DocumentComment) -> some View {
        let isActive = detailViewModel.tappedComment?.id == comment.id

        VStack(alignment: .leading, spacing: 8) {
            // Linked text preview
            if let commentedText = detailViewModel.getCommentedText(for: comment) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 3)

                    Text(commentedText.prefix(80) + (commentedText.count > 80 ? "..." : ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(2)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(uiColor: .secondarySystemBackground))
                #endif
                .cornerRadius(8)
            }

            // Menu button row
            HStack {
                Spacer()
                Menu {
                    Button {
                        editingComment = comment
                        editCommentText = comment.text
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        detailViewModel.deleteComment(comment)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
            }

            // Comment text bubble - full width
            VStack(alignment: .leading, spacing: 6) {
                Text(comment.text)
                    .font(.body)
                    .foregroundStyle(.primary)

                // Timestamp
                Text(comment.creationDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            #if os(macOS)
            .background(isActive ? Color.accentColor.opacity(0.15) : Color(nsColor: .windowBackgroundColor))
            #else
            .background(isActive ? Color.accentColor.opacity(0.15) : Color(uiColor: .tertiarySystemBackground))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isActive ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isActive ? 2 : 1)
            )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            // Set tapped comment to scroll editor to this comment's text
            detailViewModel.tappedComment = comment
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
        #if os(macOS)
        .listRowBackground(Color.clear)
        #endif
        .id(comment.id)
    }

    private func editCommentSheet(_ comment: ManuscriptDocument.DocumentComment) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let commentedText = detailViewModel.getCommentedText(for: comment) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Linked Text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\"\(commentedText)\"")
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.accent.opacity(0.1))
                            .cornerRadius(6)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Comment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $editCommentText)
                        .frame(minHeight: 100)
                        #if os(iOS)
                        .background(Color(uiColor: .secondarySystemBackground))
                        #else
                        .background(Color(nsColor: .textBackgroundColor))
                        #endif
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Comment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingComment = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let comment = editingComment {
                            detailViewModel.updateComment(comment, text: editCommentText)
                        }
                        editingComment = nil
                    }
                    .disabled(editCommentText.isEmpty)
                }
            }
        }
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

                // Synopsis Section
                VStack(alignment: .leading, spacing: 8) {

                    Text("Synopsis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #if os(iOS)
                    TextEditor(text: $editedSynopsis)
                        .plainTextEditor()
                        .frame(minHeight: 100)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    dismissKeyboard()
                                }
                            }
                        }
                    #else
                    TextEditor(text: $editedSynopsis)
                        .plainTextEditor()
                        .frame(minHeight: 100)
                    #endif
                }
                .padding(.horizontal)

                // Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        // Compact formatting toolbar
                        HStack(spacing: 4) {
                            RichTextStyle.ToggleGroup(context: notesContext)
                        }
                        .font(.caption)
                    }

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
                    .frame(minHeight: 120)
                    #if os(macOS)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                    #else
                    .background(Color(uiColor: .secondarySystemBackground))
                    #endif
                    .cornerRadius(8)
                }
                .padding(.horizontal)

                KeywordEditorView(
                    title: "Keywords",
                    keywords: $editedKeywords,
                    suggestions: documentViewModel.allKeywords
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Links")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if linkedDocuments.isEmpty {
                        Text("No linked documents")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(linkedDocuments) { linked in
                            HStack(spacing: 8) {
                                Button {
                                    documentViewModel.detailSelection = .document(linked)
                                } label: {
                                    Label(linked.title.isEmpty ? "Untitled" : linked.title, systemImage: "link")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button {
                                    removeLinkedDocument(linked)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove link to \(linked.title)")
                            }
                        }
                    }

                    if !availableLinkTargets.isEmpty {
                        Menu {
                            ForEach(availableLinkTargets) { target in
                                Button(target.title.isEmpty ? "Untitled" : target.title) {
                                    addLinkedDocument(target)
                                }
                            }
                        } label: {
                            Label("Add Link", systemImage: "link.badge.plus")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
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
        editedSynopsis: .constant("Sample Outline"),
        editedKeywords: .constant([]),
        linkedDocumentIds: .constant([]),
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
