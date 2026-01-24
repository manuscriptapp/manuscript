import Foundation
import Combine

/// Service responsible for managing automatic document backups (snapshots)
@MainActor
class BackupService: ObservableObject {
    static let shared = BackupService()

    // MARK: - Published State

    /// Whether auto-backup is currently active
    @Published private(set) var isActive: Bool = false

    /// Last backup timestamp for the current document
    @Published private(set) var lastBackupDate: Date?

    // MARK: - Configuration

    /// Default backup interval in seconds (5 minutes)
    static let defaultInterval: Int = 300

    /// Minimum backup interval in seconds (1 minute)
    static let minimumInterval: Int = 60

    /// Maximum number of auto-backups to keep per document
    static let defaultMaxAutoBackups: Int = 10

    // MARK: - Private State

    private var timer: Timer?
    private var currentDocumentId: UUID?
    private var backupAction: ((UUID) -> Void)?
    private var lastContentHash: Int?
    private var pendingContentHash: Int?

    private init() {}

    // MARK: - Public API

    /// Start automatic backup monitoring for a document
    /// - Parameters:
    ///   - documentId: The document to monitor
    ///   - interval: Backup interval in seconds
    ///   - action: Closure called when backup should be performed
    func startMonitoring(
        documentId: UUID,
        interval: Int,
        action: @escaping (UUID) -> Void
    ) {
        // Stop any existing monitoring
        stopMonitoring()

        guard interval >= Self.minimumInterval else { return }

        currentDocumentId = documentId
        backupAction = action
        isActive = true

        // Schedule periodic backup checks
        timer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(interval),
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.performBackupIfNeeded()
            }
        }

        // Add to run loop for background execution
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Stop automatic backup monitoring
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        currentDocumentId = nil
        backupAction = nil
        isActive = false
        lastContentHash = pendingContentHash
        pendingContentHash = nil
    }

    /// Notify the service that content has changed
    /// - Parameter contentHash: Hash of the current content for change detection
    func contentDidChange(contentHash: Int) {
        pendingContentHash = contentHash
    }

    /// Manually trigger a backup check (e.g., when user pauses typing)
    func checkForBackup() {
        performBackupIfNeeded()
    }

    /// Record that a backup was just performed
    func recordBackup() {
        lastBackupDate = Date()
        lastContentHash = pendingContentHash
    }

    // MARK: - Private Methods

    private func performBackupIfNeeded() {
        guard let documentId = currentDocumentId,
              let action = backupAction else { return }

        // Only backup if content has changed since last backup
        if let pendingHash = pendingContentHash,
           pendingHash != lastContentHash {
            action(documentId)
        }
    }
}

// MARK: - Backup Settings

/// Settings for automatic backup behavior (stored per-project)
struct BackupSettings: Codable, Equatable {
    /// Whether automatic backups are enabled
    var autoBackupEnabled: Bool

    /// Interval between automatic backups in seconds
    var backupInterval: Int

    /// Maximum number of automatic backups to keep per document
    var maxAutoBackupsPerDocument: Int

    /// Number of days to retain automatic backups (0 = forever)
    var retentionDays: Int

    init(
        autoBackupEnabled: Bool = true,
        backupInterval: Int = BackupService.defaultInterval,
        maxAutoBackupsPerDocument: Int = BackupService.defaultMaxAutoBackups,
        retentionDays: Int = 30
    ) {
        self.autoBackupEnabled = autoBackupEnabled
        self.backupInterval = max(backupInterval, BackupService.minimumInterval)
        self.maxAutoBackupsPerDocument = max(1, maxAutoBackupsPerDocument)
        self.retentionDays = max(0, retentionDays)
    }

    // Custom decoder for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        autoBackupEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoBackupEnabled) ?? true
        backupInterval = try container.decodeIfPresent(Int.self, forKey: .backupInterval) ?? BackupService.defaultInterval
        maxAutoBackupsPerDocument = try container.decodeIfPresent(Int.self, forKey: .maxAutoBackupsPerDocument) ?? BackupService.defaultMaxAutoBackups
        retentionDays = try container.decodeIfPresent(Int.self, forKey: .retentionDays) ?? 30
    }
}

// MARK: - Backup Interval Options

enum BackupIntervalOption: Int, CaseIterable, Identifiable {
    case oneMinute = 60
    case twoMinutes = 120
    case fiveMinutes = 300
    case tenMinutes = 600
    case fifteenMinutes = 900
    case thirtyMinutes = 1800

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .oneMinute: return "1 minute"
        case .twoMinutes: return "2 minutes"
        case .fiveMinutes: return "5 minutes"
        case .tenMinutes: return "10 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        }
    }
}

// MARK: - Retention Options

enum BackupRetentionOption: Int, CaseIterable, Identifiable {
    case sevenDays = 7
    case fourteenDays = 14
    case thirtyDays = 30
    case sixtyDays = 60
    case ninetyDays = 90
    case forever = 0

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .sevenDays: return "7 days"
        case .fourteenDays: return "14 days"
        case .thirtyDays: return "30 days"
        case .sixtyDays: return "60 days"
        case .ninetyDays: return "90 days"
        case .forever: return "Forever"
        }
    }
}
