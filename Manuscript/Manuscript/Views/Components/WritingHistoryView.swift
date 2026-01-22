import SwiftUI
#if canImport(Charts)
import Charts
#endif
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Writing History View

struct WritingHistoryView: View {
    let writingHistory: WritingHistory
    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var selectedEntry: WritingHistoryEntry?
    @State private var periodOffset: Int = 0  // 0 = current period, -1 = previous, etc.

    enum TimeRange: String, CaseIterable {
        case last7Days = "7 Days"
        case last30Days = "30 Days"
        case last90Days = "90 Days"
        case allTime = "All Time"

        var days: Int? {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            case .allTime: return nil
            }
        }

        var periodLabel: String {
            switch self {
            case .last7Days: return "Week"
            case .last30Days: return "Month"
            case .last90Days: return "Quarter"
            case .allTime: return "All Time"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Statistics Cards
                statisticsSection

                // Chart Section
                chartSection

                // Entries List
                entriesListSection
            }
            .padding()
        }
        .navigationTitle("Writing History")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Total Words",
                    value: "\(writingHistory.totalWordsWritten.formatted())",
                    icon: "character.cursor.ibeam",
                    color: .blue
                )

                StatCard(
                    title: "Days Written",
                    value: "\(writingHistory.daysWritten)",
                    icon: "calendar",
                    color: .green
                )

                StatCard(
                    title: "Current Streak",
                    value: "\(writingHistory.currentStreak) days",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Longest Streak",
                    value: "\(writingHistory.longestStreak) days",
                    subtitle: writingHistory.longestStreakDateRange,
                    icon: "trophy.fill",
                    color: .yellow
                )

                StatCard(
                    title: "Avg Words/Day",
                    value: "\(writingHistory.averageWordsPerDay.formatted())",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )

                let longStreaks = writingHistory.streaksLongerThan(3)
                if longStreaks > 0 {
                    StatCard(
                        title: "3+ Day Streaks",
                        value: "\(longStreaks)",
                        icon: "flame.circle.fill",
                        color: .red
                    )
                }

                if let bestDay = writingHistory.bestDay {
                    StatCard(
                        title: "Best Day",
                        value: "\(bestDay.wordsWritten.formatted())",
                        subtitle: bestDay.shortDate,
                        icon: "star.fill",
                        color: .pink
                    )
                }
            }
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Writing Activity")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 300)
                .onChange(of: selectedTimeRange) { _, _ in
                    periodOffset = 0  // Reset to current period when changing range
                }
            }

            // Period navigation (not shown for All Time)
            if selectedTimeRange != .allTime {
                HStack {
                    Button {
                        periodOffset -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .disabled(!canGoToPreviousPeriod)

                    Spacer()

                    VStack(spacing: 2) {
                        Text(periodDateRangeText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if periodOffset != 0 {
                            Text(periodRelativeText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        periodOffset += 1
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .disabled(periodOffset >= 0)

                    // Today button when not at current period
                    if periodOffset != 0 {
                        Button("Today") {
                            withAnimation {
                                periodOffset = 0
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 4)
            }

            if filteredEntries.isEmpty {
                emptyPeriodView
                    .frame(height: 200)
            } else {
                #if canImport(Charts)
                if #available(iOS 16.0, macOS 13.0, *) {
                    writingChart
                        .frame(height: 200)
                } else {
                    // Fallback for older OS versions
                    legacyChart
                        .frame(height: 200)
                }
                #else
                legacyChart
                    .frame(height: 200)
                #endif
            }

            // Period statistics
            if selectedTimeRange != .allTime && !filteredEntries.isEmpty {
                periodStatsView
            }
        }
        .padding()
        .background(Color(PlatformColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Empty Period View

    private var emptyPeriodView: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyPeriodIcon)
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.6))

            Text(emptyPeriodTitle)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(emptyPeriodMessage)
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)

            if periodOffset < 0 {
                Button {
                    withAnimation {
                        periodOffset = 0
                    }
                } label: {
                    Label("Back to Current \(selectedTimeRange.periodLabel)", systemImage: "arrow.right")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(PlatformColor.secondarySystemBackground).opacity(0.5))
        .cornerRadius(8)
    }

    private var emptyPeriodIcon: String {
        if periodOffset == 0 {
            return "pencil.slash"
        } else if periodOffset < -2 {
            return "clock.arrow.circlepath"
        } else {
            return "calendar.badge.minus"
        }
    }

    private var emptyPeriodTitle: String {
        if periodOffset == 0 {
            return "No Writing Yet"
        } else {
            return "No Writing This \(selectedTimeRange.periodLabel)"
        }
    }

    private var emptyPeriodMessage: String {
        if periodOffset == 0 {
            switch selectedTimeRange {
            case .last7Days:
                return "Start writing to see your activity here."
            case .last30Days:
                return "Your monthly writing activity will appear here."
            case .last90Days:
                return "Your quarterly writing progress will show up here."
            case .allTime:
                return "Import a Scrivener project or start writing to track your history."
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return "No writing recorded for \(formatter.string(from: periodStartDate))."
        }
    }

    // MARK: - Period Navigation Helpers

    private var periodStartDate: Date {
        let calendar = Calendar.current
        guard let days = selectedTimeRange.days else { return Date.distantPast }
        let endDate = calendar.date(byAdding: .day, value: days * periodOffset, to: Date()) ?? Date()
        return calendar.date(byAdding: .day, value: -days + 1, to: endDate) ?? Date()
    }

    private var periodEndDate: Date {
        let calendar = Calendar.current
        guard let days = selectedTimeRange.days else { return Date() }
        return calendar.date(byAdding: .day, value: days * periodOffset, to: Date()) ?? Date()
    }

    private var periodDateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "MMM d, yyyy"

        let start = periodStartDate
        let end = periodEndDate
        let calendar = Calendar.current

        // If spans different years, show year on both
        if !calendar.isDate(start, equalTo: end, toGranularity: .year) {
            return "\(yearFormatter.string(from: start)) – \(yearFormatter.string(from: end))"
        }
        // If same year but different months, or same month
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    private var periodRelativeText: String {
        if periodOffset == 0 { return "" }
        let periods = abs(periodOffset)
        let periodName = selectedTimeRange.periodLabel.lowercased()
        if periods == 1 {
            return "Previous \(periodName)"
        }
        return "\(periods) \(periodName)s ago"
    }

    private var canGoToPreviousPeriod: Bool {
        // Check if there's any data before the current period
        guard let earliestEntry = writingHistory.entries.first else { return false }
        return earliestEntry.date < periodStartDate
    }

    private var periodStatsView: some View {
        let entries = filteredEntries
        let totalWords = entries.reduce(0) { $0 + $1.wordsWritten }
        let daysWithWriting = entries.filter { $0.wordsWritten > 0 }.count
        let avgPerDay = daysWithWriting > 0 ? totalWords / daysWithWriting : 0

        return HStack(spacing: 24) {
            VStack(alignment: .leading) {
                Text("\(totalWords.formatted())")
                    .font(.headline)
                Text("words this period")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading) {
                Text("\(daysWithWriting)")
                    .font(.headline)
                Text("days written")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading) {
                Text("\(avgPerDay.formatted())")
                    .font(.headline)
                Text("avg/day")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    #if canImport(Charts)
    @available(iOS 16.0, macOS 13.0, *)
    private var writingChart: some View {
        let entries = filteredEntries

        return Chart(entries) { entry in
            BarMark(
                x: .value("Date", entry.date, unit: .day),
                y: .value("Words", entry.wordsWritten)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: chartAxisStride)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    #endif

    private var chartAxisStride: Calendar.Component {
        switch selectedTimeRange {
        case .last7Days: return .day
        case .last30Days: return .weekOfYear
        case .last90Days: return .month
        case .allTime: return .month
        }
    }

    private var legacyChart: some View {
        let entries = filteredEntries
        let maxWords = entries.map(\.wordsWritten).max() ?? 1

        return GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(entries) { entry in
                    VStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(
                                width: max(4, (geometry.size.width - CGFloat(entries.count * 2)) / CGFloat(entries.count)),
                                height: CGFloat(entry.wordsWritten) / CGFloat(maxWords) * geometry.size.height * 0.8
                            )
                            .cornerRadius(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var filteredEntries: [WritingHistoryEntry] {
        guard let days = selectedTimeRange.days else {
            return writingHistory.entries
        }

        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: days * periodOffset, to: Date()) ?? Date()
        let startDate = calendar.date(byAdding: .day, value: -days + 1, to: endDate) ?? Date()

        return writingHistory.entries.filter { entry in
            entry.date >= calendar.startOfDay(for: startDate) &&
            entry.date <= calendar.startOfDay(for: endDate).addingTimeInterval(86400)
        }
    }

    // MARK: - Entries List Section

    private var entriesListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Log")
                .font(.headline)
                .foregroundColor(.secondary)

            if writingHistory.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(writingHistory.entries.reversed()) { entry in
                        WritingHistoryEntryRow(entry: entry)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Writing History")
                .font(.headline)

            Text("Your daily writing progress will appear here as you write.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(PlatformColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// StatCard, WritingHistoryEntryRow, and CompactWritingHistoryView are defined in:
// - WritingHistory/StatCard.swift
// - WritingHistory/WritingHistoryEntryRow.swift
// - WritingHistory/CompactWritingHistoryView.swift

// MARK: - Preview

#if DEBUG
struct WritingHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WritingHistoryView(writingHistory: sampleHistory)
        }
    }

    static var sampleHistory: WritingHistory {
        var entries: [WritingHistoryEntry] = []
        let calendar = Calendar.current

        // Generate sample data for the last 30 days
        for i in 0..<30 {
            if Bool.random() || i < 7 { // More recent days are more likely to have data
                let date = calendar.date(byAdding: .day, value: -i, to: Date())!
                let words = Int.random(in: 200...3000)
                entries.append(WritingHistoryEntry(
                    date: date,
                    wordsWritten: words,
                    draftWordCount: 50000 + words * (30 - i)
                ))
            }
        }

        return WritingHistory(entries: entries)
    }
}
#endif
