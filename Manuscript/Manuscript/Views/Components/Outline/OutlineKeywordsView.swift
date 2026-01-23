import SwiftUI

/// Keywords display for the outline view
struct OutlineKeywordsView: View {
    let keywords: [String]

    var body: some View {
        if keywords.isEmpty {
            Text("—")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(keywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        OutlineKeywordsView(keywords: [])
        OutlineKeywordsView(keywords: ["Action", "Drama"])
        OutlineKeywordsView(keywords: ["One", "Two", "Three", "Four", "Five"])
    }
    .padding()
}
#endif
