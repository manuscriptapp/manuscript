import SwiftUI

struct TemplateCardView: View {
    let template: BookTemplate

    private var documentCount: Int {
        func countDocuments(in folder: FolderTemplate) -> Int {
            let documentsInFolder = folder.documents.count
            let documentsInSubfolders = folder.subfolders.reduce(0) { count, subfolder in
                count + countDocuments(in: subfolder)
            }
            return documentsInFolder + documentsInSubfolders
        }
        return countDocuments(in: template.structure)
    }

    private var actCount: Int {
        template.structure.subfolders.count
    }

    private var symbol: String {
        switch template.name {
        case "Hero's Journey":
            return "figure.walk.motion"
        case "Romance Outline":
            return "heart.fill"
        case "Save the Cat":
            return "cat.fill"
        case "Three-Act Structure":
            return "rectangle.split.3x1.fill"
        case "Story Circle":
            return "circle.dashed"
        case "Seven-Point Structure":
            return "7.circle.fill"
        case "Freytag's Pyramid":
            return "triangle.fill"
        case "Fichtean Curve":
            return "waveform.path.ecg"
        case "Kishōtenketsu":
            return "square.grid.2x2.fill"
        default:
            return "doc.badge.plus"
        }
    }

    private var bookColor: Color {
        switch template.name {
        case "Hero's Journey":
            return Color(red: 0.55, green: 0.35, blue: 0.2)
        case "Romance Outline":
            return Color(red: 0.85, green: 0.3, blue: 0.4)
        case "Save the Cat":
            return Color(red: 0.95, green: 0.6, blue: 0.2)
        case "Three-Act Structure":
            return Color(red: 0.25, green: 0.5, blue: 0.75)
        case "Story Circle":
            return Color(red: 0.6, green: 0.35, blue: 0.65)
        case "Seven-Point Structure":
            return Color(red: 0.25, green: 0.6, blue: 0.5)
        case "Freytag's Pyramid":
            return Color(red: 0.45, green: 0.35, blue: 0.7)
        case "Fichtean Curve":
            return Color(red: 0.8, green: 0.35, blue: 0.3)
        case "Kishōtenketsu":
            return Color(red: 0.3, green: 0.55, blue: 0.55)
        default:
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Main cover
            RoundedRectangle(cornerRadius: 3)
                .fill(bookColor)

            // Spine edge effect
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.black.opacity(0.15))
                    .frame(width: 6)
                Spacer()
            }

            // Content on cover
            VStack(alignment: .leading, spacing: 6) {
                Spacer()

                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.white.opacity(0.6))

                Text(template.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(actCount) acts · \(documentCount) scenes")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .padding(.vertical, 10)
        }
        .aspectRatio(0.7, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 2)
    }
}

#if DEBUG
#Preview {
    HStack {
        TemplateCardView(template: BookTemplate.templates[0])
            .frame(width: 140)
        TemplateCardView(template: BookTemplate.templates[1])
            .frame(width: 140)
    }
    .padding()
}
#endif
