import SwiftUI
import PDFKit
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ExportView: View {
    let document: LiteratiDocument
    @State private var isExporting = false
    @State private var exportError: Error?
    @State private var showShareSheet = false
    @State private var pdfData: Data?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Project")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Export your project in various formats")
                .foregroundStyle(.secondary)
            
            Spacer()
            
            VStack(spacing: 16) {
                ExportButton(
                    title: "Export as PDF",
                    icon: "doc.pdf",
                    isLoading: isExporting
                ) {
                    await exportAsPDF()
                }
            }
            .padding()
            
            if let error = exportError {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(activityItems: [pdfData])
            }
        }
        #endif
    }
    
    private func exportAsPDF() async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            // Create PDF document
            let pdfDocument = PDFDocument()
            
            // Create a title page
            if let titlePage = createTitlePage() {
                pdfDocument.insert(titlePage, at: 0)
            }
            
            // Add content pages
            var pageNumber = 1
            try await addFolderContentToPDF(folder: document.rootFolder, pdfDocument: pdfDocument, startingPage: &pageNumber)
            
            #if os(macOS)
            // Save PDF using NSSavePanel on macOS
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.pdf]
            savePanel.nameFieldStringValue = "\(document.title).pdf"
            
            let response = await savePanel.beginSheetModal(for: NSApp.keyWindow!)
            
            if response == .OK, let url = savePanel.url {
                pdfDocument.write(to: url)
            }
            #else
            // Share PDF using UIActivityViewController on iOS
            if let data = pdfDocument.dataRepresentation() {
                pdfData = data
                showShareSheet = true
            }
            #endif
        } catch {
            exportError = error
        }
    }
    
    private func createTitlePage() -> PDFPage? {
        #if os(iOS)
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let titleString = NSAttributedString(string: document.title, attributes: titleAttributes)
            titleString.draw(at: CGPoint(x: 50, y: 50))
            
            let authorFont = UIFont.systemFont(ofSize: 18)
            let authorAttributes: [NSAttributedString.Key: Any] = [
                .font: authorFont,
                .foregroundColor: UIColor.black
            ]
            let authorString = NSAttributedString(string: "By \(document.author)", attributes: authorAttributes)
            authorString.draw(at: CGPoint(x: 50, y: 100))
        }
        
        return PDFDocument(data: data)?.page(at: 0)
        #else
        let page = PDFPage()
        
        let titleFont = NSFont.systemFont(ofSize: 24, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        
        let titleString = NSAttributedString(string: document.title, attributes: titleAttributes)
        let titleAnnotation = PDFAnnotation(bounds: CGRect(x: 50, y: 700, width: 500, height: 50), forType: .freeText, withProperties: nil)
        titleAnnotation.contents = document.title
        titleAnnotation.font = titleFont
        titleAnnotation.color = NSColor.black
        page.addAnnotation(titleAnnotation)
        
        let authorFont = NSFont.systemFont(ofSize: 18)
        let authorAttributes: [NSAttributedString.Key: Any] = [
            .font: authorFont,
            .foregroundColor: NSColor.black
        ]
        let authorString = NSAttributedString(string: "By \(document.author)", attributes: authorAttributes)
        let authorAnnotation = PDFAnnotation(bounds: CGRect(x: 50, y: 650, width: 500, height: 50), forType: .freeText, withProperties: nil)
        authorAnnotation.contents = "By \(document.author)"
        authorAnnotation.font = authorFont
        authorAnnotation.color = NSColor.black
        page.addAnnotation(authorAnnotation)
        
        return page
        #endif
    }
    
    private func addFolderContentToPDF(folder: LiteratiFolder, pdfDocument: PDFDocument, startingPage: inout Int) async throws {
        // Add documents in this folder
        for document in folder.documents.sorted(by: { $0.order < $1.order }) {
            if let page = createContentPage(for: document) {
                pdfDocument.insert(page, at: startingPage)
                startingPage += 1
            }
        }
        
        // Recursively add content from subfolders
        for subfolder in folder.subfolders.sorted(by: { $0.order < $1.order }) {
            try await addFolderContentToPDF(folder: subfolder, pdfDocument: pdfDocument, startingPage: &startingPage)
        }
    }
    
    private func createContentPage(for document: LiteratiDocument.Document) -> PDFPage? {
        #if os(iOS)
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let titleString = NSAttributedString(string: document.title, attributes: titleAttributes)
            titleString.draw(at: CGPoint(x: 50, y: 50))
            
            let contentFont = UIFont.systemFont(ofSize: 12)
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: contentFont,
                .foregroundColor: UIColor.black
            ]
            
            let contentString = NSAttributedString(string: document.content, attributes: contentAttributes)
            contentString.draw(at: CGPoint(x: 50, y: 100))
        }
        
        return PDFDocument(data: data)?.page(at: 0)
        #else
        let page = PDFPage()
        
        let titleFont = NSFont.systemFont(ofSize: 18, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        
        let titleAnnotation = PDFAnnotation(bounds: CGRect(x: 50, y: 700, width: 500, height: 50), forType: .freeText, withProperties: nil)
        titleAnnotation.contents = document.title
        titleAnnotation.font = titleFont
        titleAnnotation.color = NSColor.black
        page.addAnnotation(titleAnnotation)
        
        let contentFont = NSFont.systemFont(ofSize: 12)
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .foregroundColor: NSColor.black
        ]
        
        let contentAnnotation = PDFAnnotation(bounds: CGRect(x: 50, y: 50, width: 500, height: 600), forType: .freeText, withProperties: nil)
        contentAnnotation.contents = document.content
        contentAnnotation.font = contentFont
        contentAnnotation.color = NSColor.black
        page.addAnnotation(contentAnnotation)
        
        return page
        #endif
    }
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

struct ExportButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(isLoading)
    }
}

#if DEBUG
#Preview {
    let document = LiteratiDocument()
    document.title = "Sample Project"
    document.author = "Sample Author"
    return ExportView(document: document)
}
#endif 