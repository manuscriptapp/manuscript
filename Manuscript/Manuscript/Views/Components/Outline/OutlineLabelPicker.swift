import SwiftUI

/// Inline label dropdown for the outline view
struct OutlineLabelPicker: View {
    let document: ManuscriptDocument.Document
    @ObservedObject var viewModel: DocumentViewModel

    private var currentLabel: ManuscriptLabel? {
        guard let labelId = document.labelId else { return nil }
        return viewModel.document.labels.first { $0.id == labelId }
    }

    var body: some View {
        Menu {
            // None option
            Button {
                viewModel.updateDocumentMetadata(document, labelId: nil, statusId: document.statusId)
            } label: {
                HStack {
                    Text("None")
                    if document.labelId == nil {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            // Label options
            ForEach(viewModel.document.labels) { label in
                Button {
                    viewModel.updateDocumentMetadata(document, labelId: label.id, statusId: document.statusId)
                } label: {
                    HStack {
                        Circle()
                            .fill(Color(hex: label.color) ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(label.name)
                        if document.labelId == label.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            if let label = currentLabel {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: label.color) ?? .gray)
                        .frame(width: 8, height: 8)
                    Text(label.name)
                        .font(.caption)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: label.color).opacity(0.2))
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
    OutlineLabelPicker(
        document: ManuscriptDocument.Document(title: "Test"),
        viewModel: DocumentViewModel()
    )
}
#endif
