//
//  ICloudSyncStatusView.swift
//  Manuscript
//
//  Created by Jonas Dalesjö on 2025-01-22.
//

import SwiftUI

#if os(macOS)
/// A toolbar view that displays the current iCloud sync status
struct ICloudSyncStatusView: View {
    @ObservedObject var syncService: ICloudSyncService

    var body: some View {
        Image(systemName: syncService.status.iconName)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(iconColor)
            .symbolEffect(.pulse, options: .repeating, isActive: isPulsing)
            .help(syncService.status.description)
    }

    private var iconColor: Color {
        switch syncService.status {
        case .notInICloud:
            return .secondary
        case .synced:
            return .green
        case .uploading, .downloading, .notDownloaded:
            return .blue
        case .error:
            return .red
        }
    }

    private var isPulsing: Bool {
        switch syncService.status {
        case .uploading, .downloading:
            return true
        default:
            return false
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        // Preview requires a mock or real service instance
        Text("iCloud Status Preview")
    }
    .padding()
}
#endif
