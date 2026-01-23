import SwiftUI

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
    var canApply: Bool = false
}

// MARK: - Chat Bubble View

struct ChatBubbleView: View {
    let message: ChatMessage

    /// Warm brown color for user messages
    private var warmBrown: Color {
        Color(red: 0.55, green: 0.4, blue: 0.3)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
            } else {
                // AI avatar
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(warmBrown)
                    .frame(width: 24, height: 24)
                    .background(warmBrown.opacity(0.15))
                    .clipShape(Circle())
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(message.isUser ? warmBrown : Color.primary.opacity(0.08))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)

            if message.isUser {
                // User avatar
                Image(systemName: "person.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 24, height: 24)
                    .background(warmBrown.opacity(0.8))
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 40)
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
