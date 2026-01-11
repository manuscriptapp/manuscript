import SwiftUI

struct EmptyLibraryView: View {
    let onAddBook: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("Your library is empty")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            Button(action: onAddBook) {
                Label("Add Your First Book", systemImage: "plus.circle.fill")
                    .font(.callout)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
    }
}

#if DEBUG
#Preview {
    EmptyLibraryView(onAddBook: {})
}
#endif 