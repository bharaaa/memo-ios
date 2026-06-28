//
//  AppleFoundationProvider.swift
//  Memo
//
//  Uses Apple Foundation Models (Apple Intelligence) for structured
//  transaction extraction. Requires iOS 26+ with Apple Intelligence enabled.
//
//  Architecture note:
//  - Uses @Generable for type-safe structured output
//  - Falls back gracefully when the model is unavailable
//  - Never blocks the main thread — all inference is async
//

import Foundation
import FoundationModels

struct AppleFoundationProvider: AIProvider {

    let name = "appleFoundation"

    var isAvailable: Bool {
        get async {
            return SystemLanguageModel.default.isAvailable
        }
    }

    // MARK: - Parse Natural Language

    func parse(input: String) async throws -> ParsedTransaction {
        guard await isAvailable else {
            throw AIProviderError.unavailable
        }

        let prompt = buildPrompt(for: input)

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(
                to: prompt,
                generating: TransactionExtractionOutput.self
            )
            return convert(response.content, rawInput: input)
        } catch {
            throw AIProviderError.parseFailure(error.localizedDescription)
        }
    }

    // MARK: - Parse OCR Text

    func parse(ocrText: String, context: String?) async throws -> ParsedTransaction {
        guard await isAvailable else {
            throw AIProviderError.unavailable
        }

        let combined = """
        The following is OCR text extracted from a receipt or document.
        \(context.map { "Context: \($0)" } ?? "")
        
        OCR Text:
        \(ocrText)
        
        Extract the transaction details.
        """

        let session = LanguageModelSession()
        let response = try await session.respond(
            to: combined,
            generating: TransactionExtractionOutput.self
        )
        return convert(response.content, rawInput: ocrText)
    }

    // MARK: - Prompt Construction

    private func buildPrompt(for input: String) -> String {
        let preferredCurrency = UserDefaults.standard.string(forKey: "preferredCurrencyCode") ?? "IDR"
        return """
        You are a financial assistant. Extract transaction details from the user's message.
        
        Rules:
        - "k" suffix means multiply by 1000 (35k = 35000)
        - "m" suffix means multiply by 1000000
        - If no date is mentioned, leave dateString empty
        - transactionType should be "expense" unless clearly income
        - categoryHint should be a simple label like "food", "transport", "shopping"
        - accountHint should be a simple label like "cash", "bank", "credit card", "bca" if mentioned
        - paymentMethod should be one of: "cash", "debit", "credit", "transfer", "other" (default to cash if unclear)
        - Always populate 'note' with a descriptive summary of the purchase based on the input text
        - Assume the default currency is \(preferredCurrency) unless explicitly stated otherwise
        - confidence: 0.0–1.0 based on how certain you are
        
        User message: "\(input)"
        """
    }

    // MARK: - Conversion

    private func convert(_ output: TransactionExtractionOutput, rawInput: String) -> ParsedTransaction {
        var parsed = ParsedTransaction(rawInput: rawInput, providerName: name)

        if let amtStr = output.amount, let a = Double(amtStr), a > 0 {
            parsed.amount = Decimal(a)
        }
        parsed.merchantName  = output.merchantName?.isEmpty == false ? output.merchantName : nil
        parsed.categoryHint  = output.categoryHint
        parsed.accountHint   = output.accountHint
        parsed.note          = output.note?.isEmpty == false ? output.note : nil
        parsed.currencyCode  = output.currencyCode?.isEmpty == false ? output.currencyCode : nil
        
        if let confStr = output.confidence, let c = Double(confStr) {
            parsed.confidence = c
        } else {
            parsed.confidence = 0.5
        }

        // Parse transaction type
        if let type = output.transactionType {
            parsed.transactionType = type.lowercased() == "income" ? .income : .expense
        }
        
        // Parse payment method
        if let pm = output.paymentMethod?.lowercased() {
            parsed.paymentMethod = PaymentMethod(rawValue: pm) ?? .cash
        }

        // Parse date
        if let ds = output.dateString, !ds.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            parsed.date = formatter.date(from: ds)
        }

        return parsed
    }
}

// MARK: - Structured Output Schema

/// The @Generable type that Foundation Models will populate.
/// All fields are optional so partial results are still useful.
@Generable
private struct TransactionExtractionOutput {
    @Guide(description: "The numeric amount of money involved, represented as a string. Apply k/m multipliers.")
    var amount: String?

    @Guide(description: "ISO 4217 currency code if mentioned (e.g. IDR, USD). Null if not specified.")
    var currencyCode: String?

    @Guide(description: "The merchant, payee, or store name. Null if unclear.")
    var merchantName: String?

    @Guide(description: "A simple spending category hint: food, transport, shopping, entertainment, health, bills, education, travel, salary, other.")
    var categoryHint: String?

    @Guide(description: "A hint for the account used if mentioned (e.g. cash, bank, credit card, bca). Null if not specified.")
    var accountHint: String?

    @Guide(description: "A short note or descriptive summary of the purchase intelligently inferred from the input. Do not leave null if you can infer a context.")
    var note: String?

    @Guide(description: "ISO 8601 date (YYYY-MM-DD) if a date is mentioned. Empty if not.")
    var dateString: String?

    @Guide(description: "expense or income. Default to expense.")
    var transactionType: String?
    
    @Guide(description: "The payment method used: cash, debit, credit, transfer, or other.")
    var paymentMethod: String?

    @Guide(description: "How confident you are in the extraction, from 0.0 to 1.0, represented as a string.")
    var confidence: String?
}
