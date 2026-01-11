import SwiftUI

struct EmptyLibraryContentView: View {
    let onAddBook: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Your library is empty")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Button(action: onAddBook) {
                Label("Add Your First Book", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    EmptyLibraryContentView(onAddBook: {})
}
#endif 