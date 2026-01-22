import SwiftUI

/// Sheet view for editing writing targets
struct WritingTargetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var targets: ManuscriptTargets?

    // Local state for editing
    @State private var draftWordCount: String = ""
    @State private var hasDraftTarget: Bool = false
    @State private var draftDeadline: Date = Date()
    @State private var hasDeadline: Bool = false
    @State private var deadlineIgnored: Bool = false
    @State private var countIncludedOnly: Bool = true

    @State private var sessionWordCount: String = ""
    @State private var hasSessionTarget: Bool = false
    @State private var sessionResetType: SessionResetType = .midnight
    @State private var sessionResetTime: Date = Calendar.current.startOfDay(for: Date())
    @State private var allowNegatives: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                draftTargetSection
                sessionTargetSection
            }
            .navigationTitle("Writing Targets")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTargets()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentTargets()
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }

    // MARK: - Draft Target Section

    private var draftTargetSection: some View {
        Section {
            Toggle("Enable Draft Target", isOn: $hasDraftTarget)

            if hasDraftTarget {
                HStack {
                    Text("Word Count Goal")
                    Spacer()
                    TextField("60000", text: $draftWordCount)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }

                Toggle("Count Included Documents Only", isOn: $countIncludedOnly)

                Divider()

                Toggle("Set Deadline", isOn: $hasDeadline)

                if hasDeadline {
                    DatePicker(
                        "Deadline",
                        selection: $draftDeadline,
                        displayedComponents: [.date]
                    )

                    Toggle("Ignore Deadline", isOn: $deadlineIgnored)
                        .foregroundColor(deadlineIgnored ? .secondary : .primary)
                }
            }
        } header: {
            Label("Draft Target", systemImage: "doc.text")
        } footer: {
            if hasDraftTarget {
                Text("Set a total word count goal for your entire manuscript.")
            }
        }
    }

    // MARK: - Session Target Section

    private var sessionTargetSection: some View {
        Section {
            Toggle("Enable Session Target", isOn: $hasSessionTarget)

            if hasSessionTarget {
                HStack {
                    Text("Daily Word Count")
                    Spacer()
                    TextField("200", text: $sessionWordCount)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }

                Picker("Reset Type", selection: $sessionResetType) {
                    Text("At Midnight").tag(SessionResetType.midnight)
                    Text("At Specific Time").tag(SessionResetType.time)
                }

                if sessionResetType == .time {
                    DatePicker(
                        "Reset Time",
                        selection: $sessionResetTime,
                        displayedComponents: [.hourAndMinute]
                    )
                }

                Toggle("Allow Negative Progress", isOn: $allowNegatives)
            }
        } header: {
            Label("Session Target", systemImage: "clock")
        } footer: {
            if hasSessionTarget {
                Text("Set a daily writing goal that resets each day.")
            }
        }
    }

    // MARK: - Data Management

    private func loadCurrentTargets() {
        guard let targets = targets else {
            // Set defaults for new targets
            draftDeadline = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            return
        }

        if let draftCount = targets.draftWordCount {
            hasDraftTarget = true
            draftWordCount = String(draftCount)
        }

        if let deadline = targets.draftDeadline {
            hasDeadline = true
            draftDeadline = deadline
        }

        deadlineIgnored = targets.draftDeadlineIgnored
        countIncludedOnly = targets.draftCountIncludedOnly

        if let sessionCount = targets.sessionWordCount {
            hasSessionTarget = true
            sessionWordCount = String(sessionCount)
        }

        sessionResetType = targets.sessionResetType
        allowNegatives = targets.sessionAllowNegatives

        if let resetTimeStr = targets.sessionResetTime {
            sessionResetTime = parseTimeString(resetTimeStr)
        }
    }

    private func saveTargets() {
        let draftCount = hasDraftTarget ? Int(draftWordCount) : nil
        let sessionCount = hasSessionTarget ? Int(sessionWordCount) : nil
        let deadline = (hasDraftTarget && hasDeadline) ? draftDeadline : nil

        let resetTimeStr: String?
        if hasSessionTarget && sessionResetType == .time {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            resetTimeStr = formatter.string(from: sessionResetTime)
        } else {
            resetTimeStr = nil
        }

        targets = ManuscriptTargets(
            draftWordCount: draftCount,
            draftDeadline: deadline,
            draftDeadlineIgnored: deadlineIgnored,
            draftCountIncludedOnly: countIncludedOnly,
            sessionWordCount: sessionCount,
            sessionResetType: sessionResetType,
            sessionResetTime: resetTimeStr,
            sessionAllowNegatives: allowNegatives
        )
    }

    private func parseTimeString(_ timeStr: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeStr) {
            // Combine with today's date
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return calendar.date(bySettingHour: components.hour ?? 0,
                               minute: components.minute ?? 0,
                               second: 0,
                               of: Date()) ?? Date()
        }
        return Calendar.current.startOfDay(for: Date())
    }
}

#Preview {
    WritingTargetEditorView(
        targets: .constant(ManuscriptTargets(
            draftWordCount: 60000,
            draftDeadline: Date(),
            sessionWordCount: 200
        ))
    )
}

#Preview("New Targets") {
    WritingTargetEditorView(targets: .constant(nil))
}
