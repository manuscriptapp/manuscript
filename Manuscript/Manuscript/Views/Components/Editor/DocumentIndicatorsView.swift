import SwiftUI

#if os(macOS)
/// Displays small indicator icons for synopsis, notes, and comments in the toolbar.
/// Clicking each icon opens a compact popover with the content preview.
struct DocumentIndicatorsView: View {
    @ObservedObject var detailViewModel: DocumentDetailViewModel

    @State private var showSynopsisPopover = false
    @State private var showNotesPopover = false
    @State private var showCommentsPopover = false

    // Content detection
    private var hasSynopsis: Bool {
        !detailViewModel.editedSynopsis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasNotes: Bool {
        !detailViewModel.editedNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasComments: Bool {
        !detailViewModel.comments.isEmpty
    }

    var body: some View {
        HStack(spacing: 6) {
            if hasSynopsis {
                synopsisIndicator
            }

            if hasNotes {
                notesIndicator
            }

            if hasComments {
                commentsIndicator
            }
        }
    }

    // MARK: - Synopsis Indicator

    private var synopsisIndicator: some View {
        Button {
            showSynopsisPopover.toggle()
        } label: {
            Image(systemName: "text.quote")
                .font(.system(size: 11))
                .foregroundStyle(.secondary.opacity(0.7))
        }
        .buttonStyle(.plain)
        .help("Synopsis")
        .popover(isPresented: $showSynopsisPopover, arrowEdge: .bottom) {
            synopsisPopover
        }
    }

    private var synopsisPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Synopsis", systemImage: "text.quote")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(detailViewModel.editedSynopsis)
                .font(.callout)
                .lineLimit(10)
                .frame(minWidth: 200, maxWidth: 300, alignment: .leading)
        }
        .padding(12)
    }

    // MARK: - Notes Indicator

    private var notesIndicator: some View {
        Button {
            showNotesPopover.toggle()
        } label: {
            Image(systemName: "note.text")
                .font(.system(size: 11))
                .foregroundStyle(.secondary.opacity(0.7))
        }
        .buttonStyle(.plain)
        .help("Notes")
        .popover(isPresented: $showNotesPopover, arrowEdge: .bottom) {
            notesPopover
        }
    }

    private var notesPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(detailViewModel.editedNotes)
                .font(.callout)
                .lineLimit(15)
                .frame(minWidth: 200, maxWidth: 300, alignment: .leading)
        }
        .padding(12)
    }

    // MARK: - Comments Indicator

    private var commentsIndicator: some View {
        Button {
            showCommentsPopover.toggle()
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 11))
                Text("\(detailViewModel.comments.count)")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.secondary.opacity(0.7))
        }
        .buttonStyle(.plain)
        .help("Comments")
        .popover(isPresented: $showCommentsPopover, arrowEdge: .bottom) {
            commentsPopover
        }
    }

    private var commentsPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("\(detailViewModel.comments.count) Comment\(detailViewModel.comments.count == 1 ? "" : "s")", systemImage: "text.bubble")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    showCommentsPopover = false
                    detailViewModel.inspectorSelectedTab = 1 // Comments tab
                    detailViewModel.isInspectorPresented = true
                } label: {
                    Text("Open Inspector")
                        .font(.caption)
                }
                .buttonStyle(.link)
            }

            if detailViewModel.comments.isEmpty {
                Text("No comments")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(detailViewModel.comments.prefix(5)) { comment in
                            commentRow(comment)
                        }

                        if detailViewModel.comments.count > 5 {
                            Text("+ \(detailViewModel.comments.count - 5) more...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(minWidth: 200, maxWidth: 300, maxHeight: 200)
            }
        }
        .padding(12)
    }

    private func commentRow(_ comment: ManuscriptDocument.DocumentComment) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Show highlighted text excerpt if available
            if let range = comment.range {
                let excerpt = getTextExcerpt(at: range)
                if !excerpt.isEmpty {
                    Text("\"\(excerpt)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text(comment.text)
                .font(.callout)
                .lineLimit(2)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(4)
    }

    private func getTextExcerpt(at range: ManuscriptDocument.DocumentComment.Range) -> String {
        let content = detailViewModel.editedContent
        guard range.location >= 0,
              range.location + range.length <= content.count else {
            return ""
        }

        let startIndex = content.index(content.startIndex, offsetBy: range.location)
        let endIndex = content.index(startIndex, offsetBy: min(range.length, 50))
        var excerpt = String(content[startIndex..<endIndex])

        if range.length > 50 {
            excerpt += "..."
        }

        return excerpt
    }
}

#Preview {
    let doc = ManuscriptDocument.Document(
        title: "Test",
        synopsis: "A brief synopsis of this chapter.",
        notes: "Some notes about the document.",
        content: "Sample content"
    )
    let vm = DocumentViewModel()
    let detailVM = DocumentDetailViewModel(document: doc, documentViewModel: vm)

    return DocumentIndicatorsView(detailViewModel: detailVM)
        .padding()
}
#endif
