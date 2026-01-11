import SwiftUI

struct HowItWorksView: View {
    @State private var showOnboarding = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                OnboardingView()
                    .padding()
                    .frame(minHeight: geometry.size.height)
            }
        }
        .navigationTitle("How It Works")
    }
}

#Preview {
    NavigationStack {
        HowItWorksView()
    }
} 
