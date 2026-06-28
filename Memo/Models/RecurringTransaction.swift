//
//  RecurringTransaction.swift
//  Memo
//
//  Template for automatic or reminder-based recurring entries.
//  The `templateSnapshot` is a JSON-encoded snapshot of the last
//  transaction so it can be replayed without keeping a live reference.
//

import Foundation
import SwiftData

@Model
final class RecurringTransaction: Identifiable {
    var id: UUID
    var name: String
    var frequency: RecurrenceFrequency
    var nextDueDate: Date
    var isActive: Bool
    var createdAt: Date

    // Snapshot of the transaction to create each cycle
    var amountSnapshot: Decimal
    var currencyCodeSnapshot: String
    var noteSnapshot: String
    var paymentMethodSnapshot: PaymentMethod
    var transactionTypeSnapshot: TransactionType

    @Relationship(deleteRule: .nullify)
    var accountSnapshot: Account?

    @Relationship(deleteRule: .nullify)
    var categorySnapshot: Category?

    @Relationship(deleteRule: .nullify)
    var merchantSnapshot: Merchant?

    @Relationship(deleteRule: .nullify, inverse: \Transaction.recurringSource)
    var generatedTransactions: [Transaction]

    init(
        name: String,
        frequency: RecurrenceFrequency,
        nextDueDate: Date,
        amount: Decimal,
        currencyCode: String,
        note: String = "",
        paymentMethod: PaymentMethod = .cash,
        transactionType: TransactionType = .expense
    ) {
        self.id = UUID()
        self.name = name
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.isActive = true
        self.createdAt = Date()
        self.amountSnapshot = amount
        self.currencyCodeSnapshot = currencyCode
        self.noteSnapshot = note
        self.paymentMethodSnapshot = paymentMethod
        self.transactionTypeSnapshot = transactionType
        self.generatedTransactions = []
    }
}
