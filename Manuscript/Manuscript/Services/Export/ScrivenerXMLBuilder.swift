import Foundation
import SwiftUI

/// Builds the .scrivx XML file for Scrivener 3 export
final class ScrivenerXMLBuilder {

    // MARK: - Properties

    private let document: ManuscriptDocument
    private let uuidMapping: [UUID: String]  // Maps Manuscript UUIDs to Scrivener UUIDs
    private let labelIdMapping: [String: Int]  // Maps Manuscript label IDs to Scrivener integer IDs
    private let statusIdMapping: [String: Int]  // Maps Manuscript status IDs to Scrivener integer IDs
    private let keywordIdMapping: [String: Int]  // Maps keyword names to Scrivener integer IDs

    // MARK: - Initialization

    init(
        document: ManuscriptDocument,
        uuidMapping: [UUID: String],
        labelIdMapping: [String: Int],
        statusIdMapping: [String: Int],
        keywordIdMapping: [String: Int]
    ) {
        self.document = document
        self.uuidMapping = uuidMapping
        self.labelIdMapping = labelIdMapping
        self.statusIdMapping = statusIdMapping
        self.keywordIdMapping = keywordIdMapping
    }

    // MARK: - Public Methods

    /// Builds the complete .scrivx XML content
    func build() -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ScrivenerProject Identifier="\(UUID().uuidString)" Version="2.0">
            <Binder>

        """

        // Add Draft folder
        xml += buildBinderItem(
            folder: document.rootFolder,
            type: "DraftFolder",
            indent: 2
        )

        // Add Research folder if it has content
        if let researchFolder = document.researchFolder, !researchFolder.isEmpty {
            xml += buildBinderItem(
                folder: researchFolder,
                type: "ResearchFolder",
                indent: 2
            )
        }

        // Add Trash folder if it has content
        if let trashFolder = document.trashFolder, !trashFolder.isEmpty {
            xml += buildBinderItem(
                folder: trashFolder,
                type: "TrashFolder",
                indent: 2
            )
        }

        xml += """
            </Binder>

        """

        // Add Label Settings
        xml += buildLabelSettings()

        // Add Status Settings
        xml += buildStatusSettings()

        // Add Keyword Settings
        xml += buildKeywordSettings()

        // Add Project Targets
        xml += buildProjectTargets()

        // Add Project Title
        xml += """
            <ProjectTitle>\(escapeXML(document.title))</ProjectTitle>
        </ScrivenerProject>
        """

        return xml
    }

    // MARK: - Binder Item Building

    private func buildBinderItem(
        folder: ManuscriptFolder,
        type: String,
        indent: Int
    ) -> String {
        let indentation = String(repeating: "    ", count: indent)
        let scrivUUID = uuidMapping[folder.id] ?? UUID().uuidString
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTimeZone]

        var xml = """
        \(indentation)<BinderItem UUID="\(scrivUUID)" Type="\(type)" Created="\(dateFormatter.string(from: folder.creationDate))" Modified="\(dateFormatter.string(from: Date()))">
        \(indentation)    <Title>\(escapeXML(folder.title))</Title>
        \(indentation)    <MetaData>
        \(indentation)        <IncludeInCompile>Yes</IncludeInCompile>
        \(indentation)    </MetaData>

        """

        // Add documents as Text items
        for doc in folder.documents.sorted(by: { $0.order < $1.order }) {
            xml += buildDocumentBinderItem(document: doc, indent: indent + 1)
        }

        // Add subfolders
        for subfolder in folder.subfolders.sorted(by: { $0.order < $1.order }) {
            xml += buildBinderItem(folder: subfolder, type: "Folder", indent: indent + 1)
        }

        xml += "\(indentation)</BinderItem>\n"

        return xml
    }

    private func buildDocumentBinderItem(document doc: ManuscriptDocument.Document, indent: Int) -> String {
        let indentation = String(repeating: "    ", count: indent)
        let scrivUUID = uuidMapping[doc.id] ?? UUID().uuidString
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTimeZone]

        var xml = """
        \(indentation)<BinderItem UUID="\(scrivUUID)" Type="Text" Created="\(dateFormatter.string(from: doc.creationDate))" Modified="\(dateFormatter.string(from: Date()))">
        \(indentation)    <Title>\(escapeXML(doc.title))</Title>
        \(indentation)    <MetaData>
        \(indentation)        <IncludeInCompile>\(doc.includeInCompile ? "Yes" : "No")</IncludeInCompile>

