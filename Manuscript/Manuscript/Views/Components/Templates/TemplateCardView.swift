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

    private var gradient: LinearGradient {
        switch template.name {
        case "Hero's Journey":
            return LinearGradient(
                colors: [.brown.opacity(0.8), Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Romance Outline":
            return LinearGradient(
                colors: [.pink.opacity(0.8), .red.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Save the Cat":
            return LinearGradient(
                colors: [.orange.opacity(0.8), .yellow.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Three-Act Structure":
            return LinearGradient(
                colors: [.blue.opacity(0.8), .cyan.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Story Circle":
            return LinearGradient(
                colors: [.purple.opacity(0.8), .pink.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Seven-Point Structure":
            return LinearGradient(
                colors: [.green.opacity(0.8), .mint.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Freytag's Pyramid":
            return LinearGradient(
                colors: [.indigo.opacity(0.8), .purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Fichtean Curve":
            return LinearGradient(
                colors: [.red.opacity(0.8), .orange.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Kishōtenketsu":
            return LinearGradient(
                colors: [.teal.opacity(0.8), .green.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradient)
                    .frame(height: 120)
                
                VStack(spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                    
                    VStack(spacing: 2) {
                        Text("\(actCount) acts")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                        Text("\(documentCount) chapters")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
            
            Text(template.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding(.horizontal, 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
    }
}

#if DEBUG
#Preview {
    TemplateCardView(template: BookTemplate.templates[0])
}
#endif 