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
    @Attribute(originalName: "amount") var originalMoneyAmount: Decimal
    @Attribute(originalName: "currencyCode") var originalMoneyCurrencyRaw: String
    
    var convertedMoneyAmount: Decimal = 0
    var convertedMoneyCurrencyRaw: String = "IDR"
    
    var exchangeRate: Decimal = 1.0
    var exchangeRateDate: Date = Date()
    
    // Computed Properties for clean Money access
    @Transient var originalMoney: Money {
        get { Money(amount: originalMoneyAmount, currencyCode: CurrencyCode(rawValue: originalMoneyCurrencyRaw) ?? .idr) }
        set { 
            originalMoneyAmount = newValue.amount
            originalMoneyCurrencyRaw = newValue.currencyCode.rawValue
        }
    }
    
    @Transient var convertedMoney: Money {
        get { Money(amount: convertedMoneyAmount, currencyCode: CurrencyCode(rawValue: convertedMoneyCurrencyRaw) ?? .idr) }
        set {
            convertedMoneyAmount = newValue.amount
            convertedMoneyCurrencyRaw = newValue.currencyCode.rawValue
        }
    }
    var note: String
    var date: Date
    var paymentMethod: PaymentMethod
    var transactionType: TransactionType
    var source: TransactionSource
    var confidence: Double     // 0.0 = unknown, 1.0 = certain
    var isConfirmed: Bool      // user has reviewed and confirmed
    var isProcessing: Bool = false // waiting for background LLM enrichment
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
        originalMoney: Money,
        convertedMoney: Money,
        exchangeRate: Decimal = 1.0,
        exchangeRateDate: Date = Date(),
        note: String = "",
        date: Date = Date(),
        paymentMethod: PaymentMethod = .cash,
        transactionType: TransactionType = .expense,
        source: TransactionSource = .chat,
        confidence: Double = 1.0,
        isConfirmed: Bool = false,
        isProcessing: Bool = false
    ) {
        self.id = UUID()
        self.originalMoneyAmount = originalMoney.amount
        self.originalMoneyCurrencyRaw = originalMoney.currencyCode.rawValue
        self.convertedMoneyAmount = convertedMoney.amount
        self.convertedMoneyCurrencyRaw = convertedMoney.currencyCode.rawValue
        self.exchangeRate = exchangeRate
        self.exchangeRateDate = exchangeRateDate
        self.note = note
        self.date = date
        self.paymentMethod = paymentMethod
        self.transactionType = transactionType
        self.source = source
        self.confidence = confidence
        self.isConfirmed = isConfirmed
        self.isProcessing = isProcessing
        self.createdAt = Date()
        self.updatedAt = Date()
        self.attachments = []
        self.tags = []
    }
}
