import Foundation
import UniformTypeIdentifiers

/// Main entry point for Scrivener project import
final class ScrivenerImporter {

    // MARK: - Properties

    private let xmlParser: ScrivenerXMLParser
    private let rtfConverter: RTFToMarkdownConverter
    private let fileManager: FileManager

    // Import state
    private var warnings: [ImportWarning] = []
    private var skippedItems = 0
    private var importedDocuments = 0
    private var importedFolders = 0

    // Mapping tables built during import
    private var labelMap: [Int: ManuscriptLabel] = [:]
    private var statusMap: [Int: ManuscriptStatus] = [:]

    // MARK: - Initialization

    init() {
        self.xmlParser = ScrivenerXMLParser()
        self.rtfConverter = RTFToMarkdownConverter()
        self.fileManager = FileManager.default
    }

    // MARK: - Public Methods

    /// Validate a Scrivener project without importing
    func validateProject(at url: URL) -> ScrivenerValidationResult {
        var warnings: [String] = []
        var errors: [String] = []

        guard fileManager.fileExists(atPath: url.path) else {
            return ScrivenerValidationResult(
                isValid: false,
                errors: ["File does not exist at \(url.path)"]
            )
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return ScrivenerValidationResult(
                isValid: false,
                errors: ["The selected file is not a Scrivener project bundle"]
            )
        }

        let scrivxPath = url.appendingPathComponent("project.scrivx")
        guard fileManager.fileExists(atPath: scrivxPath.path) else {
            return ScrivenerValidationResult(
                isValid: false,
                errors: ["Missing project.scrivx file - this may not be a valid Scrivener project"]
            )
        }

        let version = detectVersion(at: url)

        let hasV3Data = fileManager.fileExists(atPath: url.appendingPathComponent("Files/Data").path)
        let hasV2Docs = fileManager.fileExists(atPath: url.appendingPathComponent("Files/Docs").path)

        if !hasV3Data && !hasV2Docs {
            warnings.append("No content directory found - documents may be empty")
        }

        var projectTitle = ""
        var itemCount = 0

        do {
            let project = try xmlParser.parse(projectURL: scrivxPath)
            projectTitle = project.title
            itemCount = countBinderItems(project.binderItems)

            if itemCount > 500 {
                warnings.append("Large project (\(itemCount) items) - import may take a while")
            }

            if hasMediaContent(project.binderItems) {
                warnings.append("Some media files (images, PDFs) will be referenced but not embedded")
            }
        } catch {
            errors.append("Could not parse project file: \(error.localizedDescription)")
        }

        return ScrivenerValidationResult(
            isValid: errors.isEmpty,
            projectTitle: projectTitle,
            itemCount: itemCount,
            version: version,
            warnings: warnings,
            errors: errors
        )
    }

