//
//  Transfer.swift
//  Memo
//
//  A transfer moves money between two accounts the user owns.
//  It creates two Transaction entries (one debit, one credit) linked
//  by this model, so balance arithmetic stays consistent.
//

import Foundation
import SwiftData

@Model
final class Transfer: Identifiable {
    var id: UUID
    var amount: Decimal
    var currencyCode: String
    var date: Date
    var note: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var fromAccount: Account?

    @Relationship(deleteRule: .nullify)
    var toAccount: Account?

    // The two generated transaction records
    @Relationship(deleteRule: .cascade)
    var debitTransaction: Transaction?

    @Relationship(deleteRule: .cascade)
    var creditTransaction: Transaction?

    init(
        amount: Decimal,
        currencyCode: String,
        date: Date = Date(),
        note: String = "",
        fromAccount: Account? = nil,
        toAccount: Account? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
        self.note = note
        self.createdAt = Date()
        self.fromAccount = fromAccount
        self.toAccount = toAccount
    }
}
