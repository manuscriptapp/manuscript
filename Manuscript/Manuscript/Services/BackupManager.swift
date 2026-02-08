import Foundation
import Combine
import CryptoKit

@MainActor
final class BackupManager: ObservableObject {
    @Published var isAutoBackupEnabled: Bool {
        didSet {
            userDefaults.set(isAutoBackupEnabled, forKey: Self.autoBackupEnabledKey)
            updateSchedule()
        }
    }
    @Published var backupIntervalMinutes: Double {
        didSet {
            userDefaults.set(backupIntervalMinutes, forKey: Self.backupIntervalKey)
            updateSchedule()
        }
    }
    @Published var maxBackupsPerDocument: Int {
        didSet {
            userDefaults.set(maxBackupsPerDocument, forKey: Self.maxBackupsKey)
            pruneBackupsIfNeeded()
        }
    }
    @Published private(set) var lastBackupDate: Date?
    @Published private(set) var lastBackupError: String?
    @Published private(set) var backups: [BackupRecord] = []
    @Published private(set) var isBackupInProgress = false

    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private var backupTimer: AnyCancellable?
    private var documentURL: URL?
    private var documentTitle: String = ""

    private static let autoBackupEnabledKey = "backupAutoEnabled"
    private static let backupIntervalKey = "backupIntervalMinutes"
    private static let maxBackupsKey = "backupMaxPerDocument"

    init() {
        let defaultAutoEnabled = true
        let defaultInterval: Double = 30
        let defaultMaxBackups = 10

        if userDefaults.object(forKey: Self.autoBackupEnabledKey) == nil {
            userDefaults.set(defaultAutoEnabled, forKey: Self.autoBackupEnabledKey)
        }
        if userDefaults.object(forKey: Self.backupIntervalKey) == nil {
            userDefaults.set(defaultInterval, forKey: Self.backupIntervalKey)
        }
        if userDefaults.object(forKey: Self.maxBackupsKey) == nil {
            userDefaults.set(defaultMaxBackups, forKey: Self.maxBackupsKey)
        }

        self.isAutoBackupEnabled = userDefaults.bool(forKey: Self.autoBackupEnabledKey)
        self.backupIntervalMinutes = userDefaults.double(forKey: Self.backupIntervalKey)
        self.maxBackupsPerDocument = userDefaults.integer(forKey: Self.maxBackupsKey)

        if self.maxBackupsPerDocument == 0 {
            self.maxBackupsPerDocument = defaultMaxBackups
        }
    }

    var isDocumentReady: Bool {
        documentURL != nil
    }

    var backupRootPath: String? {
        try? backupRootURL().path
    }

    func configure(documentURL: URL?, documentTitle: String) {
        self.documentURL = documentURL
        self.documentTitle = documentTitle
        refreshBackupsList()
        updateSchedule()
    }

    func updateDocumentTitle(_ title: String) {
        documentTitle = title
    }

    func refreshBackupsList() {
        guard let documentURL else {
            backups = []
            lastBackupDate = nil
            return
        }

        let records = loadBackupRecords(for: documentURL)
        backups = records.sorted(by: { $0.createdAt > $1.createdAt })
        lastBackupDate = backups.first?.createdAt
    }

    func performManualBackup() {
        createBackup(reason: .manual, force: true)
    }

    func performBackgroundBackupIfNeeded() {
        createBackup(reason: .background, force: false)
    }

    func performScheduledBackupIfNeeded() {
        createBackup(reason: .automatic, force: false)
    }

    func deleteBackup(_ record: BackupRecord) {
        do {
            try fileManager.removeItem(at: record.backupFolderURL)
            refreshBackupsList()
        } catch {
            lastBackupError = "Failed to delete backup: \(error.localizedDescription)"
        }
    }

