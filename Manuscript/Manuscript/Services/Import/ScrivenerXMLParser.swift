import Foundation
import SwiftUI

/// Parses Scrivener project.scrivx XML files
final class ScrivenerXMLParser: NSObject {

    // MARK: - Properties

    private var projectTitle = ""
    private var binderItems: [ScrivenerBinderItem] = []
    private var labels: [ScrivenerLabel] = []
    private var statuses: [ScrivenerStatus] = []
    private var keywords: [ScrivenerKeyword] = []
    private var draftTarget: Int?
    private var sessionTarget: Int?

    // Draft target attributes
    private var draftDeadline: Date?
    private var draftDeadlineIgnored: Bool = false
    private var draftCountIncludedOnly: Bool = true

    // Session target attributes
    private var sessionResetType: String?
    private var sessionResetTime: String?
    private var sessionAllowNegatives: Bool = false

    // Parsing state
    private var currentElement = ""
    private var currentText = ""

    // Binder item parsing state
    private var itemStack: [PartialBinderItem] = []
    private var childrenStack: [[ScrivenerBinderItem]] = [[]]

    // Label/Status parsing state
    private var currentLabelID: Int?
    private var currentLabelColor: String?
    private var currentStatusID: Int?

    // Keyword parsing state
    private var currentKeywordID: Int?
    private var currentKeywordColor: String?
    private var currentItemKeywordIDs: [Int] = []
    private var inItemKeywords = false

    // Context tracking
    private var inBinder = false
    private var inLabelSettings = false
    private var inStatusSettings = false
    private var inKeywordSettings = false
    private var inProjectTargets = false

    // MARK: - Partial Item for Building

    private struct PartialBinderItem {
        var id: String = ""
        var uuid: String?
        var type: String = ""
        var title: String = ""
        var created: Date?
        var modified: Date?
        var synopsis: String?
        var labelID: Int?
        var statusID: Int?
        var includeInCompile: Bool = true
        var targetWordCount: Int?
        var iconFileName: String?
        var keywordIDs: [Int] = []
    }

    // MARK: - Public Methods

    /// Parse a Scrivener project.scrivx file
    /// - Parameter projectURL: URL to the project.scrivx file
    /// - Returns: Parsed ScrivenerProject
    func parse(projectURL: URL) throws -> ScrivenerProject {
        // Reset state
        resetState()

        guard let parser = XMLParser(contentsOf: projectURL) else {
            throw ImportError.xmlParsingFailed("Could not create XML parser for \(projectURL.lastPathComponent)")
        }

        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false

        guard parser.parse() else {
            let errorMsg = parser.parserError?.localizedDescription ?? "Unknown parsing error"
            throw ImportError.xmlParsingFailed(errorMsg)
        }

        // Get the final binder items from the root children stack
        let rootItems = childrenStack.first ?? []

        return ScrivenerProject(
            title: projectTitle.isEmpty ? "Untitled Project" : projectTitle,
            version: .v3,  // Version is determined by file structure, not XML
            binderItems: rootItems,
            labels: labels,
            statuses: statuses,
            keywords: keywords,
            targets: ScrivenerTargets(
                draftWordCount: draftTarget,
                sessionWordCount: sessionTarget,
                deadline: draftDeadline,
                deadlineIgnored: draftDeadlineIgnored,
                draftCountIncludedOnly: draftCountIncludedOnly,
                sessionResetType: sessionResetType,
                sessionResetTime: sessionResetTime,
                sessionAllowNegatives: sessionAllowNegatives
            ),
            customMetadata: []
        )
    }

    // MARK: - Private Methods

    private func resetState() {
        projectTitle = ""
        binderItems = []
        labels = []
        statuses = []
        keywords = []
        draftTarget = nil
        sessionTarget = nil
        draftDeadline = nil
        draftDeadlineIgnored = false
        draftCountIncludedOnly = true
        sessionResetType = nil
        sessionResetTime = nil
        sessionAllowNegatives = false
        currentElement = ""
        currentText = ""
        itemStack = []
        childrenStack = [[]]
        currentLabelID = nil
        currentLabelColor = nil
        currentStatusID = nil
        currentKeywordID = nil
        currentKeywordColor = nil
        currentItemKeywordIDs = []
        inItemKeywords = false
        inBinder = false
        inLabelSettings = false
        inStatusSettings = false
        inKeywordSettings = false
        inProjectTargets = false
    }

