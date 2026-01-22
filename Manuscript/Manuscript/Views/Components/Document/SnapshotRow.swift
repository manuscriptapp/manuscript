import SwiftUI

struct SnapshotRow: View {
    let snapshot: DocumentSnapshot
    let currentWordCount: Int

    private var wordCountDelta: Int {
        currentWordCount - snapshot.wordCount
    }

    private var wordCountDeltaText: String {
        if wordCountDelta > 0 {
            return "+\(wordCountDelta)"
        } else if wordCountDelta < 0 {
            return "\(wordCountDelta)"
        }
        return "0"
    }

    private var deltaColor: Color {
        if wordCountDelta > 0 {
            return .green
        } else if wordCountDelta < 0 {
            return .red
        }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon based on snapshot type
            Image(systemName: snapshot.iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title row
                HStack {
                    Text(snapshot.displayTitle)
                        .font(.headline)
                        .lineLimit(1)

                    if snapshot.snapshotType != .manual {
                        Text(snapshot.snapshotType.rawValue.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badgeColor.opacity(0.2))
                            .foregroundStyle(badgeColor)
                            .cornerRadius(4)
                    }
                }

                // Stats row
                HStack(spacing: 8) {
                    Text(snapshot.relativeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\u{2022}")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("\(snapshot.wordCount) words")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if wordCountDelta != 0 {
                        Text("(\(wordCountDeltaText) since)")
                            .font(.caption)
                            .foregroundStyle(deltaColor)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var iconColor: Color {
        switch snapshot.snapshotType {
        case .manual:
            return .blue
        case .auto:
            return .gray
        case .milestone:
            return .orange
        }
    }

    private var badgeColor: Color {
        switch snapshot.snapshotType {
        case .manual:
            return .blue
        case .auto:
            return .gray
        case .milestone:
            return .orange
        }
    }
}

#if DEBUG
#Preview {
    List {
        SnapshotRow(
            snapshot: DocumentSnapshot(
                documentId: UUID(),
                title: "Before major revision",
                snapshotType: .manual,
                content: "Sample content here with some words",
                notes: "Notes",
                outline: "Outline"
            ),
            currentWordCount: 150
        )

        SnapshotRow(
            snapshot: DocumentSnapshot(
                documentId: UUID(),
                snapshotType: .auto,
                content: "Auto saved content",
                notes: "",
                outline: ""
            ),
            currentWordCount: 100
        )

        SnapshotRow(
            snapshot: DocumentSnapshot(
                documentId: UUID(),
                title: "Chapter Complete",
                snapshotType: .milestone,
                content: "Milestone content that is longer than the current",
                notes: "Notes",
                outline: "Outline"
            ),
            currentWordCount: 50
        )
    }
}
#endif