    private func updateSchedule() {
        backupTimer?.cancel()
        backupTimer = nil

        guard isAutoBackupEnabled, backupIntervalMinutes > 0, documentURL != nil else { return }

        let interval = backupIntervalMinutes * 60
        backupTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.performScheduledBackupIfNeeded()
                }
            }
    }

    private func createBackup(reason: BackupReason, force: Bool) {
        guard !isBackupInProgress else { return }
        guard let documentURL else {
            lastBackupError = "Save your manuscript before creating backups."
            return
        }
        guard isAutoBackupEnabled || force else { return }

        let now = Date()
        if !force, let lastBackupDate {
            let interval = backupIntervalMinutes * 60
            if now.timeIntervalSince(lastBackupDate) < interval {
                return
            }
        }

        isBackupInProgress = true
        lastBackupError = nil

        let titleSnapshot = documentTitle
        let maxBackups = maxBackupsPerDocument

        Task.detached(priority: .utility) {
            do {
                let record = try Self.performBackup(
                    documentURL: documentURL,
                    documentTitle: titleSnapshot,
                    reason: reason,
                    fileManager: FileManager.default
                )

                await MainActor.run {
                    self.lastBackupDate = record.createdAt
                    self.backups.insert(record, at: 0)
                    self.pruneBackupsIfNeeded(maxBackups: maxBackups)
                    self.isBackupInProgress = false
                }
            } catch {
                await MainActor.run {
                    self.lastBackupError = error.localizedDescription
                    self.isBackupInProgress = false
                }
            }
        }
    }

    private func pruneBackupsIfNeeded(maxBackups: Int? = nil) {
        let limit = maxBackups ?? maxBackupsPerDocument
        guard limit > 0 else { return }

        if backups.count <= limit { return }

        let sortedBackups = backups.sorted(by: { $0.createdAt > $1.createdAt })
        let backupsToRemove = sortedBackups.suffix(from: limit)
        for backup in backupsToRemove {
            do {
                try fileManager.removeItem(at: backup.backupFolderURL)
            } catch {
                lastBackupError = "Failed to remove old backup: \(error.localizedDescription)"
            }
        }
        refreshBackupsList()
    }

    private func loadBackupRecords(for documentURL: URL) -> [BackupRecord] {
        do {
            let folderURL = try documentBackupFolderURL(for: documentURL)
            let contents = try fileManager.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            return contents.compactMap { folder in
                guard folder.hasDirectoryPath else { return nil }
                return Self.readBackupRecord(from: folder, documentURL: documentURL)
            }
        } catch {
            return []
        }
    }

    private func backupRootURL() throws -> URL {
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw BackupError.missingApplicationSupportDirectory
        }
        let rootURL = baseURL.appendingPathComponent("Manuscript", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)
        if !fileManager.fileExists(atPath: rootURL.path) {
            try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        }
        return rootURL
    }

    private func documentBackupFolderURL(for documentURL: URL) throws -> URL {
        let root = try backupRootURL()
        let identifier = Self.documentIdentifier(for: documentURL)
        let folderURL = root.appendingPathComponent(identifier, isDirectory: true)
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL
    }

    private nonisolated static func performBackup(
        documentURL: URL,
        documentTitle: String,
        reason: BackupReason,
        fileManager: FileManager
    ) throws -> BackupRecord {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?
        var backupError: Error?
        var backupRecord: BackupRecord?
        coordinator.coordinate(readingItemAt: documentURL, options: .withoutChanges, error: &coordinatorError) { coordinatedURL in
            do {
                let backupDate = Date()
                let title = documentTitle.isEmpty ? documentURL.deletingPathExtension().lastPathComponent : documentTitle
                let rootURL = try Self.backupRootURL(fileManager: fileManager)
                let documentFolder = rootURL.appendingPathComponent(Self.documentIdentifier(for: documentURL), isDirectory: true)
                if !fileManager.fileExists(atPath: documentFolder.path) {
                    try fileManager.createDirectory(at: documentFolder, withIntermediateDirectories: true)
                }

                let timestamp = Self.timestampString(from: backupDate)
                let backupFolder = documentFolder.appendingPathComponent("\(timestamp)-\(String(UUID().uuidString.prefix(8)))", isDirectory: true)
                let tempFolder = documentFolder.appendingPathComponent(".backup-\(UUID().uuidString)", isDirectory: true)
                try fileManager.createDirectory(at: tempFolder, withIntermediateDirectories: true)

                let backupPackageURL = tempFolder.appendingPathComponent(documentURL.lastPathComponent, isDirectory: true)
                try fileManager.copyItem(at: coordinatedURL, to: backupPackageURL)

                let finalBackupFolder = backupFolder
                try fileManager.moveItem(at: tempFolder, to: finalBackupFolder)

                let finalPackageURL = finalBackupFolder.appendingPathComponent(documentURL.lastPathComponent, isDirectory: true)
                let size = Self.directorySize(at: finalPackageURL, fileManager: fileManager)
                let metadata = BackupMetadata(
                    id: UUID(),
                    createdAt: backupDate,
                    reason: reason,
                    originalFileName: documentURL.lastPathComponent,
                    originalPath: documentURL.path,
                    documentTitle: title,
                    sizeBytes: size,
                    appVersion: Self.appVersionString()
                )
                try Self.writeMetadata(metadata, to: finalBackupFolder)

                backupRecord = BackupRecord(
                    id: metadata.id,
                    createdAt: metadata.createdAt,
                    reason: metadata.reason,
                    documentTitle: metadata.documentTitle,
                    sizeBytes: metadata.sizeBytes,
                    backupFolderURL: finalBackupFolder,
                    packageURL: finalPackageURL
                )
            } catch {
                backupError = error
            }
        }

        if let coordinatorError {
            throw coordinatorError
        }
        if let backupError {
            throw backupError
        }
        guard let record = backupRecord else {
            throw BackupError.backupFailed
        }
        return record
    }

    private nonisolated static func readBackupRecord(from folderURL: URL, documentURL: URL) -> BackupRecord? {
        let metadataURL = folderURL.appendingPathComponent(BackupMetadata.filename)
        if let metadata = try? readMetadata(from: metadataURL) {
            let packageURL = folderURL.appendingPathComponent(metadata.originalFileName, isDirectory: true)
            return BackupRecord(
                id: metadata.id,
                createdAt: metadata.createdAt,
                reason: metadata.reason,
                documentTitle: metadata.documentTitle,
                sizeBytes: metadata.sizeBytes,
                backupFolderURL: folderURL,
                packageURL: packageURL
            )
        }

        let packageURL = folderURL.appendingPathComponent(documentURL.lastPathComponent, isDirectory: true)
        let createdAt = (try? folderURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
        let size = directorySize(at: packageURL, fileManager: FileManager.default)
        return BackupRecord(
            id: UUID(),
            createdAt: createdAt,
            reason: .automatic,
            documentTitle: documentURL.deletingPathExtension().lastPathComponent,
            sizeBytes: size,
            backupFolderURL: folderURL,
            packageURL: packageURL
        )
    }

    private nonisolated static func directorySize(at url: URL, fileManager: FileManager) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            total += Int64(values?.fileSize ?? 0)
        }
        return total
    }

    private nonisolated static func writeMetadata(_ metadata: BackupMetadata, to folderURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)
        let metadataURL = folderURL.appendingPathComponent(BackupMetadata.filename)
        try data.write(to: metadataURL, options: [.atomic])
    }

    private nonisolated static func readMetadata(from url: URL) throws -> BackupMetadata {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupMetadata.self, from: data)
    }

    private nonisolated static func backupRootURL(fileManager: FileManager) throws -> URL {
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw BackupError.missingApplicationSupportDirectory
        }
        let rootURL = baseURL.appendingPathComponent("Manuscript", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)
        if !fileManager.fileExists(atPath: rootURL.path) {
            try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        }
        return rootURL
    }

    private nonisolated static func documentIdentifier(for documentURL: URL) -> String {
        let baseName = documentURL.deletingPathExtension().lastPathComponent
        let sanitized = baseName.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "-", options: .regularExpression)
        let hash = SHA256.hash(data: Data(documentURL.path.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
            .prefix(8)
        return "\(sanitized)-\(hash)"
    }

    private nonisolated static func timestampString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }

    private nonisolated static func appVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

struct BackupRecord: Identifiable {
    let id: UUID
    let createdAt: Date
    let reason: BackupReason
    let documentTitle: String
    let sizeBytes: Int64
    let backupFolderURL: URL
    let packageURL: URL
}

enum BackupReason: String, Codable {
    case manual
    case automatic
    case background
}

struct BackupMetadata: Codable {
    static let filename = "backup.json"

    let id: UUID
    let createdAt: Date
    let reason: BackupReason
    let originalFileName: String
    let originalPath: String
    let documentTitle: String
    let sizeBytes: Int64
    let appVersion: String
}

enum BackupError: LocalizedError {
    case missingApplicationSupportDirectory
    case backupFailed

    var errorDescription: String? {
        switch self {
        case .missingApplicationSupportDirectory:
            return "Unable to access the application support folder."
        case .backupFailed:
            return "Backup failed. Please try again."
        }
    }
}
