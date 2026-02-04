import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Document

struct ManuscriptDocument: FileDocument, Equatable, Codable {
    // Format version
    var formatVersion: ManuscriptFormatVersion

    // Document properties
    var title: String
    var author: String
    var description: String
    var style: String
    var genre: String
    var synopsis: String
    var creationDate: Date
    var modifiedDate: Date

    // The root folder of the document (contains draft, notes, research)
    var rootFolder: ManuscriptFolder

    // Additional folders
    var notesFolder: ManuscriptFolder?
    var researchFolder: ManuscriptFolder?
    var trashFolder: ManuscriptFolder?

    // Collections for characters and locations
    var characters: [ManuscriptCharacter]
    var locations: [ManuscriptLocation]

    // Labels and statuses (like Scrivener)
    var labels: [ManuscriptLabel]
    var statuses: [ManuscriptStatus]

    // Project settings
    var targets: ManuscriptTargets
    var settings: ManuscriptSettings
    var compileSettings: ManuscriptCompileSettings

    // Writing history (imported from Scrivener or tracked in-app)
    var writingHistory: WritingHistory

    // Project UI state (selected document, expanded folders, etc.)
    var projectState: ProjectState

    // Document snapshots
    var documentSnapshots: [DocumentSnapshot] = []

    // Template reference (ID of the template used to create this document)
    var templateId: String?

    // Pending asset files to be copied during save (filename -> source URL)
    // Used during Scrivener import to defer file copying until document save
    // Note: This is transient state and is not persisted (excluded from Codable)
    var pendingAssetFiles: [String: URL] = [:]

    // CodingKeys to exclude pendingAssetFiles from serialization
    private enum CodingKeys: String, CodingKey {
        case formatVersion, title, author, description, style, genre, synopsis
        case creationDate, modifiedDate, rootFolder, notesFolder, researchFolder, trashFolder
        case characters, locations, labels, statuses, targets, settings, compileSettings
        case writingHistory, projectState, documentSnapshots, templateId
    }

    // Required for FileDocument
    // Include .package and .folder as fallbacks for when custom UTType isn't registered (e.g., running from Xcode)
    // .folder is needed because macOS may identify .manuscript directories as folders rather than packages
    static var readableContentTypes: [UTType] { [.manuscriptDocument, .package, .folder] }

    // MARK: - Initialization

    init() {
        self.formatVersion = .current
        self.title = ""
        self.author = ""
        self.description = ""
        self.style = ""
        self.genre = ""
        self.synopsis = ""
        self.creationDate = Date()
        self.modifiedDate = Date()
        self.rootFolder = ManuscriptFolder(title: "Draft", folderType: .draft, iconName: "text.book.closed")
        self.notesFolder = ManuscriptFolder(title: "Notes", folderType: .notes)
        self.researchFolder = ManuscriptFolder(title: "Research", folderType: .research, iconName: "books.vertical", iconColor: "#A2845E")
        self.trashFolder = ManuscriptFolder(title: "Trash", folderType: .trash, iconName: "trash", iconColor: "#8E8E93")
        self.characters = []
        self.locations = []
        self.labels = ManuscriptLabel.defaults
        self.statuses = ManuscriptStatus.defaults
        self.targets = ManuscriptTargets()
        self.settings = ManuscriptSettings()
        self.compileSettings = ManuscriptCompileSettings()
        self.writingHistory = WritingHistory()
        self.projectState = ProjectState()
    }

    // MARK: - FileDocument Implementation

