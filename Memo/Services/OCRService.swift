//
//  OCRService.swift
//  Memo
//
//  Wraps Apple's Vision framework to extract text from images.
//  Returns raw text — interpretation is always delegated to the AI layer.
//  This keeps Vision isolated and testable.
//

import Vision
import CoreImage
import UIKit

@MainActor
final class OCRService {

    // MARK: - Image Recognition

    /// Recognise text in a UIImage. Returns concatenated lines.
    func recogniseText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        return try await recognise(cgImage: cgImage)
    }

    /// Recognise text in raw CGImage data.
    func recognise(cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.visionError(error.localizedDescription))
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["id-ID", "en-US"]  // Indonesian + English

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionError(error.localizedDescription))
            }
        }
    }

    // MARK: - PDF Support

    /// Extracts combined OCR text from the first page of a PDF.
    /// Full multi-page support can be added when PDFKit integration is expanded.
    func recognisePDF(data: Data) async throws -> String {
        guard let source = CGDataProvider(data: data as CFData),
              let pdf = CGPDFDocument(source),
              let page = pdf.page(at: 1) else {
            throw OCRError.invalidImage
        }

        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { ctx in
            ctx.cgContext.translateBy(x: 0, y: pageRect.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            ctx.cgContext.drawPDFPage(page)
        }
        return try await recogniseText(in: image)
    }
}

// MARK: - Errors

enum OCRError: LocalizedError {
    case invalidImage
    case visionError(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:        return "The image could not be processed."
        case .visionError(let m):  return "Text recognition failed: \(m)"
        }
    }
}
