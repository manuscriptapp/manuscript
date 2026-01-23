import SwiftUI

/// Inline status dropdown for the outline view
struct OutlineStatusPicker: View {
    let document: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel

    private var currentStatus: ManuscriptStatus? {
        guard let statusId = document.statusId else { return nil }
        return viewModel.document.statuses.first { $0.id == statusId }
    }

    var body: some View {
        Menu {
            // None option
            Button {
                viewModel.updateDocumentMetadata(document, labelId: document.labelId, statusId: nil)
            } label: {
                HStack {
                    Text("None")
                    if document.statusId == nil {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            // Status options
            ForEach(viewModel.document.statuses) { status in
                Button {
                    viewModel.updateDocumentMetadata(document, labelId: document.labelId, statusId: status.id)
                } label: {
                    HStack {
                        Text(status.name)
                        if document.statusId == status.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            if let status = currentStatus {
                Text(status.name)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    OutlineStatusPicker(
        document: ManuscriptDocument.Document(title: "Test"),
        viewModel: DocumentViewModel()
    )
}
#endif
