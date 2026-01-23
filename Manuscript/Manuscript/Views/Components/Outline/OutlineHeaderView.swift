import SwiftUI

/// Header row for the outline view with sortable column headers
struct OutlineHeaderView: View {
    @Binding var sortColumn: OutlineSortColumn
    @Binding var sortAscending: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Title column (flexible)
            sortableHeader(.title)
                .frame(minWidth: 200)

            Divider()
                .frame(height: 20)

            // Label column (fixed)
            sortableHeader(.label)
                .frame(width: 100)

            Divider()
                .frame(height: 20)

            // Status column (fixed)
            sortableHeader(.status)
                .frame(width: 100)

            Divider()
                .frame(height: 20)

            // Keywords column (fixed)
            sortableHeader(.keywords)
                .frame(width: 120)

            Divider()
                .frame(height: 20)

            // Words column (fixed)
            sortableHeader(.words)
                .frame(width: 70)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
    }

    private func sortableHeader(_ column: OutlineSortColumn) -> some View {
        Button {
            if sortColumn == column {
                sortAscending.toggle()
            } else {
                sortColumn = column
                sortAscending = true
            }
        } label: {
            HStack(spacing: 4) {
                Text(column.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var sortColumn: OutlineSortColumn = .title
    @Previewable @State var sortAscending: Bool = true
    OutlineHeaderView(sortColumn: $sortColumn, sortAscending: $sortAscending)
}
#endif
