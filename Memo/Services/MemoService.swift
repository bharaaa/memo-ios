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
import SwiftUI

@MainActor
@Observable
final class MemoService {

    // MARK: - Providers (in priority order)

    private let ruleBased     = RuleBasedProvider()
    private let appleFM       = AppleFoundationProvider()
    private let openAI        = OpenAICompatibleProvider()

    private let ocr           = OCRService()


    // MARK: - Selected Provider
    
    @ObservationIgnored
    @AppStorage("selectedAIProvider")
    var selectedProvider: AIProviderType = .appleFoundation
    
    // MARK: - Parse Text

    func parse(input: String) async throws -> ParsedTransaction {
        switch selectedProvider {
        case .appleFoundation:
            if await appleFM.isAvailable {
                return try await appleFM.parse(input: input)
            }
        case .externalAPI:
            if await openAI.isAvailable {
                return try await openAI.parse(input: input)
            }
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
        switch selectedProvider {
        case .appleFoundation:
            if await appleFM.isAvailable {
                return try await appleFM.parse(ocrText: text, context: context)
            }
        case .externalAPI:
            if await openAI.isAvailable {
                return try await openAI.parse(ocrText: text, context: context)
            }
        }
        throw AIProviderError.unavailable
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