    private func parseDate(_ string: String?) -> Date? {
        guard let string = string, !string.isEmpty else { return nil }

        // Try ISO8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        if let date = iso8601Formatter.date(from: string) {
            return date
        }

        // Try date-only format
        iso8601Formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if let date = iso8601Formatter.date(from: string) {
            return date
        }

        // Try common date formats
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let formats = [
            "yyyy-MM-dd HH:mm:ss Z",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd"
        ]

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: string) {
                return date
            }
        }

        return nil
    }

    private func parseColor(_ colorString: String) -> Color {
        // Scrivener uses "R G B" format with 0-1 floats
        let components = colorString.split(separator: " ").compactMap { Double($0) }
        guard components.count >= 3 else { return .gray }

        return Color(
            red: components[0],
            green: components[1],
            blue: components[2]
        )
    }
}

// MARK: - XMLParserDelegate

extension ScrivenerXMLParser: XMLParserDelegate {

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "Binder":
            inBinder = true

        case "LabelSettings":
            inLabelSettings = true

        case "StatusSettings":
            inStatusSettings = true

        case "ProjectTargets":
            inProjectTargets = true

        case "DraftTarget":
            if inProjectTargets {
                // Parse DraftTarget attributes
                // Deadline="2025-04-12 17:00:59 +0200"
                if let deadlineStr = attributeDict["Deadline"] {
                    draftDeadline = parseDate(deadlineStr)
                }
                // IgnoreDeadline="Yes"
                let ignoreDeadline = attributeDict["IgnoreDeadline"]?.lowercased()
                draftDeadlineIgnored = (ignoreDeadline == "yes" || ignoreDeadline == "true")
                // CountIncludedOnly="Yes"
                let countIncluded = attributeDict["CountIncludedOnly"]?.lowercased()
                draftCountIncludedOnly = (countIncluded == "yes" || countIncluded == "true" || countIncluded == nil)
            }

        case "SessionTarget":
            if inProjectTargets {
                // Parse SessionTarget attributes
                // ResetType="Time"
                sessionResetType = attributeDict["ResetType"]
                // ResetTime="00:00"
                sessionResetTime = attributeDict["ResetTime"]
                // AllowNegatives="Yes"
                let allowNegatives = attributeDict["AllowNegatives"]?.lowercased()
                sessionAllowNegatives = (allowNegatives == "yes" || allowNegatives == "true")
            }

        case "BinderItem":
            // Start a new binder item
            var item = PartialBinderItem()
            item.id = attributeDict["ID"] ?? UUID().uuidString
            item.uuid = attributeDict["UUID"]
            item.type = attributeDict["Type"] ?? "Text"
            item.created = parseDate(attributeDict["Created"])
            item.modified = parseDate(attributeDict["Modified"])
            itemStack.append(item)
            childrenStack.append([])  // New children array for this item

        case "Label":
            if inLabelSettings {
                if let idStr = attributeDict["ID"], let id = Int(idStr) {
                    currentLabelID = id
                    currentLabelColor = attributeDict["Color"]
                }
            }

        case "Status":
            if inStatusSettings {
                if let idStr = attributeDict["ID"], let id = Int(idStr) {
                    currentStatusID = id
                }
            }

        case "KeywordSettings":
            inKeywordSettings = true

        case "Keyword":
            if inKeywordSettings {
                // Project-level keyword definition
                if let idStr = attributeDict["ID"], let id = Int(idStr) {
                    currentKeywordID = id
                    currentKeywordColor = attributeDict["Color"]
                }
            }

