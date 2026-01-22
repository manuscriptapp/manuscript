//
//  ICloudSyncService.swift
//  Manuscript
//
//  Created by Jonas Dalesjö on 2025-01-22.
//

@preconcurrency import Foundation
import Combine

/// Represents the current iCloud sync status of a file
enum ICloudSyncStatus: Equatable {
    case notInICloud       // Local file, not in iCloud Drive
    case synced            // Fully synced with iCloud
    case uploading         // Currently uploading to iCloud
    case downloading       // Currently downloading from iCloud
    case notDownloaded     // In iCloud but not downloaded locally
    case error(String)     // Sync error occurred

    var iconName: String {
        switch self {
        case .notInICloud:
            return "icloud.slash"
        case .synced:
            return "checkmark.icloud"
        case .uploading:
            return "icloud.and.arrow.up"
        case .downloading:
            return "icloud.and.arrow.down"
        case .notDownloaded:
            return "arrow.down.circle"
        case .error:
            return "exclamationmark.icloud"
        }
    }

    var description: String {
        switch self {
        case .notInICloud:
            return "Not in iCloud"
        case .synced:
            return "Synced with iCloud"
        case .uploading:
            return "Uploading to iCloud..."
        case .downloading:
            return "Downloading from iCloud..."
        case .notDownloaded:
            return "Available in iCloud (not downloaded)"
        case .error(let message):
            return "iCloud Error: \(message)"
        }
    }
}

#if os(macOS)
/// Service that monitors iCloud sync status for a file
@MainActor
final class ICloudSyncService: ObservableObject {
    @Published private(set) var status: ICloudSyncStatus = .notInICloud
    @Published private(set) var isMonitoring = false

    private var monitoredURL: URL?
    private var refreshTimer: Timer?

    deinit {
        refreshTimer?.invalidate()
    }

    /// Start monitoring iCloud sync status for the given file URL
    func startMonitoring(url: URL?) {
        guard let url = url else {
            status = .notInICloud
            return
        }

        // Stop any existing monitoring
        stopMonitoring()

        monitoredURL = url
        isMonitoring = true

        // Check if file is in iCloud Drive
        guard isInICloudDrive(url: url) else {
            status = .notInICloud
            return
        }

        // Check status immediately
        checkStatus()

        // Set up periodic refresh to catch status changes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkStatus()
            }
        }
    }

    /// Stop monitoring iCloud sync status
    func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        monitoredURL = nil
        isMonitoring = false
    }

    /// Check the current sync status
    private func checkStatus() {
        guard let url = monitoredURL else {
            status = .notInICloud
            return
        }

        // Clear cached resource values to get fresh iCloud status
        var freshURL = url
        freshURL.removeCachedResourceValue(forKey: .isUbiquitousItemKey)
        freshURL.removeCachedResourceValue(forKey: .ubiquitousItemIsUploadingKey)
        freshURL.removeCachedResourceValue(forKey: .ubiquitousItemIsDownloadingKey)
        freshURL.removeCachedResourceValue(forKey: .ubiquitousItemDownloadingStatusKey)

        // Use URL resource values to check iCloud status
        do {
            let resourceValues = try freshURL.resourceValues(forKeys: [
                .isUbiquitousItemKey,
                .ubiquitousItemIsUploadingKey,
                .ubiquitousItemIsDownloadingKey,
                .ubiquitousItemUploadingErrorKey,
                .ubiquitousItemDownloadingErrorKey,
                .ubiquitousItemDownloadingStatusKey,
                .ubiquitousItemHasUnresolvedConflictsKey
            ])

            // Check if it's an iCloud item at all
            guard resourceValues.isUbiquitousItem == true else {
                // File exists locally in iCloud Drive path but isn't tracked by iCloud
                // This can happen for newly created files - treat as synced
                if isInICloudDrive(url: url) && FileManager.default.fileExists(atPath: url.path) {
                    status = .synced
                } else {
                    status = .notInICloud
                }
                return
            }

            // Check for conflicts
            if resourceValues.ubiquitousItemHasUnresolvedConflicts == true {
                status = .error("Sync conflict")
                return
            }

            // Check for upload errors
            if let error = resourceValues.ubiquitousItemUploadingError {
                status = .error(error.localizedDescription)
                return
            }

            // Check for download errors
            if let error = resourceValues.ubiquitousItemDownloadingError {
                status = .error(error.localizedDescription)
                return
            }

            // Check if currently uploading
            if resourceValues.ubiquitousItemIsUploading == true {
                status = .uploading
                return
            }

            // Check if currently downloading
            if resourceValues.ubiquitousItemIsDownloading == true {
                status = .downloading
                return
            }

            // Check the download status
            if let downloadingStatus = resourceValues.ubiquitousItemDownloadingStatus {
                if downloadingStatus == .current || downloadingStatus == .downloaded {
                    // File is up to date with iCloud
                    status = .synced
                } else if downloadingStatus == .notDownloaded {
                    // File is in iCloud but not downloaded locally
                    status = .notDownloaded
                } else {
                    // Unknown status, assume synced
                    status = .synced
                }
                return
            }

            // If we have an iCloud item but no specific status, assume synced
            status = .synced

        } catch {
            // If we can't read resource values, check if file is in iCloud path
            if isInICloudDrive(url: url) && FileManager.default.fileExists(atPath: url.path) {
                status = .synced
            } else {
                status = .notInICloud
            }
        }
    }

    /// Check if the URL is within iCloud Drive
    private func isInICloudDrive(url: URL) -> Bool {
        let path = url.path

        // Check common iCloud Drive paths on macOS
        // Mobile Documents is where iCloud Drive stores files
        if path.contains("Library/Mobile Documents") {
            return true
        }

        // Also check for com~apple~CloudDocs (iCloud Drive root)
        if path.contains("com~apple~CloudDocs") {
            return true
        }

        return false
    }
}
#endif
