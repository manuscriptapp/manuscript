import SwiftUI

struct ProjectInfoView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @State private var editedTitle: String = ""
    @State private var editedAuthor: String = ""
    @State private var editedDescription: String = ""
    @State private var selectedGenres: Set<String> = []
    @State private var selectedNarrativeStyle: String = ""
    @State private var selectedLiteraryStyle: String = ""
    @State private var selectedStorytellingStyle: String = ""
    @State private var editedSynopsis: String = ""
    @State private var activeTab: Int = 0
    @State private var showingTemplateSheet: Bool = false

    /// The template used to create this document, if any
    private var template: BookTemplate? {
        guard let templateId = viewModel.document.templateId else { return nil }
        return BookTemplate.find(byId: templateId)
    }
    
    private let commonGenres = [
        "Fantasy", "Science Fiction", "Mystery", "Romance",
        "Thriller", "Horror", "Literary Fiction", "Historical Fiction",
        "Young Adult", "Children's", "Biography", "Non-Fiction"
    ]
    
    private let narrativeStyles = [
        "First Person",
        "Third Person Limited",
        "Third Person Omniscient",
        "Second Person",
        "Multiple Viewpoints",
        "Stream of Consciousness"
    ]
    
    private let literaryStyles = [
        "Minimalist",
        "Lyrical",
        "Experimental",
        "Gothic",
        "Magical Realism",
        "Satirical",
        "Epistolary"
    ]
    
    private let storytellingStyles = [
        "Linear",
        "Non-linear",
        "Frame Story",
        "Parallel Narratives",
        "Flashbacks",
        "Unreliable Narrator",
        "Vignettes"
    ]
    
    private var canSelectMoreGenres: Bool {
        selectedGenres.count < 3
    }
    
    private var combinedStyle: String {
        [selectedNarrativeStyle, selectedLiteraryStyle, selectedStorytellingStyle]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
    
    private enum Tab: Int, CaseIterable {
        case basicInfo = 0
        case genre = 1
        case style = 2
        case synopsis = 3

        var title: String {
            switch self {
            case .basicInfo: "Basic Info"
            case .genre: "Genre"
            case .style: "Style"
            case .synopsis: "Synopsis"
            }
        }

        var icon: String {
            switch self {
            case .basicInfo: "info.circle"
            case .genre: "tag"
            case .style: "paintbrush"
            case .synopsis: "doc.text"
            }
        }
    }

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    #if os(macOS)
    private var macOSBody: some View {
        PlatformFormView {
            Section {
                Picker("", selection: $activeTab) {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        Text(tab.title).tag(tab.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            switch activeTab {
            case 0:
                basicInfoSection
            case 1:
                genreSection
            case 2:
                styleSection
            case 3:
                synopsisSection
            default:
                basicInfoSection
            }
        }
        .navigationTitle("Project Info")
        .onAppear {
            loadData()
        }
    }
    #endif

    #if os(iOS)
    private var iOSBody: some View {
        TabView(selection: $activeTab) {
            basicInfoTab
                .tabItem {
                    Label("Basic Info", systemImage: "info.circle")
                }
                .tag(0)

            genreTab
                .tabItem {
                    Label("Genre", systemImage: "tag")
                }
                .tag(1)

            styleTab
                .tabItem {
                    Label("Style", systemImage: "paintbrush")
                }
                .tag(2)

            synopsisTab
                .tabItem {
                    Label("Synopsis", systemImage: "doc.text")
                }
                .tag(3)
        }
        .navigationTitle("Project Info")
        .onAppear {
            loadData()
        }
    }
    #endif
    
    // MARK: - macOS Sections (without Form wrapper)

    #if os(macOS)
    @ViewBuilder
    private var basicInfoSection: some View {
        Section("Project Information") {
            TextField("Title", text: $editedTitle)
                .onChange(of: editedTitle) { _, newValue in
                    var doc = viewModel.document
                    doc.title = newValue
                    viewModel.document = doc
                }

            TextField("Author", text: $editedAuthor)
                .onChange(of: editedAuthor) { _, newValue in
                    var doc = viewModel.document
                    doc.author = newValue
                    viewModel.document = doc
                }

            TextField("Description", text: $editedDescription, axis: .vertical)
                .lineLimit(5...10)
                .onChange(of: editedDescription) { _, newValue in
                    var doc = viewModel.document
                    doc.description = newValue
                    viewModel.document = doc
                }
        }

        if let template = template {
            Section("Template") {
                Button {
                    showingTemplateSheet = true
                } label: {
                    HStack {
                        Label(template.name, systemImage: templateIcon(for: template))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingTemplateSheet) {
                TemplateDetailSheet(template: template) {
                    showingTemplateSheet = false
                }
            }
        }
    }

    @ViewBuilder
    private var genreSection: some View {
        Section("Selected Genres (max 3)") {
            if selectedGenres.isEmpty {
                Text("No genres selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                GenreFlowLayout(spacing: 8) {
                    ForEach(Array(selectedGenres).sorted(), id: \.self) { genre in
                        HStack(spacing: 4) {
                            Text(genre)
                            Button(action: {
                                selectedGenres.remove(genre)
                                updateGenre()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor)
                        )
                        .foregroundStyle(.white)
                    }
                }
            }
        }

        Section("Common genres") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(commonGenres, id: \.self) { genre in
                    Group {
                        if selectedGenres.contains(genre) {
                            Button(action: {
                                if selectedGenres.contains(genre) {
                                    selectedGenres.remove(genre)
                                } else if canSelectMoreGenres {
                                    selectedGenres.insert(genre)
                                }
                                updateGenre()
                            }) {
                                Text(genre)
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: {
                                if selectedGenres.contains(genre) {
                                    selectedGenres.remove(genre)
                                } else if canSelectMoreGenres {
                                    selectedGenres.insert(genre)
                                }
                                updateGenre()
                            }) {
                                Text(genre)
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .disabled(!selectedGenres.contains(genre) && !canSelectMoreGenres)
                    .opacity(!selectedGenres.contains(genre) && !canSelectMoreGenres ? 0.5 : 1)
                }
            }
        }
    }

    @ViewBuilder
    private var styleSection: some View {
        Section("Selected Writing Style") {
            if combinedStyle.isEmpty {
                Text("No styles selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(combinedStyle)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.1))
                    )
            }
        }

        Section("Narrative Point of View") {
            styleSelectionGrid(
                styles: narrativeStyles,
                selectedStyle: $selectedNarrativeStyle
            )
        }

        Section("Literary Style") {
            styleSelectionGrid(
                styles: literaryStyles,
                selectedStyle: $selectedLiteraryStyle
            )
        }

        Section("Storytelling Approach") {
            styleSelectionGrid(
                styles: storytellingStyles,
                selectedStyle: $selectedStorytellingStyle
            )
            .onChange(of: combinedStyle) { _, _ in
                updateStyle()
            }
        }
    }

    @ViewBuilder
    private var synopsisSection: some View {
        Section("Synopsis") {
            TextEditor(text: $editedSynopsis)
                .frame(minHeight: 200)
                .onChange(of: editedSynopsis) { _, newValue in
                    var doc = viewModel.document
                    doc.synopsis = newValue
                    viewModel.document = doc
                }
        }

        Section("Writing tips") {
            Text("A good synopsis should include:")
                .font(.subheadline)

            Group {
                Text("• Main plot points and story arc")
                Text("• Key character motivations")
                Text("• Major conflicts and their resolution")
                Text("• The story's theme and message")
                Text("• The ending (unlike a blurb)")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }
    #endif

    // MARK: - iOS Tabs (with Form wrapper)

    #if os(iOS)
    private var basicInfoTab: some View {
        Form {
            Section("Project Information") {
                TextField("Title", text: $editedTitle)
                    .onChange(of: editedTitle) { _, newValue in
                        var doc = viewModel.document
                        doc.title = newValue
                        viewModel.document = doc
                    }

                TextField("Author", text: $editedAuthor)
                    .onChange(of: editedAuthor) { _, newValue in
                        var doc = viewModel.document
                        doc.author = newValue
                        viewModel.document = doc
                    }

                TextField("Description", text: $editedDescription, axis: .vertical)
                    .lineLimit(5...10)
                    .onChange(of: editedDescription) { _, newValue in
                        var doc = viewModel.document
                        doc.description = newValue
                        viewModel.document = doc
                    }
            }

            if let template = template {
                Section("Template") {
                    Button {
                        showingTemplateSheet = true
                    } label: {
                        HStack {
                            Label(template.name, systemImage: templateIcon(for: template))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .sheet(isPresented: $showingTemplateSheet) {
                    TemplateDetailSheet(template: template) {
                        showingTemplateSheet = false
                    }
                }
            }
        }
    }

    private var genreTab: some View {
        Form {
            Section("Selected Genres (max 3)") {
                if selectedGenres.isEmpty {
                    Text("No genres selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    GenreFlowLayout(spacing: 8) {
                        ForEach(Array(selectedGenres).sorted(), id: \.self) { genre in
                            HStack(spacing: 4) {
                                Text(genre)
                                Button(action: {
                                    selectedGenres.remove(genre)
                                    updateGenre()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor)
                            )
                            .foregroundStyle(.white)
                        }
                    }
                }
            }

            Section("Common genres") {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(commonGenres, id: \.self) { genre in
                        Group {
                            if selectedGenres.contains(genre) {
                                Button(action: {
                                    if selectedGenres.contains(genre) {
                                        selectedGenres.remove(genre)
                                    } else if canSelectMoreGenres {
                                        selectedGenres.insert(genre)
                                    }
                                    updateGenre()
                                }) {
                                    Text(genre)
                                        .padding(10)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            } else {
                                Button(action: {
                                    if selectedGenres.contains(genre) {
                                        selectedGenres.remove(genre)
                                    } else if canSelectMoreGenres {
                                        selectedGenres.insert(genre)
                                    }
                                    updateGenre()
                                }) {
                                    Text(genre)
                                        .padding(10)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .disabled(!selectedGenres.contains(genre) && !canSelectMoreGenres)
                        .opacity(!selectedGenres.contains(genre) && !canSelectMoreGenres ? 0.5 : 1)
                    }
                }
            }
        }
    }
    
    private var styleTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Selected Writing Style
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Writing Style")
                        .font(.headline)
                    
                    if combinedStyle.isEmpty {
                        Text("No styles selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(combinedStyle)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal)
                
                // Narrative Point of View
                VStack(alignment: .leading, spacing: 12) {
                    Text("Narrative Point of View")
                        .font(.headline)
                    
                    styleSelectionGrid(
                        styles: narrativeStyles,
                        selectedStyle: $selectedNarrativeStyle
                    )
                }
                .padding(.horizontal)
                
                // Literary Style
                VStack(alignment: .leading, spacing: 12) {
                    Text("Literary Style")
                        .font(.headline)
                    
                    styleSelectionGrid(
                        styles: literaryStyles,
                        selectedStyle: $selectedLiteraryStyle
                    )
                }
                .padding(.horizontal)
                
                // Storytelling Approach
                VStack(alignment: .leading, spacing: 12) {
                    Text("Storytelling Approach")
                        .font(.headline)
                    
                    styleSelectionGrid(
                        styles: storytellingStyles,
                        selectedStyle: $selectedStorytellingStyle
                    )
                }
                .padding(.horizontal)
                
                // Style descriptions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Style descriptions")
                        .font(.headline)
                    
                    Group {
                        Text("Narrative Point of View:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("• First Person: The story is told from the 'I' perspective")
                        Text("• Third Person Limited: Follows one character's perspective")
                        Text("• Third Person Omniscient: All-knowing narrator")
                        Text("• Multiple Viewpoints: Story told from different characters' perspectives")
                        Text("• Stream of Consciousness: Direct thoughts and feelings")
                        
                        Text("Literary Style:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        Text("• Minimalist: Sparse, economical writing")
                        Text("• Lyrical: Poetic, flowing language")
                        Text("• Magical Realism: Realistic setting with magical elements")
                        Text("• Epistolary: Told through letters, documents, or messages")
                        
                        Text("Storytelling Approach:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        Text("• Non-linear: Events not in chronological order")
                        Text("• Frame Story: Story within a story")
                        Text("• Parallel Narratives: Multiple storylines running together")
                        Text("• Unreliable Narrator: Narrator's credibility is questionable")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onChange(of: combinedStyle) { _, _ in
            updateStyle()
        }
    }
    
    private var synopsisTab: some View {
        Form {
            Section("Synopsis") {
                TextEditor(text: $editedSynopsis)
                    .frame(minHeight: 300)
                    .onChange(of: editedSynopsis) { _, newValue in
                        var doc = viewModel.document
                        doc.synopsis = newValue
                        viewModel.document = doc
                    }
            }

            Section("Writing tips") {
                Text("A good synopsis should include:")
                    .font(.subheadline)

                Group {
                    Text("• Main plot points and story arc")
                    Text("• Key character motivations")
                    Text("• Major conflicts and their resolution")
                    Text("• The story's theme and message")
                    Text("• The ending (unlike a blurb)")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
    }
    #endif

    // MARK: - Shared Helpers

    private func templateIcon(for template: BookTemplate) -> String {
        switch template.name {
        case "Hero's Journey": return "figure.walk.motion"
        case "Romance Outline": return "heart.fill"
        case "Save the Cat": return "cat.fill"
        case "Three-Act Structure": return "rectangle.split.3x1.fill"
        case "Story Circle": return "circle.dashed"
        case "Seven-Point Structure": return "7.circle.fill"
        case "Freytag's Pyramid": return "triangle.fill"
        case "Fichtean Curve": return "waveform.path.ecg"
        case "Kishōtenketsu": return "square.grid.2x2.fill"
        default: return "doc.badge.plus"
        }
    }

    private func styleSelectionGrid(styles: [String], selectedStyle: Binding<String>) -> some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
            ForEach(styles, id: \.self) { style in
                if selectedStyle.wrappedValue == style {
                    Button(action: { 
                        selectedStyle.wrappedValue = style == selectedStyle.wrappedValue ? "" : style
                    }) {
                        Text(style)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: { 
                        selectedStyle.wrappedValue = style == selectedStyle.wrappedValue ? "" : style
                    }) {
                        Text(style)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private func loadData() {
        editedTitle = viewModel.document.title
        editedAuthor = viewModel.document.author
        editedDescription = viewModel.document.description
        editedSynopsis = viewModel.document.synopsis
        
        // Load genres
        selectedGenres = Set(viewModel.document.genre.split(separator: ", ").map(String.init))
        
        // Load styles
        let styles = viewModel.document.style.split(separator: ", ").map(String.init)
        selectedNarrativeStyle = styles.first { narrativeStyles.contains($0) } ?? ""
        selectedLiteraryStyle = styles.first { literaryStyles.contains($0) } ?? ""
        selectedStorytellingStyle = styles.first { storytellingStyles.contains($0) } ?? ""
    }
    
    private func updateGenre() {
        var doc = viewModel.document
        doc.genre = Array(selectedGenres).sorted().joined(separator: ", ")
        viewModel.document = doc
    }

    private func updateStyle() {
        var doc = viewModel.document
        doc.style = combinedStyle
        viewModel.document = doc
    }
}

// Helper view for flowing layout of selected genres
struct GenreFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var height: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var currentRowY: CGFloat = 0
        
        for size in sizes {
            if currentRowWidth + size.width > (proposal.width ?? .infinity) {
                currentRowY += currentRowHeight + spacing
                height = currentRowY
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRowWidth += size.width + spacing
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }
        
        return CGSize(width: proposal.width ?? .infinity, height: height + currentRowHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#if DEBUG
struct ProjectInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProjectInfoView(viewModel: DocumentViewModel())
        }
    }
}
#endif 