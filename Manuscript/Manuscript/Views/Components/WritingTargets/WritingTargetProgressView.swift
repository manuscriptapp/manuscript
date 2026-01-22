import SwiftUI

/// Reusable progress indicator for writing targets
struct WritingTargetProgressView: View {
    let title: String
    let currentWords: Int
    let targetWords: Int
    let style: ProgressStyle

    enum ProgressStyle {
        case circular
        case linear
    }

    private var progress: Double {
        guard targetWords > 0 else { return 0 }
        return min(Double(currentWords) / Double(targetWords), 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    private var progressColor: Color {
        switch percentage {
        case 0..<25:
            return Color(red: 0.9, green: 0.45, blue: 0.45)  // Soft coral
        case 25..<75:
            return Color(red: 0.9, green: 0.7, blue: 0.4)    // Soft amber
        default:
            return Color(red: 0.4, green: 0.75, blue: 0.65)  // Soft teal
        }
    }

    private var wordCountText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let current = formatter.string(from: NSNumber(value: currentWords)) ?? "\(currentWords)"
        let target = formatter.string(from: NSNumber(value: targetWords)) ?? "\(targetWords)"
        return "\(current) / \(target)"
    }

    var body: some View {
        switch style {
        case .circular:
            circularProgress
        case .linear:
            linearProgress
        }
    }

    // MARK: - Circular Progress

    private var circularProgress: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(progressColor.opacity(0.2), lineWidth: 8)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                // Center content
                VStack(spacing: 2) {
                    Text("\(percentage)%")
                        .font(.title2.bold())
                        .foregroundColor(progressColor)
                    Text(wordCountText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Linear Progress

    private var linearProgress: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(percentage)%")
                    .font(.subheadline.bold())
                    .foregroundColor(progressColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor.opacity(0.2))

                    // Progress bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)

            Text(wordCountText + " words")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Compact progress indicator for inline display
struct CompactTargetProgressView: View {
    let currentWords: Int
    let targetWords: Int

    private var progress: Double {
        guard targetWords > 0 else { return 0 }
        return min(Double(currentWords) / Double(targetWords), 1.0)
    }

    private var progressColor: Color {
        let percentage = Int(progress * 100)
        switch percentage {
        case 0..<25:
            return Color(red: 0.9, green: 0.45, blue: 0.45)  // Soft coral
        case 25..<75:
            return Color(red: 0.9, green: 0.7, blue: 0.4)    // Soft amber
        default:
            return Color(red: 0.4, green: 0.75, blue: 0.65)  // Soft teal
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(progressColor.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 20, height: 20)

            Text("\(currentWords)/\(targetWords)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview("Circular Progress") {
    HStack(spacing: 40) {
        WritingTargetProgressView(
            title: "Draft",
            currentWords: 15000,
            targetWords: 60000,
            style: .circular
        )
        WritingTargetProgressView(
            title: "Session",
            currentWords: 150,
            targetWords: 200,
            style: .circular
        )
    }
    .padding()
}

#Preview("Linear Progress") {
    VStack(spacing: 20) {
        WritingTargetProgressView(
            title: "Draft Progress",
            currentWords: 45000,
            targetWords: 60000,
            style: .linear
        )
        WritingTargetProgressView(
            title: "Session Progress",
            currentWords: 50,
            targetWords: 200,
            style: .linear
        )
    }
    .padding()
    .frame(width: 300)
}
