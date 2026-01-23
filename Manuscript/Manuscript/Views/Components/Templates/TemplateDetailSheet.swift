import SwiftUI
import UniformTypeIdentifiers

struct DocumentRowView: View {
    let document: DocumentTemplate
    let index: Int
    let accentColor: Color
    @State private var showingNotes = false

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index + 1).")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 20, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.subheadline)

                if !document.synopsis.isEmpty {
                    Text(document.synopsis)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !document.notes.isEmpty {
                Button {
                    showingNotes.toggle()
                } label: {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow.opacity(0.9))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingNotes, arrowEdge: .trailing) {
                    ScrollView {
                        Text(cleanMarkdown(document.notes))
                            .font(.callout)
                            .padding()
                            .frame(minWidth: 280, maxWidth: 360, alignment: .leading)
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// Remove markdown headers and clean up notes for display
    private func cleanMarkdown(_ text: String) -> String {
        text
            .replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "\\*\\*([^*]+)\\*\\*", with: "$1", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ActTemplateView: View {
    let folder: FolderTemplate
    let accentColor: Color
    @State private var isExpanded = false

    private var sortedDocuments: [DocumentTemplate] {
        folder.documents.sorted { $0.order < $1.order }
    }

    private var chapterCount: Int {
        sortedDocuments.count
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(sortedDocuments.enumerated()), id: \.offset) { index, document in
                    DocumentRowView(document: document, index: index, accentColor: accentColor)
                }
            }
            .padding(.leading, 4)
            .padding(.top, 8)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.title)
                        .font(.headline)

                    Text(folder.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(chapterCount)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.15))
                    .foregroundStyle(accentColor)
                    .clipShape(Capsule())
            }
        }
        .tint(.primary)
    }
}

struct TemplateDetailSheet: View {
    let template: BookTemplate
    let onCreateBook: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewBookSheet = false

    private var symbol: String {
        switch template.name {
        case "Hero's Journey":
            return "figure.walk.motion"
        case "Romance Outline":
            return "heart.fill"
        case "Save the Cat":
            return "cat.fill"
        case "Three-Act Structure":
            return "rectangle.split.3x1.fill"
        case "Story Circle":
            return "circle.dashed"
        case "Seven-Point Structure":
            return "7.circle.fill"
        case "Freytag's Pyramid":
            return "triangle.fill"
        case "Fichtean Curve":
            return "waveform.path.ecg"
        case "Kishōtenketsu":
            return "square.grid.2x2.fill"
        default:
            return "doc.badge.plus"
        }
    }

    private var accentColor: Color {
        switch template.name {
        case "Hero's Journey":
            return .brown
        case "Romance Outline":
            return .pink
        case "Save the Cat":
            return .orange
        case "Three-Act Structure":
            return .blue
        case "Story Circle":
            return .purple
        case "Seven-Point Structure":
            return .green
        case "Freytag's Pyramid":
            return .indigo
        case "Fichtean Curve":
            return .red
        case "Kishōtenketsu":
            return .teal
        default:
            return .gray
        }
    }

