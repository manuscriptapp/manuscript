import Foundation

/// Exports Manuscript documents to Scrivener 3 (.scriv) format
final class ScrivenerExporter {

    // MARK: - Singleton

    static let shared = ScrivenerExporter()

    private init() {}

    // MARK: - Export Error

    enum ExportError: LocalizedError {
        case failedToCreateDirectory
        case failedToWriteFile(String)
        case failedToCreateZip

        var errorDescription: String? {
            switch self {
            case .failedToCreateDirectory:
                return "Failed to create the Scrivener project directory structure."
            case .failedToWriteFile(let filename):
                return "Failed to write file: \(filename)"
            case .failedToCreateZip:
                return "Failed to create the ZIP archive."
            }
        }
    }

    // MARK: - Public Methods

    /// Exports a ManuscriptDocument to Scrivener format
    /// - Parameters:
    ///   - document: The document to export
    ///   - progress: Optional progress callback
    /// - Returns: URL to the created .scriv folder (in temp directory)
    func export(
        document: ManuscriptDocument,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> URL {
        progress?(0.05, "Preparing export...")

        // 1. Build UUID mapping for all folders and documents
        let uuidMapping = ScrivenerXMLBuilder.buildUUIDMapping(for: document)
        let labelIdMapping = ScrivenerXMLBuilder.buildLabelIdMapping(for: document)
        let statusIdMapping = ScrivenerXMLBuilder.buildStatusIdMapping(for: document)
        let keywordIdMapping = ScrivenerXMLBuilder.buildKeywordIdMapping(for: document)

        progress?(0.10, "Creating project structure...")

        // 2. Create temp directory for .scriv package
        let tempDir = FileManager.default.temporaryDirectory
        let projectName = document.title.isEmpty ? "Untitled" : document.title.slugified
        let scrivDir = tempDir.appendingPathComponent("\(projectName).scriv")

        // Remove existing if present
        if FileManager.default.fileExists(atPath: scrivDir.path) {
            try FileManager.default.removeItem(at: scrivDir)
        }

        // Create .scriv directory structure
        try FileManager.default.createDirectory(at: scrivDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: scrivDir.appendingPathComponent("Files/Data"),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: scrivDir.appendingPathComponent("Settings"),
            withIntermediateDirectories: true
        )

        progress?(0.20, "Generating project manifest...")

        // 3. Generate .scrivx XML
        let xmlBuilder = ScrivenerXMLBuilder(
            document: document,
            uuidMapping: uuidMapping,
            labelIdMapping: labelIdMapping,
            statusIdMapping: statusIdMapping,
            keywordIdMapping: keywordIdMapping
        )
        let scrivxContent = xmlBuilder.build()

        // Write .scrivx file
        let scrivxPath = scrivDir.appendingPathComponent("\(projectName).scrivx")
        try scrivxContent.write(to: scrivxPath, atomically: true, encoding: .utf8)

        progress?(0.30, "Writing version file...")

        // 4. Write version.txt (Scrivener 3 format version)
        let versionPath = scrivDir.appendingPathComponent("Files/version.txt")
        try "16".write(to: versionPath, atomically: true, encoding: .utf8)

        progress?(0.35, "Converting documents...")

        // 5. Write content files for all documents
        let rtfConverter = MarkdownToRTFConverter.shared
        let dataDir = scrivDir.appendingPathComponent("Files/Data")

        // Calculate total items for progress
        let totalItems = countAllDocuments(document: document)
        var processedItems = 0

        // Process draft folder
        try processFolder(
            document.rootFolder,
            uuidMapping: uuidMapping,
            rtfConverter: rtfConverter,
            dataDir: dataDir,
            totalItems: totalItems,
            processedItems: &processedItems,
            progress: progress
        )

        // Process research folder
        if let researchFolder = document.researchFolder, !researchFolder.isEmpty {
            try processFolder(
                researchFolder,
                uuidMapping: uuidMapping,
                rtfConverter: rtfConverter,
                dataDir: dataDir,
                totalItems: totalItems,
                processedItems: &processedItems,
                progress: progress
            )
        }

        // Process trash folder
        if let trashFolder = document.trashFolder, !trashFolder.isEmpty {
            try processFolder(
                trashFolder,
                uuidMapping: uuidMapping,
                rtfConverter: rtfConverter,
                dataDir: dataDir,
                totalItems: totalItems,
                processedItems: &processedItems,
                progress: progress
            )
        }

        progress?(1.0, "Export complete!")

        return scrivDir
    }

    /// Exports a ManuscriptDocument to a ZIP-compressed .scriv archive
    /// This is useful for iOS where sharing folders is less convenient
    /// - Parameters:
    ///   - document: The document to export
    ///   - progress: Optional progress callback
    /// - Returns: Data containing the ZIP archive
    func exportAsZip(
        document: ManuscriptDocument,
        progress: ((Double, String) -> Void)? = nil
    ) async throws -> Data {
        // First export to folder
        let scrivURL = try await export(document: document, progress: { fraction, message in
            // Scale progress to 0-80%
            progress?(fraction * 0.8, message)
        })

        progress?(0.85, "Creating ZIP archive...")

        // Create ZIP archive
        let zipBuilder = ZipArchiveBuilder()

        // Add all files from the .scriv directory
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: scrivURL, includingPropertiesForKeys: nil)

        while let fileURL = enumerator?.nextObject() as? URL {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else { continue }

            if !isDirectory.boolValue {
                let relativePath = fileURL.path.replacingOccurrences(
                    of: scrivURL.deletingLastPathComponent().path + "/",
                    with: ""
                )

                if let data = try? Data(contentsOf: fileURL) {
                    zipBuilder.addFile(path: relativePath, data: data)
                }
            }
        }

        progress?(0.95, "Finalizing...")

        let zipData = try zipBuilder.finalize()

        // Clean up temp directory
        try? fileManager.removeItem(at: scrivURL)

        progress?(1.0, "Export complete!")

        return zipData
    }

