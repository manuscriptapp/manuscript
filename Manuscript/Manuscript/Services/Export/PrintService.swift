//
//  PrintService.swift
//  Manuscript
//
//  Print service for sending compiled manuscripts to system print dialogs.
//

import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
import PDFKit
#endif

enum PrintError: LocalizedError {
    case printingUnavailable
    case pdfGenerationFailed
    case printFailed(Error)

    var errorDescription: String? {
        switch self {
        case .printingUnavailable:
            return "Printing is not available"
        case .pdfGenerationFailed:
            return "Failed to generate PDF for printing"
        case .printFailed(let error):
            return "Print failed: \(error.localizedDescription)"
        }
    }
}

class PrintService {
    static let shared = PrintService()
    private init() {}

    /// Print compiled manuscript using existing PDFExporter
    func printManuscript(
        documents: [CompilableDocument],
        title: String,
        author: String,
        settings: CompileSettings,
        progress: ((CompileProgress) -> Void)? = nil
    ) async throws {
        // Generate PDF using existing exporter
        let pdfData = try await PDFExporter.shared.export(
            documents: documents,
            title: title,
            author: author,
            settings: settings,
            progress: progress
        )

        try await printPDF(data: pdfData, jobName: title)
    }

    #if os(iOS)
    @MainActor
    private func printPDF(data: Data, jobName: String) async throws {
        guard UIPrintInteractionController.isPrintingAvailable else {
            throw PrintError.printingUnavailable
        }

        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = jobName
        printInfo.outputType = .general

        printController.printInfo = printInfo
        printController.printingItem = data

        printController.present(animated: true)
    }
    #else
    @MainActor
    private func printPDF(data: Data, jobName: String) async throws {
        guard let pdfDocument = PDFDocument(data: data) else {
            throw PrintError.pdfGenerationFailed
        }

        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo

        if let printOp = pdfDocument.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true) {
            printOp.jobTitle = jobName
            printOp.showsPrintPanel = true
            printOp.showsProgressPanel = true
            printOp.run()
        }
    }
    #endif
}
