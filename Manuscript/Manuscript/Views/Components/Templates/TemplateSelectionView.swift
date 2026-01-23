import SwiftUI

struct TemplateCard: View {
    let template: BookTemplate?
    let isSelected: Bool
    
    private var symbol: String {
        switch template?.name {
        case "Heros Journey":
            return "figure.walk.motion"
        case "Romance Outline":
            return "heart.fill"
        // Add more cases for future templates
        default:
            return "doc.badge.plus"
        }
    }
    
    private var gradient: LinearGradient {
        switch template?.name {
        case "Heros Journey":
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
        default:
            return LinearGradient(
                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Template icon with background
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Template info
            VStack(alignment: .leading, spacing: 6) {
                Text(template?.name ?? "No Template")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if let description = template?.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Start with a blank book without any predefined structure")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Selection indicator
            VStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? .white : .clear, lineWidth: 2)
        )
        .shadow(color: isSelected ? .black.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
    }
}

struct TemplateSelectionView: View {
    @Binding var selectedTemplate: BookTemplate?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a Template")
                .font(.title2)
                .bold()
            
            VStack(spacing: 12) {
                Button {
                    selectedTemplate = nil
                } label: {
                    TemplateCard(template: nil, isSelected: selectedTemplate == nil)
                }
                .buttonStyle(.plain)
                
                ForEach(BookTemplate.templates) { template in
                    Button {
                        selectedTemplate = template
                    } label: {
                        TemplateCard(template: template, isSelected: selectedTemplate == template)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    VStack {
        TemplateSelectionView(selectedTemplate: .constant(BookTemplate.heroJourney))
            .padding()
    }
    .frame(maxHeight: .infinity)
} 
