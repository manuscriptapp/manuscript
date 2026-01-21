import Foundation

// MARK: - Writing History Entry

/// Represents a single day's writing statistics
struct WritingHistoryEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var wordsWritten: Int          // Words written that day (session count)
    var draftWordCount: Int?       // Total draft word count at end of day
    var sessionDuration: TimeInterval?  // Time spent writing (if tracked)

    init(
        id: UUID = UUID(),
        date: Date,
        wordsWritten: Int,
        draftWordCount: Int? = nil,
        sessionDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.date = date
        self.wordsWritten = wordsWritten
        self.draftWordCount = draftWordCount
        self.sessionDuration = sessionDuration
    }

    /// The date formatted for display (e.g., "Jan 15, 2025")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// The date as a short string (e.g., "Jan 15")
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// The day of week (e.g., "Mon")
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Writing History

/// Container for writing history with computed statistics
struct WritingHistory: Codable, Equatable {
    var entries: [WritingHistoryEntry]

    init(entries: [WritingHistoryEntry] = []) {
        self.entries = entries.sorted { $0.date < $1.date }
    }

    // MARK: - Statistics

    /// Total words written across all days
    var totalWordsWritten: Int {
        entries.reduce(0) { $0 + $1.wordsWritten }
    }

    /// Number of days with writing activity
    var daysWritten: Int {
        entries.count
    }

    /// Average words per writing day
    var averageWordsPerDay: Int {
        guard !entries.isEmpty else { return 0 }
        return totalWordsWritten / entries.count
    }

    /// Best single-day word count
    var bestDay: WritingHistoryEntry? {
        entries.max { $0.wordsWritten < $1.wordsWritten }
    }

    /// Current writing streak (consecutive days)
    var currentStreak: Int {
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sortedEntries = entries.sorted { $0.date > $1.date }

        var streak = 0
        var expectedDate = today

        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.date)

            // Check if this entry matches the expected date or the day before
            if entryDate == expectedDate || calendar.isDate(entryDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: expectedDate)!) {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: entryDate)!
            } else if entryDate < expectedDate {
                // Gap in writing, streak ends
                break
            }
        }

        return streak
    }

    /// Longest writing streak ever
    var longestStreak: Int {
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date < $1.date }

        var maxStreak = 1
        var currentStreak = 1
        var previousDate = calendar.startOfDay(for: sortedEntries[0].date)

        for entry in sortedEntries.dropFirst() {
            let entryDate = calendar.startOfDay(for: entry.date)
            let daysDiff = calendar.dateComponents([.day], from: previousDate, to: entryDate).day ?? 0

            if daysDiff == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if daysDiff > 1 {
                currentStreak = 1
            }
            // daysDiff == 0 means same day, skip

            previousDate = entryDate
        }

        return maxStreak
    }

    /// Words written in the last 7 days
    var wordsLast7Days: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return entries.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.wordsWritten }
    }

    /// Words written in the last 30 days
    var wordsLast30Days: Int {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        return entries.filter { $0.date >= monthAgo }.reduce(0) { $0 + $1.wordsWritten }
    }

    /// Entries for the last N days (for charts)
    func entriesForLastDays(_ days: Int) -> [WritingHistoryEntry] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date())!
        return entries.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    /// Get entry for a specific date
    func entry(for date: Date) -> WritingHistoryEntry? {
        let calendar = Calendar.current
        return entries.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    /// Group entries by week
    var entriesByWeek: [[WritingHistoryEntry]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry -> Date in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)
            return calendar.date(from: components) ?? entry.date
        }
        return grouped.keys.sorted().map { grouped[$0]! }
    }

    /// Group entries by month
    var entriesByMonth: [(month: String, entries: [WritingHistoryEntry])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: entries) { entry -> String in
            formatter.string(from: entry.date)
        }

        // Sort by date (using first entry of each group)
        return grouped.map { (month: $0.key, entries: $0.value.sorted { $0.date < $1.date }) }
            .sorted { ($0.entries.first?.date ?? Date()) < ($1.entries.first?.date ?? Date()) }
    }

    // MARK: - Mutations

    /// Add or update an entry for today
    mutating func recordWords(_ count: Int, draftTotal: Int? = nil) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let index = entries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            // Update existing entry
            entries[index].wordsWritten += count
            if let total = draftTotal {
                entries[index].draftWordCount = total
            }
        } else {
            // Create new entry
            let entry = WritingHistoryEntry(
                date: today,
                wordsWritten: count,
                draftWordCount: draftTotal
            )
            entries.append(entry)
            entries.sort { $0.date < $1.date }
        }
    }

    /// Check if history is empty
    var isEmpty: Bool {
        entries.isEmpty
    }
}

// MARK: - Scrivener Writing History Parser

/// Parser for Scrivener's writing.history XML file
final class ScrivenerWritingHistoryParser: NSObject {

    private var entries: [WritingHistoryEntry] = []
    private var currentElement = ""
    private var parseError: Error?

    /// Parse writing.history XML data
    func parse(data: Data) throws -> WritingHistory {
        entries = []
        parseError = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false

        guard parser.parse() else {
            if let error = parseError {
                throw error
            }
            throw ImportError.xmlParsingFailed(parser.parserError?.localizedDescription ?? "Unknown error")
        }

        return WritingHistory(entries: entries)
    }

    /// Parse writing.history from a file URL
    func parse(url: URL) throws -> WritingHistory {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }
}

// MARK: - XMLParserDelegate

extension ScrivenerWritingHistoryParser: XMLParserDelegate {

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName

        if elementName == "Day" {
            // Parse day entry attributes
            // Format: <Day Date="2025-01-15" WordCount="1500" DraftWordCount="50000"/>

            guard let dateStr = attributeDict["Date"] else { return }

            // Parse date (YYYY-MM-DD format)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            guard let date = dateFormatter.date(from: dateStr) else { return }

            // Parse word count (session words written)
            let wordsWritten = Int(attributeDict["WordCount"] ?? attributeDict["Words"] ?? "0") ?? 0

            // Parse draft word count (total at end of day)
            let draftWordCount = Int(attributeDict["DraftWordCount"] ?? attributeDict["TotalWords"] ?? "")

            // Parse session duration if available
            let sessionDuration: TimeInterval?
            if let durationStr = attributeDict["Duration"] ?? attributeDict["SessionDuration"],
               let duration = Double(durationStr) {
                sessionDuration = duration
            } else {
                sessionDuration = nil
            }

            let entry = WritingHistoryEntry(
                date: date,
                wordsWritten: wordsWritten,
                draftWordCount: draftWordCount,
                sessionDuration: sessionDuration
            )
            entries.append(entry)
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
