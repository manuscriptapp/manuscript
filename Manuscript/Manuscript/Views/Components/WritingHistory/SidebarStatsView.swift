import SwiftUI

/// Stats view for the project sidebar
/// Shows total words, days written, current streak, longest streak, and average words/day
struct SidebarStatsView: View {
    let totalWords: Int
    let writingHistory: WritingHistory

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            statRow(
                icon: "character.cursor.ibeam",
                color: .blue,
                title: "Total Words",
                value: totalWords.formatted()
            )

            Divider()

            statRow(
                icon: "calendar",
                color: .green,
                title: "Days Written",
                value: "\(writingHistory.daysWritten)"
            )

            Divider()

            statRow(
                icon: "flame.fill",
                color: writingHistory.currentStreak > 0 ? .orange : .secondary,
                title: "Current Streak",
                value: "\(writingHistory.currentStreak) days"
            )

            Divider()

            statRow(
                icon: "trophy.fill",
                color: .yellow,
                title: "Longest Streak",
                value: "\(writingHistory.longestStreak) days",
                subtitle: writingHistory.longestStreakDateRange
            )

            Divider()

            statRow(
                icon: "chart.line.uptrend.xyaxis",
                color: .purple,
                title: "Avg Words/Day",
                value: writingHistory.averageWordsPerDay.formatted()
            )
        }
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        #else
        .background(Color(uiColor: .secondarySystemBackground))
        #endif
    }

    private func statRow(
        icon: String,
        color: Color,
        title: String,
        value: String,
        subtitle: String? = nil
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#if DEBUG
struct SidebarStatsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SidebarStatsView(
                totalWords: 45_892,
                writingHistory: sampleHistory
            )
            .frame(width: 280)

            SidebarStatsView(
                totalWords: 0,
                writingHistory: WritingHistory()
            )
            .frame(width: 280)
        }
        .padding()
    }

    static var sampleHistory: WritingHistory {
        var entries: [WritingHistoryEntry] = []
        let calendar = Calendar.current

        for i in 0..<15 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            entries.append(WritingHistoryEntry(
                date: date,
                wordsWritten: Int.random(in: 500...2000)
            ))
        }

        return WritingHistory(entries: entries)
    }
}
#endif