    private var gradient: LinearGradient {
        switch template.name {
        case "Hero's Journey":
            return LinearGradient(
                colors: [.brown.opacity(0.8), Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Romance Outline":
            return LinearGradient(
                colors: [.pink.opacity(0.8), .red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Save the Cat":
            return LinearGradient(
                colors: [.orange.opacity(0.8), .yellow.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Three-Act Structure":
            return LinearGradient(
                colors: [.blue.opacity(0.8), .cyan.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Story Circle":
            return LinearGradient(
                colors: [.purple.opacity(0.8), .pink.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Seven-Point Structure":
            return LinearGradient(
                colors: [.green.opacity(0.8), .mint.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Freytag's Pyramid":
            return LinearGradient(
                colors: [.indigo.opacity(0.8), .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Fichtean Curve":
            return LinearGradient(
                colors: [.red.opacity(0.8), .orange.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Kishōtenketsu":
            return LinearGradient(
                colors: [.teal.opacity(0.8), .green.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var actCount: Int {
        template.structure.subfolders.count
    }

    private var chapterCount: Int {
        func countDocuments(in folder: FolderTemplate) -> Int {
            let documentsInFolder = folder.documents.count
            let documentsInSubfolders = folder.subfolders.reduce(0) { count, subfolder in
                count + countDocuments(in: subfolder)
            }
            return documentsInFolder + documentsInSubfolders
        }
        return countDocuments(in: template.structure)
    }

    private var notesCount: Int {
        func countNotes(in folder: FolderTemplate) -> Int {
            let notesInFolder = folder.documents.filter { !$0.notes.isEmpty }.count
            let notesInSubfolders = folder.subfolders.reduce(0) { count, subfolder in
                count + countNotes(in: subfolder)
            }
            return notesInFolder + notesInSubfolders
        }
        return countNotes(in: template.structure)
    }

    private var sortedActs: [FolderTemplate] {
        template.structure.subfolders.sorted { $0.order < $1.order }
    }

    private var headerView: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 64, height: 64)

                Image(systemName: symbol)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(template.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(template.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    private var statsView: some View {
        HStack(spacing: 0) {
            statItem(value: actCount, label: "Acts", icon: "folder.fill")
            Divider()
                .frame(height: 32)
            statItem(value: chapterCount, label: "Chapters", icon: "doc.text.fill")
            Divider()
                .frame(height: 32)
            statItem(value: notesCount, label: "Writing Notes", icon: "lightbulb.fill")
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.08))
        )
        .padding(.horizontal)
    }

    private func statItem(value: Int, label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.headline)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var structureView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Structure")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(Array(sortedActs.enumerated()), id: \.offset) { _, act in
                    ActTemplateView(folder: act, accentColor: accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.secondary.opacity(0.06))
                        )
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var examplesView: some View {
        if !template.examples.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Example Works")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(Array(template.examples.enumerated()), id: \.offset) { _, example in
                        HStack(spacing: 10) {
                            Image(systemName: example.medium.icon)
                                .font(.caption)
                                .foregroundStyle(accentColor)
                                .frame(width: 16)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(example.title)
                                    .font(.subheadline)
                                    .lineLimit(1)

                                HStack(spacing: 4) {
                                    if let creator = example.creator {
                                        Text(creator)
                                            .lineLimit(1)
                                    }
                                    if let year = example.year {
                                        Text("(\(String(year)))")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.secondary.opacity(0.06))
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var sourcesView: some View {
        if !template.sources.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Learn More")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 6) {
                    ForEach(Array(template.sources.enumerated()), id: \.offset) { _, source in
                        HStack(spacing: 10) {
                            Image(systemName: source.type.icon)
                                .font(.caption)
                                .foregroundStyle(accentColor)
                                .frame(width: 16)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.title)
                                    .font(.subheadline)
                                    .lineLimit(1)

                                if let author = source.author {
                                    Text(author)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if let urlString = source.url, let url = URL(string: urlString) {
                                Link(destination: url) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundStyle(accentColor)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.secondary.opacity(0.06))
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    statsView
                    examplesView
                    structureView
                    sourcesView
                }
                .padding(.bottom, 24)
            }
            #if os(macOS)
            .frame(minWidth: 520, minHeight: 500)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create Book") {
                        showingNewBookSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showingNewBookSheet) {
                NewBookSheet(
                    preSelectedTemplate: template
                ) { _ in
                    onCreateBook()
                    dismiss()
                }
            }
        }
    }
}

#if DEBUG
#Preview("Hero's Journey") {
    TemplateDetailSheet(template: .heroJourney, onCreateBook: {})
        .frame(width: 520, height: 600)
}

#Preview("Save the Cat") {
    TemplateDetailSheet(template: .saveTheCat, onCreateBook: {})
        .frame(width: 520, height: 600)
}
#endif
