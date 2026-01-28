import SwiftUI
import PDFKit

/// A view that displays a PDF document with page navigation
struct PDFPreviewView: View {
    let mediaItem: ManuscriptDocument.MediaItem
    @ObservedObject var assetManager: AssetManager

    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 1

    var body: some View {
        VStack(spacing: 0) {
            if let url = assetManager.assetURL(for: mediaItem) {
                PDFKitView(url: url, currentPage: $currentPage, totalPages: $totalPages)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Unable to load PDF")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Page navigation bar
            if totalPages > 1 {
                HStack(spacing: 16) {
                    Button {
                        goToPreviousPage()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentPage <= 1)

                    Text("Page \(currentPage) of \(totalPages)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        goToNextPage()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentPage >= totalPages)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color(white: 0.15))
            }
        }
        .background(Color(white: 0.1))
    }

    private func goToPreviousPage() {
        if currentPage > 1 {
            currentPage -= 1
        }
    }

    private func goToNextPage() {
        if currentPage < totalPages {
            currentPage += 1
        }
    }
}

/// UIViewRepresentable/NSViewRepresentable wrapper for PDFView
#if canImport(AppKit)
struct PDFKitView: NSViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = NSColor(white: 0.1, alpha: 1.0)

        if let document = PDFDocument(url: url) {
            pdfView.document = document
            DispatchQueue.main.async {
                totalPages = document.pageCount
            }
        }

        // Observe page changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        guard let document = pdfView.document else { return }

        // Navigate to page if currentPage changed externally
        if let page = document.page(at: currentPage - 1),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage)
    }

    class Coordinator: NSObject {
        @Binding var currentPage: Int

        init(currentPage: Binding<Int>) {
            _currentPage = currentPage
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPDFPage = pdfView.currentPage,
                  let document = pdfView.document else { return }

            let pageIndex = document.index(for: currentPDFPage)

            DispatchQueue.main.async {
                self.currentPage = pageIndex + 1
            }
        }
    }
}
#else
struct PDFKitView: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)

        if let document = PDFDocument(url: url) {
            pdfView.document = document
            DispatchQueue.main.async {
                totalPages = document.pageCount
            }
        }

        // Observe page changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        guard let document = pdfView.document else { return }

        // Navigate to page if currentPage changed externally
        if let page = document.page(at: currentPage - 1),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage)
    }

    class Coordinator: NSObject {
        @Binding var currentPage: Int

        init(currentPage: Binding<Int>) {
            _currentPage = currentPage
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPDFPage = pdfView.currentPage,
                  let document = pdfView.document else { return }

            let pageIndex = document.index(for: currentPDFPage)

            DispatchQueue.main.async {
                self.currentPage = pageIndex + 1
            }
        }
    }
}
#endif

#if DEBUG
#Preview {
    PDFPreviewView(
        mediaItem: ManuscriptDocument.MediaItem(
            title: "Test PDF",
            mediaType: .pdf,
            filename: "test.pdf",
            originalFilename: "test.pdf"
        ),
        assetManager: AssetManager()
    )
}
#endif
