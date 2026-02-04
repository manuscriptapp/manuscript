import SwiftUI

/// Editor for adding/removing keyword tags
struct KeywordEditorView: View {
    let title: String
    @Binding var keywords: [String]
    var suggestions: [String] = []
    var placeholder: String = "Add keyword"

    @State private var newKeyword: String = ""

    private var availableSuggestions: [String] {
        let existing = Set(keywords.map { $0.lowercased() })
        return suggestions.filter { !existing.contains($0.lowercased()) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField(placeholder, text: $newKeyword)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addKeyword(from: newKeyword)
                    }

                Button("Add") {
                    addKeyword(from: newKeyword)
                }
                .buttonStyle(.bordered)
                .disabled(normalizedKeyword(newKeyword).isEmpty)
            }

            if keywords.isEmpty {
                Text("No keywords")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 6)], alignment: .leading, spacing: 6) {
                    ForEach(keywords, id: \.self) { keyword in
                        keywordChip(keyword)
                    }
                }
            }

            if !availableSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(availableSuggestions, id: \.self) { suggestion in
                            Button {
                                addKeyword(from: suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.15))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func keywordChip(_ keyword: String) -> some View {
        HStack(spacing: 4) {
            Text(keyword)
                .font(.caption)
                .lineLimit(1)

            Button {
                removeKeyword(keyword)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove keyword \(keyword)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.15))
        .cornerRadius(6)
    }

    private func addKeyword(from rawValue: String) {
        let trimmed = normalizedKeyword(rawValue)
        guard !trimmed.isEmpty else { return }

        if keywords.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            newKeyword = ""
            return
        }

        keywords.append(trimmed)
        newKeyword = ""
    }

    private func removeKeyword(_ keyword: String) {
        keywords.removeAll { $0.caseInsensitiveCompare(keyword) == .orderedSame }
    }

    private func normalizedKeyword(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var keywords = ["Action", "Drama"]
    return KeywordEditorView(title: "Keywords", keywords: $keywords, suggestions: ["Action", "Mystery", "Romance"])
        .padding()
}
#endif
