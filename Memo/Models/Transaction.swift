//
//  Transaction.swift
//  Memo
//
//  The central entity of the app. Every transaction flows through
//  validation before reaching the ModelContext — AI never writes here
//  directly. `confidence` (0–1) records how certain the AI was;
//  low-confidence entries are flagged for user review.
//

import Foundation
import SwiftData

@Model
final class Transaction: Identifiable {
    var id: UUID
    var amount: Decimal
    var currencyCode: String
    var note: String
    var date: Date
    var paymentMethod: PaymentMethod
    var transactionType: TransactionType
    var source: TransactionSource
    var confidence: Double     // 0.0 = unknown, 1.0 = certain
    var isConfirmed: Bool      // user has reviewed and confirmed
    var createdAt: Date
    var updatedAt: Date

    // MARK: Relationships

    @Relationship(deleteRule: .nullify)
    var account: Account?

    /// If this transaction is part of a transfer, links to the other side
    var linkedTransferID: UUID?

    @Relationship(deleteRule: .nullify)
    var category: Category?

    @Relationship(deleteRule: .nullify)
    var merchant: Merchant?

    @Relationship(deleteRule: .cascade)
    var attachments: [Attachment]

    @Relationship(deleteRule: .nullify)
    var tags: [Tag]

    @Relationship(deleteRule: .nullify)
    var recurringSource: RecurringTransaction?

    init(
        amount: Decimal,
        currencyCode: String,
        note: String = "",
        date: Date = Date(),
        paymentMethod: PaymentMethod = .cash,
        transactionType: TransactionType = .expense,
        source: TransactionSource = .chat,
        confidence: Double = 1.0,
        isConfirmed: Bool = false
    ) {
        self.id = UUID()
        self.amount = amount
        self.currencyCode = currencyCode
        self.note = note
        self.date = date
        self.paymentMethod = paymentMethod
        self.transactionType = transactionType
        self.source = source
        self.confidence = confidence
        self.isConfirmed = isConfirmed
        self.createdAt = Date()
        self.updatedAt = Date()
        self.attachments = []
        self.tags = []
    }
}
