import SwiftUI

struct SnapshotPreviewSheet: View {
    let snapshot: DocumentSnapshot
    let document: ManuscriptDocument.Document
    @ObservedObject var documentViewModel: DocumentViewModel
    @Binding var isPresented: Bool

    @State private var selectedSegment = 0 // 0 = Content, 1 = Notes, 2 = Synopsis
    @State private var showRestoreConfirmation = false
    @State private var showDeleteConfirmation = false

    private var wordCountDelta: Int {
        document.wordCount - snapshot.wordCount
    }

    private var wordCountDeltaText: String {
        if wordCountDelta > 0 {
            return "+\(wordCountDelta) words since"
        } else if wordCountDelta < 0 {
            return "\(wordCountDelta) words since"
        }
        return "Same word count"
    }

    private var deltaColor: Color {
        if wordCountDelta > 0 {
            return .green
        } else if wordCountDelta < 0 {
            return .red
        }
        return .secondary
    }

    private var selectedContent: String {
        switch selectedSegment {
        case 0:
            return snapshot.content.isEmpty ? "No content" : snapshot.content
        case 1:
            return snapshot.notes.isEmpty ? "No notes" : snapshot.notes
        case 2:
            return snapshot.synopsis.isEmpty ? "No synopsis" : snapshot.synopsis
        default:
            return ""
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats header
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        // Word count
                        VStack(spacing: 4) {
                            Text("\(snapshot.wordCount)")
                                .font(.title2.bold())
                            Text("Words")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()
                            .frame(height: 40)

                        // Change delta
                        VStack(spacing: 4) {
                            Text(wordCountDeltaText)
                                .font(.subheadline)
                                .foregroundStyle(deltaColor)
                            Text("Change")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()
                            .frame(height: 40)

                        // Date
                        VStack(spacing: 4) {
                            Text(snapshot.timestamp, format: .dateTime.month(.abbreviated).day())
                                .font(.subheadline)
                            Text(snapshot.timestamp, format: .dateTime.hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    #if os(macOS)
                    .background(Color(nsColor: .controlBackgroundColor))
                    #else
                    .background(Color(uiColor: .secondarySystemBackground))
                    #endif
                    .cornerRadius(12)
                }
                .padding()

                // Segment picker
                Picker("Content Type", selection: $selectedSegment) {
                    Text("Content").tag(0)
                    Text("Notes").tag(1)
                    Text("Synopsis").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom)

                Divider()

                // Content preview
                ScrollView {
                    Text(selectedContent)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .foregroundStyle(selectedContent.hasPrefix("No ") ? .secondary : .primary)
                }
                #if os(macOS)
                .background(Color(nsColor: .textBackgroundColor))
                #else
                .background(Color(uiColor: .systemBackground))
                #endif
            }
            .navigationTitle(snapshot.displayTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    ManuscriptDoneButton {
                        isPresented = false
                    }
                }

                #if os(iOS)
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showRestoreConfirmation = true
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Snapshot", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showRestoreConfirmation = true
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                    }
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                #endif
            }
            .alert("Restore Snapshot?", isPresented: $showRestoreConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Restore") {
                    documentViewModel.restoreFromSnapshot(snapshot)
                    isPresented = false
                }
            } message: {
                Text("This will replace the current content, notes, and outline with the snapshot version. This action cannot be undone.")
            }
            .alert("Delete Snapshot?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    documentViewModel.removeSnapshot(snapshot)
                    isPresented = false
                }
            } message: {
                Text("This snapshot will be permanently deleted.")
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
    }
}

#if DEBUG
#Preview {
    SnapshotPreviewSheet(
        snapshot: DocumentSnapshot(
            documentId: UUID(),
            title: "Before revision",
            snapshotType: .manual,
            content: "This is the original content of the document before the major revision was made. It contains several paragraphs of text that explain the main concepts and ideas.",
            notes: "Some notes about the document",
            synopsis: "Chapter 1 outline"
        ),
        document: ManuscriptDocument.Document(
            title: "Sample",
            content: "Updated content that is longer"
        ),
        documentViewModel: DocumentViewModel(),
        isPresented: .constant(true)
    )
}
#endif
