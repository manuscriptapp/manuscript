import SwiftUI

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
                .tint(.accent)
        }
    }
} 