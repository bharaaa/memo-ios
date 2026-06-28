//
//  TransactionParsingModels.swift
//  Memo
//
//  Data models for the layered AI parsing architecture.
//

import Foundation

/// The current status of a parsing operation.
enum ParsingStatus: String, Codable, Sendable, Equatable {
    case parsing
    case ready
    case failed
}

/// DTO representing the output of the fast local parser.
struct LocalParsingResult: Sendable {
    var amount: Decimal?
    var currencyCode: String?
    var date: Date?
    var transactionType: TransactionType
    var merchantGuess: String?
    var confidence: Double
    
    // Metadata
    var missingFields: [String] = []
}

/// DTO representing the output of a foundation or external semantic model.
struct SemanticParsingResult: Sendable {
    var merchantName: String?
    var categoryHint: String?
    var accountHint: String?
    var note: String?
    var paymentMethod: PaymentMethod?
    var confidence: Double
}
