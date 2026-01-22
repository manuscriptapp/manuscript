import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Compact Writing History View (for sidebar/overview)

struct CompactWritingHistoryView: View {
    let writingHistory: WritingHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.blue)
                Text("Writing History")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: WritingHistoryView(writingHistory: writingHistory)) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            if writingHistory.isEmpty {
                Text("No writing history yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("\(writingHistory.totalWordsWritten.formatted())")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Total Words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading) {
                        Text("\(writingHistory.currentStreak)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Day Streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading) {
                        Text("\(writingHistory.wordsLast7Days.formatted())")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Last 7 Days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Mini chart of last 7 days
                miniChart
                    .frame(height: 40)
            }
        }
        .padding()
        .background(Color(PlatformColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var miniChart: some View {
        let entries = writingHistory.entriesForLastDays(7)
        let maxWords = max(entries.map(\.wordsWritten).max() ?? 1, 1)

        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(entries) { entry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(
                        width: 12,
                        height: max(4, CGFloat(entry.wordsWritten) / CGFloat(maxWords) * 36)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
