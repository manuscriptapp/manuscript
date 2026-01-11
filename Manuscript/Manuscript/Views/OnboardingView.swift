import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    let pages: [(title: String, description: String, icon: String)] = [
        ("Welcome to Manuscript", "Your free, open-source writing environment for creating stories, novels, and more.", "doc.text"),
        ("Document-Based Structure", "Every project is saved as a standalone file that's easy to backup and sync with iCloud.", "folder"),
        ("Organize Your Content", "Create folders and documents to organize your writing project just the way you want.", "rectangle.grid.1x2"),
        ("Characters & Locations", "Keep track of your story elements with built-in character and location management.", "person.2.fill"),
        ("Get Started", "Tap the button below to start your writing journey!", "play.fill")
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(
                        title: pages[index].title,
                        description: pages[index].description,
                        icon: pages[index].icon
                    )
                    .tag(index)
                }
            }
            
            if currentPage == pages.count - 1 {
                Button {
                    dismiss()
                } label: {
                    Text("Start Writing")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            } else {
                Button {
                    withAnimation {
                        currentPage = min(currentPage + 1, pages.count - 1)
                    }
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

struct OnboardingPageView: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding()
            
            Text(title)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundColor(.secondary)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
} 
