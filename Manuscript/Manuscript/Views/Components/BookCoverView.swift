import SwiftUI

struct BookCoverView: View {
    let book: Book
    
    var body: some View {
        ZStack {
            // Book cover background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 60, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            
            VStack(spacing: 4) {
                // Book icon
                Image(systemName: "book.closed")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentColor.opacity(0.8))
                    .padding(.bottom, 4)
                
                // Book title preview (first few characters)
                Text(book.title.prefix(3) + "...")
                    .font(.system(size: 10))
                    .foregroundColor(.accentColor.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
        }
    }
}

#if DEBUG
struct BookCoverView_Previews: PreviewProvider {
    static var previews: some View {
        let mockBook = Book(title: "Sample Book", author: "John Doe")
        BookCoverView(book: mockBook)
    }
}
#endif 
