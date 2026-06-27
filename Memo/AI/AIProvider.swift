//
//  AIProvider.swift
//  Memo
//
//  Protocol that all AI providers must conform to.
//  Callers never know which provider generated the ParsedTransaction —
//  they just get a consistent result regardless of backend.
//

import Foundation

/// Errors that any AI provider may throw.
enum AIProviderError: LocalizedError, Sendable {
    case unavailable
    case lowConfidence(Double)
    case invalidInput(String)
    case networkError(String)
    case parseFailure(String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "AI is not available on this device."
        case .lowConfidence(let score):
            return "Could not parse with enough confidence (\(Int(score * 100))%)."
        case .invalidInput(let msg):
            return "Invalid input: \(msg)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .parseFailure(let msg):
            return "Could not understand the input: \(msg)"
        }
    }
}

/// Protocol every AI provider must implement.
protocol AIProvider: Sendable {

    /// Whether this provider can currently be used.
    var isAvailable: Bool { get async }

    /// Human-readable name — used for debugging and settings UI.
    var name: String { get }

    /// Parse a natural language string (e.g. "Coffee 35k").
    func parse(input: String) async throws -> ParsedTransaction

    /// Parse OCR text extracted from an image or PDF.
    /// `context` is an optional hint (e.g. "receipt from Grab").
    func parse(ocrText: String, context: String?) async throws -> ParsedTransaction
}

// MARK: - Default Implementation

extension AIProvider {
    func parse(ocrText: String, context: String?) async throws -> ParsedTransaction {
        // Default: treat OCR text as natural language input
        let combined = context.map { "\($0)\n\(ocrText)" } ?? ocrText
        return try await parse(input: combined)
    }
}
