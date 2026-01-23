import SwiftUI

struct TemplatesSection: View {
    let onSelectTemplate: (BookTemplate?) -> Void
    
    var body: some View {
#if os(macOS)
        Section {
            ForEach(BookTemplate.templates) { template in
                Button {
                    onSelectTemplate(template)
                } label: {
                    Label(template.name, systemImage: template.name == "Heros Journey" ? "figure.walk.motion" : "heart.fill")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            
            Button {
                onSelectTemplate(nil)
            } label: {
                Label("Blank Book", systemImage: "plus")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        } header: {
            Text("Templates")
        }
#else
        VStack(alignment: .leading, spacing: 4) {
            Text("Story Templates")
                .font(.headline)
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
            
            LazyVGrid(columns: columns, spacing: 12) {
                Button {
                    onSelectTemplate(nil)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 120)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "plus.square.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                                
                                Text("Start Fresh")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        Text("Blank Book")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.background)
                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
                
                ForEach(BookTemplate.templates) { template in
                    Button {
                        onSelectTemplate(template)
                    } label: {
                        TemplateCardView(template: template)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
#endif
    }
}

#if DEBUG
#Preview {
    List {
        TemplatesSection(onSelectTemplate: { _ in })
    }
}
#endif 