    /// Import a Scrivener project from URL
    func importProject(
        from url: URL,
        options: ScrivenerImportOptions = .default,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> ImportResult {
        // Reset state
        warnings = []
        skippedItems = 0
        importedDocuments = 0
        importedFolders = 0
        labelMap = [:]
        statusMap = [:]

        // 1. Validate
        progress?(0.05, "Validating Scrivener project...")
        try validateBundle(at: url)

        // 2. Parse
        progress?(0.10, "Reading project structure...")
        let scrivxURL = url.appendingPathComponent("project.scrivx")
        let scrivProject = try xmlParser.parse(projectURL: scrivxURL)

        // 3. Detect version
        let version = detectVersion(at: url)
        let contentPath = version == .v3 ? "Files/Data" : "Files/Docs"

        // 4. Create manuscript and map Scrivener metadata
        var manuscript = ManuscriptDocument()
        manuscript.formatVersion = .current
        manuscript.title = scrivProject.title
        manuscript.creationDate = Date()
        manuscript.modifiedDate = Date()

        // 5. Map labels from Scrivener
        manuscript.labels = scrivProject.labels.map { scrivLabel in
            let label = ManuscriptLabel(
                id: "scriv-label-\(scrivLabel.id)",
                name: scrivLabel.name,
                color: colorToHex(scrivLabel.color)
            )
            labelMap[scrivLabel.id] = label
            return label
        }
        if manuscript.labels.isEmpty {
            manuscript.labels = ManuscriptLabel.defaults
        }

        // 6. Map statuses from Scrivener
        manuscript.statuses = scrivProject.statuses.map { scrivStatus in
            let status = ManuscriptStatus(
                id: "scriv-status-\(scrivStatus.id)",
                name: scrivStatus.name
            )
            statusMap[scrivStatus.id] = status
            return status
        }
        if manuscript.statuses.isEmpty {
            manuscript.statuses = ManuscriptStatus.defaults
        }

        // 7. Map targets
        if let targets = scrivProject.targets {
            manuscript.targets = ManuscriptTargets(
                draftWordCount: targets.draftWordCount,
                draftDeadline: targets.deadline,
                sessionWordCount: targets.sessionWordCount
            )
        }

        // 8. Convert binder items
        progress?(0.20, "Converting documents...")
        let totalItems = countBinderItems(scrivProject.binderItems)
        var convertedCount = 0

        var draftFolder: ManuscriptFolder?
        var researchFolder: ManuscriptFolder?
        var trashFolder: ManuscriptFolder?

        for binderItem in scrivProject.binderItems {
            let progressCallback: (Int) -> Void = { converted in
                convertedCount += converted
                let itemProgress = 0.20 + (Double(convertedCount) / Double(max(totalItems, 1))) * 0.70
                progress?(itemProgress, "Converting: \(binderItem.title)")
            }

            let folder = try await convertBinderItem(
                binderItem,
                projectURL: url,
                contentPath: contentPath,
                version: version,
                options: options,
                onProgress: progressCallback
            )

            switch binderItem.type {
            case .draftFolder:
                draftFolder = folder
            case .researchFolder:
                if options.importResearch {
                    researchFolder = folder
                }
            case .trashFolder:
                if options.importTrash {
                    trashFolder = folder
                }
            default:
                if draftFolder != nil {
                    draftFolder?.subfolders.append(folder)
                }
            }
        }

        // 9. Build final structure
        if let draft = draftFolder {
            manuscript.rootFolder = draft
            manuscript.rootFolder.folderType = .draft
        } else {
            manuscript.rootFolder = ManuscriptFolder(title: scrivProject.title, folderType: .draft)
        }

        if let research = researchFolder {
            manuscript.researchFolder = research
            manuscript.researchFolder?.folderType = .research
        }

        if let trash = trashFolder {
            manuscript.trashFolder = trash
            manuscript.trashFolder?.folderType = .trash
        }

        progress?(1.0, "Import complete!")

        return ImportResult(
            document: manuscript,
            warnings: warnings,
            skippedItems: skippedItems,
            importedDocuments: importedDocuments,
            importedFolders: importedFolders
        )
    }

    // MARK: - Private Methods

    private func validateBundle(at url: URL) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw ImportError.notABundle
        }

