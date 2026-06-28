//
//  ParsedTransaction.swift
//  Memo
//
//  The universal output DTO produced by every AIProvider.
//  AI never writes to SwiftData — it always produces a ParsedTransaction
//  which is validated and reviewed before TransactionService saves it.
//

import Foundation

/// Intermediate representation of an AI-extracted transaction.
/// Nil fields indicate the AI could not determine the value with confidence.
struct ParsedTransaction: Sendable {

    // MARK: Core Fields

    var amount: Decimal?
    var currencyCode: String?          // ISO 4217 — nil means "use account default"
    var merchantName: String?
    var categoryHint: String?          // natural language hint, e.g. "food", "transport"
    var accountHint: String?           // natural language hint, e.g. "cash", "bca"
    var note: String?
    var date: Date?
    var paymentMethod: PaymentMethod?
    var transactionType: TransactionType
    var confidence: Double             // 0.0–1.0

    // MARK: Metadata

    var rawInput: String               // original user string / OCR text
    var providerName: String           // "rule_based", "apple_foundation", "openai"

    // MARK: Validation Helpers

    var isUsable: Bool { amount != nil && amount! > 0 }

    /// True if the transaction can be saved without user review.
    /// High confidence + required fields present.
    var canAutoConfirm: Bool {
        confidence >= 0.95 && amount != nil && amount! > 0
    }

    // MARK: Init

    init(
        amount: Decimal? = nil,
        currencyCode: String? = nil,
        merchantName: String? = nil,
        categoryHint: String? = nil,
        accountHint: String? = nil,
        note: String? = nil,
        date: Date? = nil,
        paymentMethod: PaymentMethod? = nil,
        transactionType: TransactionType = .expense,
        confidence: Double = 0.0,
        rawInput: String = "",
        providerName: String = "unknown"
    ) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.merchantName = merchantName
        self.categoryHint = categoryHint
        self.accountHint = accountHint
        self.note = note
        self.date = date
        self.paymentMethod = paymentMethod
        self.transactionType = transactionType
        self.confidence = confidence
        self.rawInput = rawInput
        self.providerName = providerName
    }
}