        """

        // Add label ID
        if let labelId = doc.labelId, let scrivLabelId = labelIdMapping[labelId] {
            xml += "\(indentation)        <LabelID>\(scrivLabelId)</LabelID>\n"
        }

        // Add status ID
        if let statusId = doc.statusId, let scrivStatusId = statusIdMapping[statusId] {
            xml += "\(indentation)        <StatusID>\(scrivStatusId)</StatusID>\n"
        }

        // Add keywords
        if !doc.keywords.isEmpty {
            xml += "\(indentation)        <Keywords>\n"
            for keyword in doc.keywords {
                if let keywordId = keywordIdMapping[keyword] {
                    xml += "\(indentation)            <KeywordID>\(keywordId)</KeywordID>\n"
                }
            }
            xml += "\(indentation)        </Keywords>\n"
        }

        xml += "\(indentation)    </MetaData>\n"

        // Add synopsis if present
        if !doc.synopsis.isEmpty {
            xml += "\(indentation)    <Synopsis>\(escapeXML(doc.synopsis))</Synopsis>\n"
        }

        xml += "\(indentation)</BinderItem>\n"

        return xml
    }

    // MARK: - Settings Building

    private func buildLabelSettings() -> String {
        var xml = "    <LabelSettings>\n"

        // Add "No Label" as ID -1
        xml += "        <Label ID=\"-1\">No Label</Label>\n"

        for (index, label) in document.labels.enumerated() {
            let colorRGB = hexToScrivenerColor(label.color)
            xml += "        <Label ID=\"\(index)\" Color=\"\(colorRGB)\">\(escapeXML(label.name))</Label>\n"
        }

        xml += "    </LabelSettings>\n"
        return xml
    }

    private func buildStatusSettings() -> String {
        var xml = "    <StatusSettings>\n"

        // Add "No Status" as ID -1
        xml += "        <Status ID=\"-1\">No Status</Status>\n"

        for (index, status) in document.statuses.enumerated() {
            xml += "        <Status ID=\"\(index)\">\(escapeXML(status.name))</Status>\n"
        }

        xml += "    </StatusSettings>\n"
        return xml
    }

    private func buildKeywordSettings() -> String {
        // Collect all unique keywords from documents
        var allKeywords = Set<String>()
        collectKeywords(from: document.rootFolder, into: &allKeywords)
        if let research = document.researchFolder {
            collectKeywords(from: research, into: &allKeywords)
        }

        guard !allKeywords.isEmpty else { return "" }

        var xml = "    <KeywordSettings>\n"

        for (index, keyword) in allKeywords.sorted().enumerated() {
            xml += "        <Keyword ID=\"\(index)\">\(escapeXML(keyword))</Keyword>\n"
        }

        xml += "    </KeywordSettings>\n"
        return xml
    }

    private func collectKeywords(from folder: ManuscriptFolder, into set: inout Set<String>) {
        for doc in folder.documents {
            for keyword in doc.keywords {
                set.insert(keyword)
            }
        }
        for subfolder in folder.subfolders {
            collectKeywords(from: subfolder, into: &set)
        }
    }

    private func buildProjectTargets() -> String {
        let targets = document.targets

        var xml = "    <ProjectTargets>\n"

        // Draft target
        if let draftTarget = targets.draftWordCount {
            var draftAttrs = ""
            if let deadline = targets.draftDeadline {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                draftAttrs += " Deadline=\"\(dateFormatter.string(from: deadline))\""
            }
            if targets.draftDeadlineIgnored {
                draftAttrs += " IgnoreDeadline=\"Yes\""
            }
            if targets.draftCountIncludedOnly {
                draftAttrs += " CountIncludedOnly=\"Yes\""
            }
            xml += "        <DraftTarget\(draftAttrs)>\(draftTarget)</DraftTarget>\n"
        }

        // Session target
        if let sessionTarget = targets.sessionWordCount {
            var sessionAttrs = ""
            let resetType = targets.sessionResetType
            sessionAttrs += " ResetType=\"\(resetType == .time ? "Time" : "Midnight")\""
            if let resetTime = targets.sessionResetTime {
                sessionAttrs += " ResetTime=\"\(resetTime)\""
            }
            if targets.sessionAllowNegatives {
                sessionAttrs += " AllowNegatives=\"Yes\""
            }
            xml += "        <SessionTarget\(sessionAttrs)>\(sessionTarget)</SessionTarget>\n"
        }

        xml += "    </ProjectTargets>\n"
        return xml
    }

    // MARK: - Helpers

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    /// Converts a hex color string to Scrivener's RGB float format
    /// e.g., "#4A90D9" -> "0.290196 0.564706 0.850980"
    private func hexToScrivenerColor(_ hex: String) -> String {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString = String(hexString.dropFirst())
        }

        guard hexString.count == 6,
              let hexValue = UInt32(hexString, radix: 16) else {
            return "0.5 0.5 0.5"  // Default gray
        }

        let r = Double((hexValue >> 16) & 0xFF) / 255.0
        let g = Double((hexValue >> 8) & 0xFF) / 255.0
        let b = Double(hexValue & 0xFF) / 255.0

        return String(format: "%.6f %.6f %.6f", r, g, b)
    }
}

// MARK: - UUID Mapping Builder

extension ScrivenerXMLBuilder {
    /// Builds UUID mappings for all items in a document
    static func buildUUIDMapping(for document: ManuscriptDocument) -> [UUID: String] {
        var mapping: [UUID: String] = [:]

        func mapFolder(_ folder: ManuscriptFolder) {
            mapping[folder.id] = UUID().uuidString
            for doc in folder.documents {
                mapping[doc.id] = UUID().uuidString
            }
            for subfolder in folder.subfolders {
                mapFolder(subfolder)
            }
        }

        mapFolder(document.rootFolder)
        if let research = document.researchFolder {
            mapFolder(research)
        }
        if let trash = document.trashFolder {
            mapFolder(trash)
        }

        return mapping
    }

    /// Builds label ID mapping (Manuscript string ID -> Scrivener integer ID)
    static func buildLabelIdMapping(for document: ManuscriptDocument) -> [String: Int] {
        var mapping: [String: Int] = [:]
        for (index, label) in document.labels.enumerated() {
            mapping[label.id] = index
        }
        return mapping
    }

    /// Builds status ID mapping (Manuscript string ID -> Scrivener integer ID)
    static func buildStatusIdMapping(for document: ManuscriptDocument) -> [String: Int] {
        var mapping: [String: Int] = [:]
        for (index, status) in document.statuses.enumerated() {
            mapping[status.id] = index
        }
        return mapping
    }

    /// Builds keyword ID mapping (keyword name -> Scrivener integer ID)
    static func buildKeywordIdMapping(for document: ManuscriptDocument) -> [String: Int] {
        var allKeywords = Set<String>()

        func collectKeywords(from folder: ManuscriptFolder) {
            for doc in folder.documents {
                for keyword in doc.keywords {
                    allKeywords.insert(keyword)
                }
            }
            for subfolder in folder.subfolders {
                collectKeywords(from: subfolder)
            }
        }

        collectKeywords(from: document.rootFolder)
        if let research = document.researchFolder {
            collectKeywords(from: research)
        }

        var mapping: [String: Int] = [:]
        for (index, keyword) in allKeywords.sorted().enumerated() {
            mapping[keyword] = index
        }
        return mapping
    }
}
