import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Entry Row

struct WritingHistoryEntryRow: View {
    let entry: WritingHistoryEntry

    var body: some View {
        HStack(spacing: 16) {
            // Date column
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.dayOfWeek)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(entry.shortDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(width: 60, alignment: .leading)

            // Word count bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        #if os(macOS)
                        .fill(Color(nsColor: .quaternaryLabelColor))
                        #else
                        .fill(Color(uiColor: .tertiarySystemFill))
                        #endif
                        .cornerRadius(4)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: barWidth(for: geometry.size.width))
                        .cornerRadius(4)
                }
            }
            .frame(height: 24)

            // Word count
            Text("\(entry.wordsWritten.formatted())")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 70, alignment: .trailing)

            Text("words")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        #if os(macOS)
        .background(Color(nsColor: .textBackgroundColor))
        #else
        .background(Color(uiColor: .systemBackground))
        #endif
        .cornerRadius(8)
    }

    private func barWidth(for maxWidth: CGFloat) -> CGFloat {
        // Assume max of 5000 words for scaling (can be adjusted)
        let maxWordsForScale = 5000.0
        let percentage = min(Double(entry.wordsWritten) / maxWordsForScale, 1.0)
        return maxWidth * CGFloat(percentage)
    }
}
