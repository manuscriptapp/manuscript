import SwiftUI
import SwiftData

/// E-book style reading view that displays all documents in a continuous flow
struct ProjectReadingView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @State private var scrollPosition: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Book title page
                titlePage

                // All documents in reading order
                documentFlow
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
        .scrollPosition(id: $scrollPosition)
    }

    private var titlePage: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            Text(viewModel.document.title.isEmpty ? "Untitled" : viewModel.document.title)
                .font(.system(size: 32, weight: .light, design: .serif))
                .multilineTextAlignment(.center)

            if !viewModel.document.author.isEmpty {
                Text("by \(viewModel.document.author)")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: 80)

            Divider()
                .padding(.horizontal, 40)

            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity)
    }

    private var documentFlow: some View {
        ForEach(allDocumentsInOrder()) { item in
            documentSection(item)
        }
    }

    @ViewBuilder
    private func documentSection(_ item: ReadingItem) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Chapter/Section header
            if item.isChapterStart {
                chapterHeader(item)
            }

            // Document title (if not a chapter header)
            if !item.isChapterStart {
                Text(item.document.title)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .padding(.top, 24)
            }

            // Document content
            Text(item.document.content)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .lineSpacing(8)
                .kerning(0.3)
        }
        .id(item.document.id)
        .padding(.bottom, 32)
    }

    private func chapterHeader(_ item: ReadingItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let folderTitle = item.folderTitle {
                Text(folderTitle.uppercased())
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(.secondary)
                    .kerning(2)
                    .padding(.top, 48)
            }

            Text(item.document.title)
                .font(.system(size: 26, weight: .light, design: .serif))

            Divider()
                .padding(.top, 8)
                .padding(.trailing, 60)
        }
    }

    // MARK: - Document Ordering

    private func allDocumentsInOrder() -> [ReadingItem] {
        var items: [ReadingItem] = []
        collectDocuments(from: viewModel.rootFolder, into: &items, folderTitle: nil, isFirstInFolder: true)
        return items
    }

    private func collectDocuments(from folder: ManuscriptFolder, into items: inout [ReadingItem], folderTitle: String?, isFirstInFolder: Bool) {
        // Sort documents by order
        let sortedDocuments = folder.documents.sorted { $0.order < $1.order }

        for (index, document) in sortedDocuments.enumerated() {
            let isFirst = index == 0 && isFirstInFolder
            items.append(ReadingItem(
                document: document,
                folderTitle: isFirst ? folderTitle : nil,
                isChapterStart: isFirst && folderTitle != nil
            ))
        }

        // Sort and process subfolders
        let sortedSubfolders = folder.subfolders.sorted { $0.order < $1.order }
        for subfolder in sortedSubfolders {
            collectDocuments(from: subfolder, into: &items, folderTitle: subfolder.title, isFirstInFolder: true)
        }
    }
}

// MARK: - Reading Item Model

private struct ReadingItem: Identifiable {
    let document: ManuscriptDocument.Document
    let folderTitle: String?
    let isChapterStart: Bool

    var id: UUID { document.id }
}

#Preview {
    ProjectReadingView(viewModel: {
        let vm = DocumentViewModel()
        vm.bind(to: .constant(ManuscriptDocument.sampleDocument))
        return vm
    }())
}