    // MARK: - Private Methods

    private func countAllDocuments(document: ManuscriptDocument) -> Int {
        var count = countDocuments(in: document.rootFolder)
        if let research = document.researchFolder {
            count += countDocuments(in: research)
        }
        if let trash = document.trashFolder {
            count += countDocuments(in: trash)
        }
        return max(count, 1)
    }

    private func countDocuments(in folder: ManuscriptFolder) -> Int {
        var count = folder.documents.count
        for subfolder in folder.subfolders {
            count += countDocuments(in: subfolder)
        }
        return count
    }

    private func processFolder(
        _ folder: ManuscriptFolder,
        uuidMapping: [UUID: String],
        rtfConverter: MarkdownToRTFConverter,
        dataDir: URL,
        totalItems: Int,
        processedItems: inout Int,
        progress: ((Double, String) -> Void)?
    ) throws {
        // Create folder's data directory (even if empty, to maintain structure)
        if let folderUUID = uuidMapping[folder.id] {
            let folderDir = dataDir.appendingPathComponent(folderUUID)
            try FileManager.default.createDirectory(at: folderDir, withIntermediateDirectories: true)
        }

        // Process documents
        for doc in folder.documents {
            guard let docUUID = uuidMapping[doc.id] else { continue }

            let docDir = dataDir.appendingPathComponent(docUUID)
            try FileManager.default.createDirectory(at: docDir, withIntermediateDirectories: true)

            // Write content.rtf
            let rtfData = rtfConverter.convert(doc.content)
            let contentPath = docDir.appendingPathComponent("content.rtf")
            try rtfData.write(to: contentPath)

            // Write notes.rtf if notes exist
            if !doc.notes.isEmpty {
                let notesRTF = rtfConverter.convert(doc.notes)
                let notesPath = docDir.appendingPathComponent("notes.rtf")
                try notesRTF.write(to: notesPath)
            }

            // Write synopsis.txt if synopsis exists
            if !doc.synopsis.isEmpty {
                let synopsisPath = docDir.appendingPathComponent("synopsis.txt")
                try doc.synopsis.write(to: synopsisPath, atomically: true, encoding: .utf8)
            }

            processedItems += 1
            let fraction = 0.35 + (Double(processedItems) / Double(totalItems)) * 0.60
            progress?(fraction, "Converting: \(doc.title)")
        }

        // Process subfolders recursively
        for subfolder in folder.subfolders {
            try processFolder(
                subfolder,
                uuidMapping: uuidMapping,
                rtfConverter: rtfConverter,
                dataDir: dataDir,
                totalItems: totalItems,
                processedItems: &processedItems,
                progress: progress
            )
        }
    }
}
