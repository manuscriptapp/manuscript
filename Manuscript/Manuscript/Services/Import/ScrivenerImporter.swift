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

    // MARK: - Initialization

    init() {
        self.xmlParser = ScrivenerXMLParser()
        self.rtfConverter = RTFToMarkdownConverter()
        self.fileManager = FileManager.default
    }

    // MARK: - Public Methods

    /// Validate a Scrivener project without importing
    /// - Parameter url: URL to the .scriv bundle
    /// - Returns: Validation result with any warnings/errors
    func validateProject(at url: URL) -> ScrivenerValidationResult {
        var warnings: [String] = []
        var errors: [String] = []

        // Check bundle structure
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

        // Check for project.scrivx
        let scrivxPath = url.appendingPathComponent("project.scrivx")
        guard fileManager.fileExists(atPath: scrivxPath.path) else {
            return ScrivenerValidationResult(
                isValid: false,
                errors: ["Missing project.scrivx file - this may not be a valid Scrivener project"]
            )
        }

        // Detect version
        let version = detectVersion(at: url)

        // Check for content directory
        let hasV3Data = fileManager.fileExists(atPath: url.appendingPathComponent("Files/Data").path)
        let hasV2Docs = fileManager.fileExists(atPath: url.appendingPathComponent("Files/Docs").path)

        if !hasV3Data && !hasV2Docs {
            warnings.append("No content directory found - documents may be empty")
        }

        // Try to parse the project to count items
        var projectTitle = ""
        var itemCount = 0

        do {
            let project = try xmlParser.parse(projectURL: scrivxPath)
            projectTitle = project.title
            itemCount = countBinderItems(project.binderItems)

            if itemCount > 500 {
                warnings.append("Large project (\(itemCount) items) - import may take a while")
            }

            // Check for media content
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
    /// - Parameters:
    ///   - url: URL to the .scriv bundle
    ///   - options: Import configuration options
    ///   - progress: Progress callback (progress 0.0-1.0, status message)
    /// - Returns: ImportResult containing the document and any warnings
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

        // 1. Validate bundle structure
        progress?(0.05, "Validating Scrivener project...")
        try validateBundle(at: url)

        // 2. Parse project.scrivx
        progress?(0.10, "Reading project structure...")
        let scrivxURL = url.appendingPathComponent("project.scrivx")
        let scrivProject = try xmlParser.parse(projectURL: scrivxURL)

        // 3. Detect version and content location
        let version = detectVersion(at: url)
        let contentPath = version == .v3 ? "Files/Data" : "Files/Docs"

        // 4. Create Manuscript document
        var manuscript = ManuscriptDocument()
        manuscript.title = scrivProject.title
        manuscript.creationDate = Date()

        // 5. Create label and status maps for reference
        let labelMap = Dictionary(uniqueKeysWithValues: scrivProject.labels.map { ($0.id, $0) })
        let statusMap = Dictionary(uniqueKeysWithValues: scrivProject.statuses.map { ($0.id, $0) })

        // 6. Convert binder items to folders/documents
        progress?(0.20, "Converting documents...")
        let totalItems = countBinderItems(scrivProject.binderItems)
        var convertedCount = 0

        // Find the draft folder
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
                labelMap: labelMap,
                statusMap: statusMap,
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
                // Add other root items as subfolders of draft
                if draftFolder != nil {
                    draftFolder?.subfolders.append(folder)
                }
            }
        }

        // 7. Build the final structure
        if let draft = draftFolder {
            manuscript.rootFolder = draft

            // Add research as a subfolder if imported
            if let research = researchFolder {
                manuscript.rootFolder.subfolders.append(research)
            }

            // Add trash as a subfolder if imported
            if let trash = trashFolder {
                manuscript.rootFolder.subfolders.append(trash)
            }
        } else {
            // No draft folder found - create one from root items
            manuscript.rootFolder = ManuscriptFolder(title: scrivProject.title)
            for binderItem in scrivProject.binderItems {
                let folder = try await convertBinderItem(
                    binderItem,
                    projectURL: url,
                    contentPath: contentPath,
                    version: version,
                    labelMap: labelMap,
                    statusMap: statusMap,
                    options: options,
                    onProgress: { _ in }
                )
                if binderItem.type == .folder || binderItem.children.isEmpty == false {
                    manuscript.rootFolder.subfolders.append(folder)
                }
            }
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
        // Check it's a directory
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw ImportError.notABundle
        }

        // Check for project.scrivx
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
        labelMap: [Int: ScrivenerLabel],
        statusMap: [Int: ScrivenerStatus],
        options: ScrivenerImportOptions,
        onProgress: (Int) -> Void
    ) async throws -> ManuscriptFolder {
        var folder = ManuscriptFolder(
            title: item.title,
            creationDate: item.created ?? Date()
        )

        importedFolders += 1

        // Convert children recursively
        for (index, child) in item.children.enumerated() {
            switch child.type {
            case .text:
                // Convert to document
                do {
                    let document = try await convertTextItem(
                        child,
                        projectURL: projectURL,
                        contentPath: contentPath,
                        version: version,
                        order: index,
                        labelMap: labelMap,
                        statusMap: statusMap
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
                // Convert to subfolder
                let subfolder = try await convertBinderItem(
                    child,
                    projectURL: projectURL,
                    contentPath: contentPath,
                    version: version,
                    labelMap: labelMap,
                    statusMap: statusMap,
                    options: options,
                    onProgress: onProgress
                )
                folder.subfolders.append(subfolder)

            case .pdf, .image, .webPage:
                // Skip media items for now, add warning
                warnings.append(ImportWarning(
                    message: "Media item skipped (not yet supported)",
                    itemTitle: child.title,
                    severity: .info
                ))
                skippedItems += 1
                onProgress(1)

            case .trashFolder:
                // Only include if option is set
                if options.importTrash {
                    let subfolder = try await convertBinderItem(
                        child,
                        projectURL: projectURL,
                        contentPath: contentPath,
                        version: version,
                        labelMap: labelMap,
                        statusMap: statusMap,
                        options: options,
                        onProgress: onProgress
                    )
                    folder.subfolders.append(subfolder)
                } else {
                    skippedItems += countBinderItems([child])
                }

            case .root, .other:
                // Try to convert as a generic folder
                let subfolder = try await convertBinderItem(
                    child,
                    projectURL: projectURL,
                    contentPath: contentPath,
                    version: version,
                    labelMap: labelMap,
                    statusMap: statusMap,
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
        order: Int,
        labelMap: [Int: ScrivenerLabel],
        statusMap: [Int: ScrivenerStatus]
    ) async throws -> ManuscriptDocument.Document {
        // Determine content file path
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

        // Load and convert content
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

        // Load notes if available
        var notes = ""
        if fileManager.fileExists(atPath: notesURL.path) {
            do {
                notes = try rtfConverter.convert(rtfURL: notesURL)
            } catch {
                // Non-critical - just skip notes
            }
        }

        // Load synopsis - prefer from file, fallback to XML
        var synopsis = item.synopsis ?? ""
        if fileManager.fileExists(atPath: synopsisURL.path) {
            do {
                synopsis = try rtfConverter.convertPlainText(from: synopsisURL)
            } catch {
                // Use XML synopsis as fallback
            }
        }

        // Map label to color
        var colorName = "Brown"  // Default
        if let labelID = item.labelID, let label = labelMap[labelID] {
            colorName = mapLabelToColorName(label)
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
            iconName: "doc.text"
        )
    }

    private func mapLabelToColorName(_ label: ScrivenerLabel) -> String {
        // Map Scrivener label colors to Manuscript color names
        // This is a simplified mapping based on label name keywords
        let name = label.name.lowercased()

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
        } else {
            return "Brown"
        }
    }
}

// MARK: - UTType Extension for Scrivener

extension UTType {
    /// Scrivener project bundle type
    static var scrivenerProject: UTType {
        UTType(filenameExtension: "scriv") ?? .folder
    }
}