    init(configuration: ReadConfiguration) throws {
        print("📄 [ManuscriptDocument] init(configuration:) called")
        print("   - isDirectory: \(configuration.file.isDirectory)")
        print("   - filename: \(configuration.file.filename ?? "nil")")
        print("   - preferredFilename: \(configuration.file.preferredFilename ?? "nil")")

        // Only support package (directory) format
        guard configuration.file.isDirectory else {
            print("❌ [ManuscriptDocument] Error: File is not a directory (package)")
            throw CocoaError(.fileReadUnsupportedScheme)
        }

        do {
            try self.init(fromPackage: configuration.file)
            print("✅ [ManuscriptDocument] Successfully loaded document: \(self.title)")
        } catch {
            print("❌ [ManuscriptDocument] Error loading document: \(error)")
            print("   - Error type: \(type(of: error))")
            print("   - Localized description: \(error.localizedDescription)")
            if let cocoaError = error as? CocoaError {
                print("   - CocoaError code: \(cocoaError.code)")
            }

            // Report error to UI
            let filename = configuration.file.filename ?? configuration.file.preferredFilename
            Task { @MainActor in
                ErrorManager.shared.showDocumentLoadError(error, filename: filename)
            }

            throw error
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        print("💾 [ManuscriptDocument] fileWrapper(configuration:) called")
        print("   - existingFile: \(configuration.existingFile != nil)")

        do {
            let wrapper = try createPackageFileWrapper()
            print("✅ [ManuscriptDocument] Successfully created file wrapper for: \(self.title)")
            return wrapper
        } catch {
            print("❌ [ManuscriptDocument] Error creating file wrapper: \(error)")
            print("   - Error type: \(type(of: error))")
            print("   - Localized description: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Package Format Reading

    private init(fromPackage fileWrapper: FileWrapper) throws {
        print("📦 [ManuscriptDocument] Reading package...")
        print("   - fileWrapper.filename: \(fileWrapper.filename ?? "nil")")

        guard let children = fileWrapper.fileWrappers else {
            print("❌ [ManuscriptDocument] Package has no children (not a directory)")
            throw CocoaError(.fileReadCorruptFile)
        }

        print("   - Package contents: \(children.keys.sorted().joined(separator: ", "))")

        // Read project.json
        guard let projectJsonWrapper = children["project.json"],
              let projectJsonData = projectJsonWrapper.regularFileContents else {
            print("❌ [ManuscriptDocument] Missing or unreadable project.json")
            print("   - project.json exists: \(children["project.json"] != nil)")
            throw CocoaError(.fileReadCorruptFile)
        }

        print("   - project.json size: \(projectJsonData.count) bytes")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let projectData: ProjectJSON
        do {
            projectData = try decoder.decode(ProjectJSON.self, from: projectJsonData)
            print("   - Decoded project: \(projectData.title)")
        } catch {
            print("❌ [ManuscriptDocument] Failed to decode project.json: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   - Missing key: \(key.stringValue) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .typeMismatch(let type, let context):
                    print("   - Type mismatch: expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("   - Value not found: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    print("   - Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)")
                @unknown default:
                    print("   - Unknown decoding error")
                }
            }
            throw error
        }

        self.formatVersion = ManuscriptFormatVersion(rawValue: projectData.version) ?? .current
        self.title = projectData.title
        self.author = projectData.author
        self.description = projectData.description ?? ""
        self.style = projectData.style ?? ""
        self.genre = projectData.genre ?? ""
        self.synopsis = projectData.synopsis ?? ""
        self.creationDate = projectData.created
        self.modifiedDate = projectData.modified
        self.settings = projectData.settings ?? ManuscriptSettings()
        self.compileSettings = projectData.compile ?? ManuscriptCompileSettings()
        self.targets = projectData.targets ?? ManuscriptTargets()
        self.labels = projectData.labels ?? ManuscriptLabel.defaults
        self.statuses = projectData.statuses ?? ManuscriptStatus.defaults
        self.characters = projectData.characters ?? []
        self.locations = projectData.locations ?? []
        self.writingHistory = projectData.writingHistory ?? WritingHistory()

        // Read state.json (UI state)
        if let stateWrapper = children["state.json"],
           let stateData = stateWrapper.regularFileContents {
            self.projectState = (try? decoder.decode(ProjectState.self, from: stateData)) ?? ProjectState()
        } else {
            self.projectState = ProjectState()
        }

        // Read contents folder
        if let contentsWrapper = children["contents"], contentsWrapper.isDirectory {
            // Read draft folder
            if let draftWrapper = contentsWrapper.fileWrappers?["draft"] {
                self.rootFolder = try Self.readFolder(from: draftWrapper, type: .draft)
            } else {
                self.rootFolder = ManuscriptFolder(title: "Draft", folderType: .draft)
            }

            // Read notes folder
            if let notesWrapper = contentsWrapper.fileWrappers?["notes"] {
                self.notesFolder = try Self.readFolder(from: notesWrapper, type: .notes)
            }

            // Read research folder
            if let researchWrapper = contentsWrapper.fileWrappers?["research"] {
                self.researchFolder = try Self.readFolder(from: researchWrapper, type: .research)
            }
        } else {
            self.rootFolder = ManuscriptFolder(title: "Draft", folderType: .draft)
        }

        // Read trash folder
        if let trashWrapper = children["trash"] {
            self.trashFolder = try Self.readFolder(from: trashWrapper, type: .trash)
        }

        // Read snapshots
        if let snapshotsWrapper = children["snapshots"], snapshotsWrapper.isDirectory {
            self.documentSnapshots = Self.readSnapshots(from: snapshotsWrapper)
        }
    }

    private static func readFolder(from fileWrapper: FileWrapper, type: ManuscriptFolderType) throws -> ManuscriptFolder {
        guard fileWrapper.isDirectory, let children = fileWrapper.fileWrappers else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Read folder.json
        var folderMetadata: FolderJSON?
        if let folderJsonWrapper = children["folder.json"],
           let folderJsonData = folderJsonWrapper.regularFileContents {
            folderMetadata = try? decoder.decode(FolderJSON.self, from: folderJsonData)
        }

        // Determine default icon and color based on folder type
        let defaultIcon: String
        let defaultColor: String?
        switch type {
        case .draft:
            defaultIcon = "text.book.closed"
            defaultColor = nil  // Uses .blue in views
        case .research:
            defaultIcon = "books.vertical"
            defaultColor = "#A2845E"  // Brown
        case .trash:
            defaultIcon = "trash"
            defaultColor = "#8E8E93"  // Gray
        default:
            defaultIcon = "folder"
            defaultColor = nil  // Uses .blue in views
        }

        var folder = ManuscriptFolder(
            id: UUID(uuidString: folderMetadata?.id ?? "") ?? UUID(),
            title: folderMetadata?.title ?? fileWrapper.filename ?? "Untitled",
            folderType: type,
            creationDate: folderMetadata?.created ?? Date(),
            iconName: folderMetadata?.iconName ?? defaultIcon,
            iconColor: folderMetadata?.iconColor ?? defaultColor
        )

        // Read items from folder.json to maintain order
        if let items = folderMetadata?.items {
            for item in items {
                if item.type == "document" {
                    // Read the markdown file
                    if let mdWrapper = children[item.file],
                       let mdData = mdWrapper.regularFileContents,
                       let content = String(data: mdData, encoding: .utf8) {

                        // Read notes from separate .notes.md file
                        let notesFilename = item.file.replacingOccurrences(of: ".md", with: ".notes.md")
                        var notes = ""
                        if let notesWrapper = children[notesFilename],
                           let notesData = notesWrapper.regularFileContents,
                           let notesContent = String(data: notesData, encoding: .utf8) {
                            notes = notesContent
                        }

                        // Read comments from separate .comments.json file
                        let commentsFilename = item.file.replacingOccurrences(of: ".md", with: ".comments.json")
                        var comments: [ManuscriptDocument.DocumentComment] = []
                        if let commentsWrapper = children[commentsFilename],
                           let commentsData = commentsWrapper.regularFileContents {
                            comments = (try? decoder.decode([ManuscriptDocument.DocumentComment].self, from: commentsData)) ?? []
                        }

                        let document = ManuscriptDocument.Document(
                            id: UUID(uuidString: item.id) ?? UUID(),
                            title: item.title,
                            synopsis: item.synopsis ?? "",
                            notes: notes,
                            content: extractContentFromMarkdown(content),
                            creationDate: item.created ?? Date(),
                            order: folder.documents.count,
                            iconName: item.iconName ?? "doc.text",
                            iconColor: item.iconColor,
                            labelId: item.label,
                            statusId: item.status,
                            keywords: item.keywords ?? [],
                            linkedDocumentIds: item.linkedDocumentIds?.compactMap { UUID(uuidString: $0) } ?? [],
                            isFavorite: item.isFavorite ?? false,
                            includeInCompile: item.includeInCompile ?? true,
                            comments: comments
                        )
                        folder.documents.append(document)
                    }
                } else if item.type == "folder" {
                    // Recursively read subfolder
                    if let subfolderWrapper = children[item.file] {
                        let subfolder = try readFolder(from: subfolderWrapper, type: .subfolder)
                        folder.subfolders.append(subfolder)
                    }
                } else if item.type == "media" {
                    // Read media item metadata (actual file is in assets/)
                    if let mediaTypeStr = item.mediaType,
                       let mediaType = MediaType(rawValue: mediaTypeStr) {
                        let mediaItem = ManuscriptDocument.MediaItem(
                            id: UUID(uuidString: item.id) ?? UUID(),
                            title: item.title,
                            synopsis: item.synopsis ?? "",
                            mediaType: mediaType,
                            filename: item.file,
                            originalFilename: item.originalFilename ?? item.file,
                            fileSize: item.fileSize ?? 0,
                            creationDate: item.created ?? Date(),
                            order: folder.mediaItems.count,
                            iconName: item.iconName,
                            iconColor: item.iconColor,
                            labelId: item.label,
                            statusId: item.status,
                            keywords: item.keywords ?? [],
                            isFavorite: item.isFavorite ?? false,
                            includeInCompile: item.includeInCompile ?? false,
                            imageWidth: item.imageWidth,
                            imageHeight: item.imageHeight,
                            pageCount: item.pageCount
                        )
                        folder.mediaItems.append(mediaItem)
                    }
                }
            }
        } else {
            // No folder.json - read all markdown files (excluding .notes.md files)
            for (filename, wrapper) in children where filename.hasSuffix(".md") && !filename.hasSuffix(".notes.md") {
                if let data = wrapper.regularFileContents,
                   let content = String(data: data, encoding: .utf8) {
                    let title = filename.replacingOccurrences(of: ".md", with: "")
                        .replacingOccurrences(of: "-", with: " ")
                        .trimmingCharacters(in: .decimalDigits)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                        .trimmingCharacters(in: .whitespaces)

                    // Check for separate notes file
                    let notesFilename = filename.replacingOccurrences(of: ".md", with: ".notes.md")
                    var notes = ""
                    if let notesWrapper = children[notesFilename],
                       let notesData = notesWrapper.regularFileContents,
                       let notesContent = String(data: notesData, encoding: .utf8) {
                        notes = notesContent
                    }

                    let document = ManuscriptDocument.Document(
                        title: title.isEmpty ? "Untitled" : title.capitalized,
                        notes: notes,
                        content: extractContentFromMarkdown(content)
                    )
                    folder.documents.append(document)
                }
            }
        }

        return folder
    }

    private static func readSnapshots(from fileWrapper: FileWrapper) -> [DocumentSnapshot] {
        guard let children = fileWrapper.fileWrappers else { return [] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var allSnapshots: [DocumentSnapshot] = []

        // Iterate through document ID folders
        for (_, docFolderWrapper) in children {
            guard docFolderWrapper.isDirectory,
                  let docSnapshots = docFolderWrapper.fileWrappers else { continue }

            // Read each snapshot JSON file
            for (filename, snapshotWrapper) in docSnapshots {
                guard filename.hasSuffix(".json"),
                      let data = snapshotWrapper.regularFileContents else { continue }

                if let snapshot = try? decoder.decode(DocumentSnapshot.self, from: data) {
                    allSnapshots.append(snapshot)
                }
            }
        }

        return allSnapshots
    }

    private static func extractContentFromMarkdown(_ markdown: String) -> String {
        // Remove YAML frontmatter if present
        if markdown.hasPrefix("---") {
            let parts = markdown.components(separatedBy: "---")
            if parts.count >= 3 {
                return parts.dropFirst(2).joined(separator: "---").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return markdown
    }

    // MARK: - Package Format Writing

    func createPackageFileWrapper() throws -> FileWrapper {
        let rootWrapper = FileWrapper(directoryWithFileWrappers: [:])
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedTitle = sanitizedFilename(from: trimmedTitle)
        if !sanitizedTitle.isEmpty {
            rootWrapper.preferredFilename = sanitizedTitle
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        // Create project.json
        let projectData = ProjectJSON(
            version: formatVersion.rawValue,
            title: title,
            author: author,
            description: description.isEmpty ? nil : description,
            style: style.isEmpty ? nil : style,
            genre: genre.isEmpty ? nil : genre,
            synopsis: synopsis.isEmpty ? nil : synopsis,
            created: creationDate,
            modified: Date(),
            settings: settings,
            compile: compileSettings,
            targets: targets,
            labels: labels,
            statuses: statuses,
            characters: characters.isEmpty ? nil : characters,
            locations: locations.isEmpty ? nil : locations,
            writingHistory: writingHistory.isEmpty ? nil : writingHistory
        )
        let projectJsonData = try encoder.encode(projectData)
        rootWrapper.addRegularFile(withContents: projectJsonData, preferredFilename: "project.json")

        // Create state.json (UI state)
        let stateData = try encoder.encode(projectState)
        rootWrapper.addRegularFile(withContents: stateData, preferredFilename: "state.json")

        // Create contents directory
        let contentsWrapper = FileWrapper(directoryWithFileWrappers: [:])

        // Add draft folder
        let draftWrapper = try createFolderWrapper(for: rootFolder)
        contentsWrapper.addFileWrapper(draftWrapper)

        // Add notes folder
        if let notesFolder = notesFolder, !notesFolder.isEmpty {
            let notesWrapper = try createFolderWrapper(for: notesFolder)
            contentsWrapper.addFileWrapper(notesWrapper)
        }

        // Add research folder
        if let researchFolder = researchFolder, !researchFolder.isEmpty {
            let researchWrapper = try createFolderWrapper(for: researchFolder)
            contentsWrapper.addFileWrapper(researchWrapper)
        }

        contentsWrapper.preferredFilename = "contents"
        rootWrapper.addFileWrapper(contentsWrapper)

        // Add trash folder
        if let trashFolder = trashFolder, !trashFolder.isEmpty {
            let trashWrapper = try createFolderWrapper(for: trashFolder)
            trashWrapper.preferredFilename = "trash"
            rootWrapper.addFileWrapper(trashWrapper)
        }

        // Create assets directory with media files
        let assetsWrapper = try createAssetsWrapper()
        assetsWrapper.preferredFilename = "assets"
        rootWrapper.addFileWrapper(assetsWrapper)

        // Create snapshots directory with actual snapshot data
        let snapshotsWrapper = try createSnapshotsWrapper()
        snapshotsWrapper.preferredFilename = "snapshots"
        rootWrapper.addFileWrapper(snapshotsWrapper)

        return rootWrapper
    }

    private func createFolderWrapper(for folder: ManuscriptFolder) throws -> FileWrapper {
        let folderWrapper = FileWrapper(directoryWithFileWrappers: [:])
        folderWrapper.preferredFilename = folder.folderType.directoryName

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        // Build items array for folder.json
        var items: [FolderItem] = []

        // Sort documents by order before writing
        let sortedDocuments = folder.documents.sorted { $0.order < $1.order }

        // Add documents
        for (index, document) in sortedDocuments.enumerated() {
            let filename = String(format: "%02d-%@.md", index + 1, document.title.slugified)

            let item = FolderItem(
                id: document.id.uuidString,
                file: filename,
                title: document.title,
                type: "document",
                label: document.labelId,
                status: document.statusId,
                keywords: document.keywords.isEmpty ? nil : document.keywords,
                linkedDocumentIds: document.linkedDocumentIds.isEmpty ? nil : document.linkedDocumentIds.map { $0.uuidString },
                isFavorite: document.isFavorite,
                synopsis: document.synopsis.isEmpty ? nil : document.synopsis,
                includeInCompile: document.includeInCompile,
                created: document.creationDate,
                modified: Date(),
                iconName: document.iconName == "doc.text" ? nil : document.iconName,
                iconColor: document.iconColor
            )
            items.append(item)

            // Create markdown file (content only, no notes embedded)
            let mdContent = createMarkdownContent(for: document)
            if let mdData = mdContent.data(using: .utf8) {
                folderWrapper.addRegularFile(withContents: mdData, preferredFilename: filename)
            }

            // Create separate notes file if notes exist
            if !document.notes.isEmpty {
                let notesFilename = filename.replacingOccurrences(of: ".md", with: ".notes.md")
                if let notesData = document.notes.data(using: .utf8) {
                    folderWrapper.addRegularFile(withContents: notesData, preferredFilename: notesFilename)
                }
            }

            // Create separate comments file if comments exist
            if !document.comments.isEmpty {
                let commentsFilename = filename.replacingOccurrences(of: ".md", with: ".comments.json")
                if let commentsData = try? encoder.encode(document.comments) {
                    folderWrapper.addRegularFile(withContents: commentsData, preferredFilename: commentsFilename)
                }
            }
        }

        // Sort subfolders by order before writing
        let sortedSubfolders = folder.subfolders.sorted { $0.order < $1.order }

        // Add subfolders
        for (index, subfolder) in sortedSubfolders.enumerated() {
            let folderName = String(format: "%02d-%@", index + sortedDocuments.count + 1, subfolder.title.slugified)

            let item = FolderItem(
                id: subfolder.id.uuidString,
                file: folderName,
                title: subfolder.title,
                type: "folder",
                label: nil,
                status: nil,
                keywords: nil,
                linkedDocumentIds: nil,
                isFavorite: nil,
                synopsis: nil,
                includeInCompile: true,
                created: subfolder.creationDate,
                modified: Date(),
                iconName: subfolder.iconName == "folder" ? nil : subfolder.iconName,
                iconColor: subfolder.iconColor
            )
            items.append(item)

            // Create subfolder
            var subfolderCopy = subfolder
            subfolderCopy.folderType = .subfolder
            let subfolderWrapper = try createFolderWrapper(for: subfolderCopy)
            subfolderWrapper.preferredFilename = folderName
            folderWrapper.addFileWrapper(subfolderWrapper)
        }

        // Sort media items by order before writing
        let sortedMediaItems = folder.mediaItems.sorted { $0.order < $1.order }

        // Add media items (metadata only - actual files are in assets/)
        for mediaItem in sortedMediaItems {
            let item = FolderItem(
                id: mediaItem.id.uuidString,
                file: mediaItem.filename,
                title: mediaItem.title,
                type: "media",
                label: mediaItem.labelId,
                status: mediaItem.statusId,
                keywords: mediaItem.keywords.isEmpty ? nil : mediaItem.keywords,
                linkedDocumentIds: nil,
                isFavorite: mediaItem.isFavorite,
                synopsis: mediaItem.synopsis.isEmpty ? nil : mediaItem.synopsis,
                includeInCompile: mediaItem.includeInCompile,
                created: mediaItem.creationDate,
                modified: Date(),
                iconName: mediaItem.iconName == mediaItem.mediaType.iconName ? nil : mediaItem.iconName,
                iconColor: mediaItem.iconColor,
                mediaType: mediaItem.mediaType.rawValue,
                originalFilename: mediaItem.originalFilename,
                fileSize: mediaItem.fileSize,
                imageWidth: mediaItem.imageWidth,
                imageHeight: mediaItem.imageHeight,
                pageCount: mediaItem.pageCount
            )
            items.append(item)
        }

        // Create folder.json
        let folderJson = FolderJSON(
            id: folder.id.uuidString,
            title: folder.title,
            type: folder.folderType.rawValue,
            created: folder.creationDate,
            modified: Date(),
            expanded: true,
            iconName: folder.iconName == "folder" ? nil : folder.iconName,
            iconColor: folder.iconColor,
            items: items
        )
        let folderJsonData = try encoder.encode(folderJson)
        folderWrapper.addRegularFile(withContents: folderJsonData, preferredFilename: "folder.json")

        return folderWrapper
    }

    private func createSnapshotsWrapper() throws -> FileWrapper {
        let snapshotsWrapper = FileWrapper(directoryWithFileWrappers: [:])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        // Group snapshots by documentId
        let groupedSnapshots = Dictionary(grouping: documentSnapshots) { $0.documentId }

        for (documentId, snapshots) in groupedSnapshots {
            let docFolderWrapper = FileWrapper(directoryWithFileWrappers: [:])
            docFolderWrapper.preferredFilename = documentId.uuidString

            for snapshot in snapshots {
                let snapshotData = try encoder.encode(snapshot)
                docFolderWrapper.addRegularFile(
                    withContents: snapshotData,
                    preferredFilename: "\(snapshot.id.uuidString).json"
                )
            }

            snapshotsWrapper.addFileWrapper(docFolderWrapper)
        }

        return snapshotsWrapper
    }

    private func createAssetsWrapper() throws -> FileWrapper {
        let assetsWrapper = FileWrapper(directoryWithFileWrappers: [:])

        // Collect all media items from all folders
        var allMediaItems: [ManuscriptDocument.MediaItem] = []
        collectMediaItems(from: rootFolder, into: &allMediaItems)
        if let research = researchFolder {
            collectMediaItems(from: research, into: &allMediaItems)
        }
        if let notes = notesFolder {
            collectMediaItems(from: notes, into: &allMediaItems)
        }
        if let trash = trashFolder {
            collectMediaItems(from: trash, into: &allMediaItems)
        }

        // For each media item, check if we have a pending file to copy
        for mediaItem in allMediaItems {
            if let sourceURL = pendingAssetFiles[mediaItem.filename] {
                // Copy the file from the source URL
                do {
                    let fileData = try Data(contentsOf: sourceURL)
                    assetsWrapper.addRegularFile(withContents: fileData, preferredFilename: mediaItem.filename)
                } catch {
                    print("⚠️ [ManuscriptDocument] Failed to copy asset file \(mediaItem.filename): \(error)")
                }
            }
            // Note: Existing assets (already in the package) are preserved by FileWrapper's merge behavior
        }

        return assetsWrapper
    }

    private func collectMediaItems(from folder: ManuscriptFolder, into items: inout [ManuscriptDocument.MediaItem]) {
        items.append(contentsOf: folder.mediaItems)
        for subfolder in folder.subfolders {
            collectMediaItems(from: subfolder, into: &items)
        }
    }

    private func sanitizedFilename(from title: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = title
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
        let collapsed = cleaned
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return collapsed
    }

    private func createMarkdownContent(for document: ManuscriptDocument.Document) -> String {
        var content = ""

        // Add YAML frontmatter if there's metadata (synopsis only, notes are stored separately)
        if !document.synopsis.isEmpty {
            content += "---\n"
            content += "title: \(document.title)\n"
            content += "synopsis: \(document.synopsis.replacingOccurrences(of: "\n", with: " "))\n"
            content += "---\n\n"
        }

        content += document.content

        // Notes are now stored in separate .notes.md files, not embedded as HTML comments

        return content
    }

}

// MARK: - JSON Schemas

/// Schema for project.json
private struct ProjectJSON: Codable {
    let version: String
    var title: String
    var author: String
    var description: String?
    var style: String?
    var genre: String?
    var synopsis: String?
    var created: Date
    var modified: Date
    var settings: ManuscriptSettings?
    var compile: ManuscriptCompileSettings?
    var targets: ManuscriptTargets?
    var labels: [ManuscriptLabel]?
    var statuses: [ManuscriptStatus]?
    var characters: [ManuscriptCharacter]?
    var locations: [ManuscriptLocation]?
    var writingHistory: WritingHistory?
}

/// Schema for folder.json
private struct FolderJSON: Codable {
    var id: String
    var title: String
    var type: String
    var created: Date
    var modified: Date
    var expanded: Bool
    var iconName: String?
    var iconColor: String?
    var items: [FolderItem]
}

/// Item in folder.json
private struct FolderItem: Codable {
    var id: String
    var file: String
    var title: String
    var type: String  // "document", "folder", or "media"
    var label: String?
    var status: String?
    var keywords: [String]?
    var linkedDocumentIds: [String]?
    var isFavorite: Bool?
    var synopsis: String?
    var includeInCompile: Bool?
    var created: Date?
    var modified: Date?
    var iconName: String?
    var iconColor: String?  // Hex color for icon tint (e.g., "#FF0000")

    // Media-specific properties
    var mediaType: String?         // "image" or "pdf"
    var originalFilename: String?
    var fileSize: Int64?
    var imageWidth: Int?
    var imageHeight: Int?
    var pageCount: Int?
}

// MARK: - Preview Support

#if DEBUG
extension ManuscriptDocument {
    static func preview(title: String, author: String) -> ManuscriptDocument {
        var doc = ManuscriptDocument()
        doc.title = title
        doc.author = author
        return doc
    }
}
#endif
