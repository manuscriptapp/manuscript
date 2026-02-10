import SwiftUI

struct SnapshotsTabView: View {
    let document: ManuscriptDocument.Document
    @ObservedObject var documentViewModel: DocumentViewModel
    @State private var selectedSnapshot: DocumentSnapshot?
    @State private var isPreviewPresented = false
    @State private var snapshots: [DocumentSnapshot] = []

    private func refreshSnapshots() {
        snapshots = documentViewModel.snapshotsForDocument(document.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Snapshots")
                        .font(.headline)
                    Text("\(snapshots.count) snapshot\(snapshots.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    documentViewModel.takeSnapshotOfDocument(document)
                } label: {
                    Label("Take Snapshot", systemImage: "camera.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.accent)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            if snapshots.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No Snapshots")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Take a snapshot to save a point-in-time version of this document that you can restore later.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        documentViewModel.takeSnapshotOfDocument(document)
                    } label: {
                        Label("Take Snapshot", systemImage: "camera.circle")
                    }
                    .manuscriptPrimaryButton()
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Snapshots list
                List {
                    ForEach(snapshots) { snapshot in
                        SnapshotRow(snapshot: snapshot, currentWordCount: document.wordCount)
                            .onTapGesture {
                                selectedSnapshot = snapshot
                                isPreviewPresented = true
                            }
                    }
                    .onDelete(perform: deleteSnapshots)
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $isPreviewPresented) {
            if let snapshot = selectedSnapshot {
                SnapshotPreviewSheet(
                    snapshot: snapshot,
                    document: document,
                    documentViewModel: documentViewModel,
                    isPresented: $isPreviewPresented
                )
            }
        }
        .onAppear {
            refreshSnapshots()
        }
        .onChange(of: documentViewModel.snapshotUpdateTrigger) { _, _ in
            refreshSnapshots()
        }
    }

    private func deleteSnapshots(at offsets: IndexSet) {
        for index in offsets {
            let snapshot = snapshots[index]
            documentViewModel.removeSnapshot(snapshot)
        }
    }
}

#if DEBUG
#Preview {
    let viewModel = DocumentViewModel()
    let doc = ManuscriptDocument.Document(
        title: "Sample Document",
        notes: "Notes",
        content: "Sample content with some words for testing"
    )

    SnapshotsTabView(document: doc, documentViewModel: viewModel)
}
#endif
