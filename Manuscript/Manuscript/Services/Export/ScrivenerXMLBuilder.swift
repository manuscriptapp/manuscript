import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#endif

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
        let modifiedDate = formatScrivenerDate(Date())

        #if os(macOS)
        let deviceName = Host.current().localizedName ?? "Mac"
        #else
        let deviceName = UIDevice.current.name
        #endif

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ScrivenerProject Identifier="\(UUID().uuidString)" Version="2.0" Creator="Manuscript-1.0" Device="\(escapeXML(deviceName))" Modified="\(modifiedDate)" ModID="\(UUID().uuidString)">
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

        // Add sections in CORRECT order as per Scrivener 3 format:
        xml += buildCollections()
        xml += buildKeywords()
        xml += buildSectionTypes()
        xml += buildLabelSettings()
        xml += buildStatusSettings()
        xml += buildProjectTargets()
        xml += buildRecentWritingHistory()
        xml += buildPrintSettings()

        xml += "</ScrivenerProject>\n"

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

        // Special folder types (DraftFolder, ResearchFolder, TrashFolder) don't have TextSettings
        let isSpecialFolder = type == "DraftFolder" || type == "ResearchFolder" || type == "TrashFolder"

        var xml = """
        \(indentation)<BinderItem UUID="\(scrivUUID)" Type="\(type)" Created="\(formatScrivenerDate(folder.creationDate))" Modified="\(formatScrivenerDate(Date()))">
        \(indentation)    <Title>\(escapeXML(folder.title))</Title>
        \(indentation)    <MetaData>
        \(indentation)        <IncludeInCompile>Yes</IncludeInCompile>
        \(indentation)    </MetaData>

        """

        // Only add TextSettings for regular folders, not special folders
        if !isSpecialFolder {
            xml += """
        \(indentation)    <TextSettings>
        \(indentation)        <TextSelection>0,0</TextSelection>
        \(indentation)    </TextSettings>

        """
        }

        // Collect children (documents and subfolders)
        let sortedDocs = folder.documents.sorted(by: { $0.order < $1.order })
        let sortedSubfolders = folder.subfolders.sorted(by: { $0.order < $1.order })

        // Only add Children wrapper if there are children
        if !sortedDocs.isEmpty || !sortedSubfolders.isEmpty {
            xml += "\(indentation)    <Children>\n"

            // Add documents as Text items
            for doc in sortedDocs {
                xml += buildDocumentBinderItem(document: doc, indent: indent + 2)
            }

            // Add subfolders
            for subfolder in sortedSubfolders {
                xml += buildBinderItem(folder: subfolder, type: "Folder", indent: indent + 2)
            }

            xml += "\(indentation)    </Children>\n"
        }

        xml += "\(indentation)</BinderItem>\n"

        return xml
    }

    private func buildDocumentBinderItem(document doc: ManuscriptDocument.Document, indent: Int) -> String {
        let indentation = String(repeating: "    ", count: indent)
        let scrivUUID = uuidMapping[doc.id] ?? UUID().uuidString

        var xml = """
        \(indentation)<BinderItem UUID="\(scrivUUID)" Type="Text" Created="\(formatScrivenerDate(doc.creationDate))" Modified="\(formatScrivenerDate(Date()))">
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

        // Add TextSettings (required by Scrivener)
        xml += "\(indentation)    <TextSettings>\n"
        xml += "\(indentation)        <TextSelection>0,0</TextSelection>\n"
        xml += "\(indentation)    </TextSettings>\n"

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
        xml += "        <Title>Label</Title>\n"
        xml += "        <DefaultLabelID>-1</DefaultLabelID>\n"
        xml += "        <Labels>\n"

        // Add "No Label" as ID -1
        xml += "            <Label ID=\"-1\">No Label</Label>\n"

        for (index, label) in document.labels.enumerated() {
            let colorRGB = hexToScrivenerColor(label.color)
            xml += "            <Label ID=\"\(index)\" Color=\"\(colorRGB)\">\(escapeXML(label.name))</Label>\n"
        }

        xml += "        </Labels>\n"
        xml += "    </LabelSettings>\n"
        return xml
    }

    private func buildStatusSettings() -> String {
        var xml = "    <StatusSettings>\n"
        xml += "        <Title>Status</Title>\n"
        xml += "        <DefaultStatusID>-1</DefaultStatusID>\n"
        xml += "        <StatusItems>\n"

        // Add "No Status" as ID -1
        xml += "            <Status ID=\"-1\">No Status</Status>\n"

        for (index, status) in document.statuses.enumerated() {
            xml += "            <Status ID=\"\(index)\">\(escapeXML(status.name))</Status>\n"
        }

        xml += "        </StatusItems>\n"
        xml += "    </StatusSettings>\n"
        return xml
    }

    private func buildKeywords() -> String {
        // Collect all unique keywords from documents
        var allKeywords = Set<String>()
        collectKeywords(from: document.rootFolder, into: &allKeywords)
        if let research = document.researchFolder {
            collectKeywords(from: research, into: &allKeywords)
        }

        guard !allKeywords.isEmpty else { return "" }

        // Generate consistent colors for keywords based on hash
        let keywordColors = [
            "0.993495 0.701227 0.732594",  // Red
            "0.995418 0.790968 0.65239",   // Orange
            "0.99772 0.892753 0.652574",   // Yellow
            "0.715848 0.948734 0.697698",  // Green
            "0.702312 0.888297 0.97426",   // Blue
            "0.957564 0.766768 0.999625",  // Purple
            "0.943039 0.654989 0.986895",  // Pink
            "0.584909 0.947715 0.802964"   // Teal
        ]

        var xml = "    <Keywords>\n"

        for (index, keyword) in allKeywords.sorted().enumerated() {
            let color = keywordColors[index % keywordColors.count]
            xml += "        <Keyword ID=\"\(index)\">\n"
            xml += "            <Title>\(escapeXML(keyword))</Title>\n"
            xml += "            <Color>\(color)</Color>\n"
            xml += "        </Keyword>\n"
        }

        xml += "    </Keywords>\n"
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        var xml = "    <ProjectTargets Notify=\"No\">\n"

        // Draft target
        let draftTarget = targets.draftWordCount ?? 0
        var draftAttrs = "Type=\"Words\" CountIncludedOnly=\"Yes\" CurrentCompileGroupOnly=\"No\""
        if let deadline = targets.draftDeadline {
            draftAttrs += " Deadline=\"\(dateFormatter.string(from: deadline))\""
        } else {
            draftAttrs += " Deadline=\"\(dateFormatter.string(from: Date()))\""
        }
        draftAttrs += " IgnoreDeadline=\"\(targets.draftDeadlineIgnored ? "Yes" : "No")\""
        xml += "        <DraftTarget \(draftAttrs)>\(draftTarget)</DraftTarget>\n"

        // Session target
        let sessionTarget = targets.sessionWordCount ?? 0
        var sessionAttrs = "Type=\"Words\" CountDraftOnly=\"Yes\""
        sessionAttrs += " AllowNegatives=\"\(targets.sessionAllowNegatives ? "Yes" : "No")\""

        // Calculate next reset date (tomorrow at reset time)
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let resetDateString = dateFormatter.string(from: tomorrow)
        sessionAttrs += " NextResetDate=\"\(resetDateString)\""

        let resetType = targets.sessionResetType
        sessionAttrs += " ResetType=\"\(resetType == .time ? "Time" : "Midnight")\""
        sessionAttrs += " ResetTime=\"\(targets.sessionResetTime ?? "00:00")\""
        sessionAttrs += " DeterminedFromDeadline=\"No\" WritingDays=\"\" CanWriteOnDeadlineDate=\"No\""
        xml += "        <SessionTarget \(sessionAttrs)>\(sessionTarget)</SessionTarget>\n"

        // Previous session (required)
        let previousSessionDate = dateFormatter.string(from: Date())
        xml += "        <PreviousSession Words=\"0\" Characters=\"0\" Date=\"\(previousSessionDate)\"/>\n"

        xml += "    </ProjectTargets>\n"
        return xml
    }

    private func buildCollections() -> String {
        let collectionId = UUID().uuidString
        return """
            <Collections>
                <Collection Type="Binder" ID="\(collectionId)" Color="1.0 1.0 1.0">
                    <Title>Binder</Title>
                </Collection>
            </Collections>

        """
    }

    private func buildSectionTypes() -> String {
        let headingId = UUID().uuidString
        let subHeadingId = UUID().uuidString
        let sectionId = UUID().uuidString
        return """
            <SectionTypes>
                <TypeDefinitions>
                    <Type ID="\(headingId)">Heading</Type>
                    <Type ID="\(subHeadingId)">Sub-Heading</Type>
                    <Type ID="\(sectionId)">Section</Type>
                </TypeDefinitions>
                <LevelTypes>
                    <Folders>
                        <Type>\(headingId)</Type>
                    </Folders>
                    <Containers>
                        <Type>\(sectionId)</Type>
                    </Containers>
                    <Files>
                        <Type>\(sectionId)</Type>
                    </Files>
                </LevelTypes>
            </SectionTypes>

        """
    }

    private func buildRecentWritingHistory() -> String {
        let dateString = formatScrivenerDate(Date())
        return """
            <RecentWritingHistory Date="\(dateString)">
                <DraftWordCount>0</DraftWordCount>
                <DraftCharCount>0</DraftCharCount>
                <OtherWordCount>0</OtherWordCount>
                <OtherCharCount>0</OtherCharCount>
            </RecentWritingHistory>

        """
    }

    private func buildPrintSettings() -> String {
        """
            <PrintSettings PaperSize="612.0,792.0" LeftMargin="72.0" RightMargin="72.0" TopMargin="90.0" BottomMargin="90.0" PaperType="na-letter" Orientation="Portrait" HorizontalPagination="Clip" VerticalPagination="Auto" ScaleFactor="1.0" HorizontallyCentered="Yes" VerticallyCentered="Yes" Collates="Yes" PagesAcross="1" PagesDown="1"/>

        """
    }

    // MARK: - Helpers

    /// Formats a date in Scrivener's expected format: "2025-04-12 17:00:59 +0200"
    private func formatScrivenerDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

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