        let scrivxPath = url.appendingPathComponent("project.scrivx")
        guard fileManager.fileExists(atPath: scrivxPath.path) else {
            throw ImportError.missingProjectFile
        }
    }

    private func detectVersion(at url: URL) -> ScrivenerVersion {
        let dataPath = url.appendingPathComponent("Files/Data")
        return fileManager.fileExists(atPath: dataPath.path) ? .v3 : .v2
    }

    private func countBinderItems(_ items: [ScrivenerBinderItem]) -> Int {
        items.reduce(0) { count, item in
            count + 1 + countBinderItems(item.children)
        }
    }

    private func hasMediaContent(_ items: [ScrivenerBinderItem]) -> Bool {
        for item in items {
            switch item.type {
            case .pdf, .image, .webPage:
                return true
            default:
                if hasMediaContent(item.children) {
                    return true
                }
            }
        }
        return false
    }

    private func convertBinderItem(
        _ item: ScrivenerBinderItem,
        projectURL: URL,
        contentPath: String,
        version: ScrivenerVersion,
        options: ScrivenerImportOptions,
        onProgress: (Int) -> Void
    ) async throws -> ManuscriptFolder {
        var folder = ManuscriptFolder(
            title: item.title,
            folderType: .subfolder,
            creationDate: item.created ?? Date()
        )

        importedFolders += 1

        for (index, child) in item.children.enumerated() {
            switch child.type {
            case .text:
                do {
                    let document = try await convertTextItem(
                        child,
                        projectURL: projectURL,
                        contentPath: contentPath,
                        version: version,
                        order: index
                    )
                    folder.documents.append(document)
                    importedDocuments += 1
                    onProgress(1)
                } catch {
                    warnings.append(ImportWarning(
                        message: "Could not import document: \(error.localizedDescription)",
                        itemTitle: child.title,
                        severity: .warning
                    ))
                    skippedItems += 1
                    onProgress(1)
                }

            case .folder, .draftFolder, .researchFolder:
                let subfolder = try await convertBinderItem(
                    child,
                    projectURL: projectURL,
                    contentPath: contentPath,
                    version: version,
                    options: options,
                    onProgress: onProgress
                )
                folder.subfolders.append(subfolder)

            case .pdf, .image, .webPage:
                warnings.append(ImportWarning(
                    message: "Media item skipped (not yet supported)",
                    itemTitle: child.title,
                    severity: .info
                ))
                skippedItems += 1
                onProgress(1)

            case .trashFolder:
                if options.importTrash {
                    let subfolder = try await convertBinderItem(
                        child,
                        projectURL: projectURL,
                        contentPath: contentPath,
                        version: version,
                        options: options,
                        onProgress: onProgress
                    )
                    folder.subfolders.append(subfolder)
                } else {
                    skippedItems += countBinderItems([child])
                }

            case .root, .other:
                let subfolder = try await convertBinderItem(
                    child,
                    projectURL: projectURL,
                    contentPath: contentPath,
                    version: version,
                    options: options,
                    onProgress: onProgress
                )
                folder.subfolders.append(subfolder)
            }
        }

        return folder
    }

    private func convertTextItem(
        _ item: ScrivenerBinderItem,
        projectURL: URL,
        contentPath: String,
        version: ScrivenerVersion,
        order: Int
    ) async throws -> ManuscriptDocument.Document {
        let contentURL: URL
        let notesURL: URL
        let synopsisURL: URL

        if version == .v3, let uuid = item.uuid {
            let itemFolder = projectURL
                .appendingPathComponent(contentPath)
                .appendingPathComponent(uuid)
            contentURL = itemFolder.appendingPathComponent("content.rtf")
            notesURL = itemFolder.appendingPathComponent("notes.rtf")
            synopsisURL = itemFolder.appendingPathComponent("synopsis.txt")
        } else {
            let docsFolder = projectURL.appendingPathComponent(contentPath)
            contentURL = docsFolder.appendingPathComponent("\(item.id).rtf")
            notesURL = docsFolder.appendingPathComponent("\(item.id)_notes.rtf")
            synopsisURL = docsFolder.appendingPathComponent("\(item.id)_synopsis.txt")
        }

        // Load content
        var markdownContent = ""
        if fileManager.fileExists(atPath: contentURL.path) {
            do {
                markdownContent = try rtfConverter.convert(rtfURL: contentURL)
            } catch {
                warnings.append(ImportWarning(
                    message: "Could not convert RTF content: \(error.localizedDescription)",
                    itemTitle: item.title,
                    severity: .warning
                ))
            }
        }

        // Load notes
        var notes = ""
        if fileManager.fileExists(atPath: notesURL.path) {
            do {
                notes = try rtfConverter.convert(rtfURL: notesURL)
            } catch {
                // Non-critical
            }
        }

        // Load synopsis
        var synopsis = item.synopsis ?? ""
        if fileManager.fileExists(atPath: synopsisURL.path) {
            do {
                synopsis = try rtfConverter.convertPlainText(from: synopsisURL)
            } catch {
                // Use XML synopsis
            }
        }

        // Map label and status using our built mappings
        var labelId: String? = nil
        var statusId: String? = nil
        var colorName = "Brown"

        if let scrivLabelID = item.labelID, let label = labelMap[scrivLabelID] {
            labelId = label.id
            colorName = mapLabelColorName(label)
        }

        if let scrivStatusID = item.statusID, let status = statusMap[scrivStatusID] {
            statusId = status.id
        }

        return ManuscriptDocument.Document(
            id: UUID(),
            title: item.title,
            outlinePrompt: "",
            outline: synopsis,
            notes: notes,
            content: markdownContent,
            creationDate: item.created ?? Date(),
            order: order,
            colorName: colorName,
            iconName: "doc.text",
            labelId: labelId,
            statusId: statusId,
            keywords: [],
            includeInCompile: item.includeInCompile,
            characterIds: [],
            locationIds: []
        )
    }

    private func colorToHex(_ color: SwiftUI.Color) -> String {
        // Convert SwiftUI Color to hex string
        // This is a simplified implementation
        #if canImport(AppKit)
        guard let nsColor = NSColor(color).usingColorSpace(.deviceRGB) else {
            return "#808080"
        }
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        // iOS fallback - return gray
        return "#808080"
        #endif
    }

    private func mapLabelColorName(_ label: ManuscriptLabel) -> String {
        let name = label.name.lowercased()
        let color = label.color.lowercased()

        // Check by name first
        if name.contains("red") || name.contains("urgent") || name.contains("critical") {
            return "Red"
        } else if name.contains("orange") || name.contains("important") {
            return "Orange"
        } else if name.contains("yellow") || name.contains("review") {
            return "Yellow"
        } else if name.contains("green") || name.contains("done") || name.contains("complete") {
            return "Green"
        } else if name.contains("blue") || name.contains("info") {
            return "Blue"
        } else if name.contains("purple") || name.contains("violet") {
            return "Purple"
        } else if name.contains("pink") {
            return "Pink"
        }

        // Check by color hex
        if color.hasPrefix("#ff") && !color.hasPrefix("#ff0") && !color.hasPrefix("#fff") {
            return "Red"
        } else if color.hasPrefix("#00ff") || color.hasPrefix("#0f0") {
            return "Green"
        } else if color.hasPrefix("#0000ff") || color.hasPrefix("#00f") {
            return "Blue"
        }

        return "Brown"
    }
}