        case "Keywords":
            // Item-level keywords (within MetaData)
            if !itemStack.isEmpty {
                inItemKeywords = true
                currentItemKeywordIDs = []
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "Binder":
            inBinder = false

        case "LabelSettings":
            inLabelSettings = false

        case "StatusSettings":
            inStatusSettings = false

        case "ProjectTargets":
            inProjectTargets = false

        case "ProjectTitle":
            projectTitle = trimmedText

        case "Title":
            if !itemStack.isEmpty {
                itemStack[itemStack.count - 1].title = trimmedText
            }

        case "Synopsis":
            if !itemStack.isEmpty {
                itemStack[itemStack.count - 1].synopsis = trimmedText
            }

        case "LabelID":
            if !itemStack.isEmpty, let labelID = Int(trimmedText) {
                itemStack[itemStack.count - 1].labelID = labelID
            }

        case "StatusID":
            if !itemStack.isEmpty, let statusID = Int(trimmedText) {
                itemStack[itemStack.count - 1].statusID = statusID
            }

        case "IncludeInCompile":
            if !itemStack.isEmpty {
                let include = trimmedText.lowercased()
                itemStack[itemStack.count - 1].includeInCompile = (include == "yes" || include == "true")
            }

        case "DraftTarget":
            if inProjectTargets {
                draftTarget = Int(trimmedText)
            }

        case "SessionTarget":
            if inProjectTargets {
                sessionTarget = Int(trimmedText)
            }

        case "Target":
            if !itemStack.isEmpty, let target = Int(trimmedText) {
                itemStack[itemStack.count - 1].targetWordCount = target
            }

        case "IconFileName":
            if !itemStack.isEmpty && !trimmedText.isEmpty {
                itemStack[itemStack.count - 1].iconFileName = trimmedText
            }

        case "BinderItem":
            // Complete the current binder item
            if let partialItem = itemStack.popLast() {
                let children = childrenStack.popLast() ?? []

                let item = ScrivenerBinderItem(
                    id: partialItem.id,
                    uuid: partialItem.uuid,
                    type: ScrivenerItemType(rawValue: partialItem.type),
                    title: partialItem.title.isEmpty ? "Untitled" : partialItem.title,
                    created: partialItem.created,
                    modified: partialItem.modified,
                    synopsis: partialItem.synopsis,
                    labelID: partialItem.labelID,
                    statusID: partialItem.statusID,
                    includeInCompile: partialItem.includeInCompile,
                    children: children,
                    targetWordCount: partialItem.targetWordCount,
                    iconFileName: partialItem.iconFileName,
                    keywordIDs: partialItem.keywordIDs
                )

                // Add to parent's children or root
                if !childrenStack.isEmpty {
                    childrenStack[childrenStack.count - 1].append(item)
                } else {
                    binderItems.append(item)
                }
            }

        case "Label":
            if inLabelSettings, let id = currentLabelID {
                let color = parseColor(currentLabelColor ?? "0.5 0.5 0.5")
                labels.append(ScrivenerLabel(id: id, name: trimmedText, color: color))
                currentLabelID = nil
                currentLabelColor = nil
            }

        case "Status":
            if inStatusSettings, let id = currentStatusID {
                statuses.append(ScrivenerStatus(id: id, name: trimmedText))
                currentStatusID = nil
            }

        case "KeywordSettings":
            inKeywordSettings = false

        case "Keyword":
            if inKeywordSettings, let id = currentKeywordID {
                let color = currentKeywordColor.map { parseColor($0) }
                keywords.append(ScrivenerKeyword(id: id, name: trimmedText, color: color))
                currentKeywordID = nil
                currentKeywordColor = nil
            }

        case "Keywords":
            // End of item-level keywords
            if inItemKeywords && !itemStack.isEmpty {
                itemStack[itemStack.count - 1].keywordIDs = currentItemKeywordIDs
                inItemKeywords = false
                currentItemKeywordIDs = []
            }

        case "KeywordID":
            // Item-level keyword reference
            if inItemKeywords, let keywordID = Int(trimmedText) {
                currentItemKeywordIDs.append(keywordID)
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // Error is handled in parse() method
    }
}
