import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Main view for displaying and managing writing targets
struct WritingTargetsView: View {
    @Binding var targets: ManuscriptTargets?
    let currentDraftWords: Int
    let currentSessionWords: Int
    @State private var showingEditor = false

    private var hasTargets: Bool {
        guard let targets = targets else { return false }
        return targets.draftWordCount != nil || targets.sessionWordCount != nil
    }

    var body: some View {
        VStack(spacing: 20) {
            if hasTargets {
                targetsContent
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showingEditor) {
            WritingTargetEditorView(targets: $targets)
        }
    }

    // MARK: - Targets Content

    private var targetsContent: some View {
        VStack(spacing: 24) {
            // Header with edit button
            HStack {
                Text("Writing Targets")
                    .font(.headline)
                Spacer()
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }

            // Progress indicators
            HStack(spacing: 32) {
                if let draftTarget = targets?.draftWordCount {
                    WritingTargetProgressView(
                        title: "Draft",
                        currentWords: currentDraftWords,
                        targetWords: draftTarget,
                        style: .circular
                    )
                }

                if let sessionTarget = targets?.sessionWordCount {
                    WritingTargetProgressView(
                        title: "Session",
                        currentWords: currentSessionWords,
                        targetWords: sessionTarget,
                        style: .circular
                    )
                }
            }

            // Deadline section
            if let deadline = targets?.draftDeadline,
               targets?.draftDeadlineIgnored != true {
                deadlineSection(deadline: deadline)
            }

            // Session reset info
            if targets?.sessionWordCount != nil {
                sessionResetInfo
            }
        }
        .padding()
        .background(secondaryBackgroundColor)
        .cornerRadius(12)
    }

    // MARK: - Platform Colors

    private var secondaryBackgroundColor: Color {
        #if os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }

    private var tertiaryBackgroundColor: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.tertiarySystemBackground)
        #endif
    }

    // MARK: - Deadline Section

    private func deadlineSection(deadline: Date) -> some View {
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0

        return HStack {
            Image(systemName: "calendar")
                .foregroundColor(daysRemaining < 7 ? .red : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Deadline")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(deadline, style: .date)
                    .font(.subheadline)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(daysRemaining >= 0 ? "Days left" : "Overdue")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(abs(daysRemaining))")
                    .font(.title3.bold())
                    .foregroundColor(daysRemaining < 7 ? .red : (daysRemaining < 30 ? .orange : .primary))
            }
        }
        .padding()
        .background(tertiaryBackgroundColor)
        .cornerRadius(8)
    }

    // MARK: - Session Reset Info

    private var sessionResetInfo: some View {
        HStack {
            Image(systemName: "arrow.clockwise")
                .foregroundColor(.secondary)

            Text(sessionResetText)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var sessionResetText: String {
        guard let targets = targets else { return "" }

        switch targets.sessionResetType {
        case .time:
            if let resetTime = targets.sessionResetTime {
                return "Session resets daily at \(resetTime)"
            }
            return "Session resets daily"
        case .midnight:
            return "Session resets at midnight"
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Writing Targets")
                .font(.headline)

            Text("Set word count goals to track your progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingEditor = true
            } label: {
                Label("Set Targets", systemImage: "plus")
            }
            .manuscriptPrimaryButton()
            .padding(.top, 8)
        }
        .padding()
    }
}

/// Compact view for displaying targets in sidebar
struct CompactWritingTargetsView: View {
    let targets: ManuscriptTargets?
    let currentDraftWords: Int
    let currentSessionWords: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let draftTarget = targets?.draftWordCount {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    CompactTargetProgressView(
                        currentWords: currentDraftWords,
                        targetWords: draftTarget
                    )
                }
            }

            if let sessionTarget = targets?.sessionWordCount {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    CompactTargetProgressView(
                        currentWords: currentSessionWords,
                        targetWords: sessionTarget
                    )
                }
            }
        }
    }
}

#Preview {
    WritingTargetsView(
        targets: .constant(ManuscriptTargets(
            draftWordCount: 60000,
            draftDeadline: Calendar.current.date(byAdding: .day, value: 45, to: Date()),
            draftDeadlineIgnored: false,
            draftCountIncludedOnly: true,
            sessionWordCount: 200,
            sessionResetType: .time,
            sessionResetTime: "00:00",
            sessionAllowNegatives: false
        )),
        currentDraftWords: 15000,
        currentSessionWords: 150
    )
    .padding()
}

#Preview("Empty State") {
    WritingTargetsView(
        targets: .constant(nil),
        currentDraftWords: 0,
        currentSessionWords: 0
    )
    .padding()
}
