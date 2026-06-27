//
//  MemoService.swift
//  Memo
//
//  The central orchestrator. It decides which AI provider to use
//  and drives the full parsing pipeline:
//
//  User Input → RuleBased → [if low confidence] → AppleFoundation
//                        → [if unavailable]      → OpenAICompatible
//                        → ParsedTransaction
//
//  MemoService never writes to SwiftData. It returns a ParsedTransaction
//  which the view model passes to TransactionPreviewView before saving.
//

import Foundation
import UIKit

@MainActor
@Observable
final class MemoService {

    // MARK: - Providers (in priority order)

    private let ruleBased     = RuleBasedProvider()
    private let appleFM       = AppleFoundationProvider()
    private let openAI        = OpenAICompatibleProvider()

    private let ocr           = OCRService()

    // MARK: - Confidence Threshold

    /// If RuleBased confidence exceeds this, AI is not called.
    private let ruleBasedThreshold: Double = 0.80

    // MARK: - Parse Text

    func parse(input: String) async throws -> ParsedTransaction {
        // 1. Try rule-based first
        if let result = try? await ruleBased.parse(input: input),
           result.confidence >= ruleBasedThreshold {
            return result
        }

        // 2. Try Apple Foundation Models
        if await appleFM.isAvailable {
            return try await appleFM.parse(input: input)
        }

        // 3. Try OpenAI-compatible fallback
        if await openAI.isAvailable {
            return try await openAI.parse(input: input)
        }

        // 4. Last resort: return the rule-based result even if low confidence
        if let result = try? await ruleBased.parse(input: input) {
            return result
        }

        throw AIProviderError.unavailable
    }

    // MARK: - Parse Image (OCR → AI)

    func parse(image: UIImage) async throws -> ParsedTransaction {
        let rawText = try await ocr.recogniseText(in: image)
        guard !rawText.isEmpty else {
            throw AIProviderError.parseFailure("No text found in image.")
        }
        return try await parseOCR(text: rawText, context: "Receipt image")
    }

    // MARK: - Parse PDF

    func parse(pdfData: Data) async throws -> ParsedTransaction {
        let rawText = try await ocr.recognisePDF(data: pdfData)
        guard !rawText.isEmpty else {
            throw AIProviderError.parseFailure("No text found in PDF.")
        }
        return try await parseOCR(text: rawText, context: "PDF receipt")
    }

    // MARK: - Private OCR Pipeline

    private func parseOCR(text: String, context: String) async throws -> ParsedTransaction {
        if await appleFM.isAvailable {
            return try await appleFM.parse(ocrText: text, context: context)
        }
        if await openAI.isAvailable {
            return try await openAI.parse(ocrText: text, context: context)
        }
        return try await ruleBased.parse(input: text)
    }

    // MARK: - Provider Status (for Settings UI)

    func providerStatus() async -> [String: Bool] {
        async let rb   = ruleBased.isAvailable
        async let fm   = appleFM.isAvailable
        async let oai  = openAI.isAvailable
        return await [
            ruleBased.name: rb,
            appleFM.name:   fm,
            openAI.name:    oai,
        ]
    }
}
