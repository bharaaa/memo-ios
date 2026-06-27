//
//  Account.swift
//  Memo
//
//  Accounts represent where money lives or comes from.
//  The `balance` here is a running total managed by TransactionService —
//  it is NOT fetched from a bank API, keeping the app fully offline.
//

import Foundation
import SwiftData

@Model
final class Account: Identifiable {
    var id: UUID
    var name: String
    var icon: String           // SF Symbol name
    var colorHex: String
    var currencyCode: String   // ISO 4217, e.g. "IDR", "USD"
    var balance: Decimal
    var accountType: AccountType
    var isDefault: Bool        // one account can be the default for new transactions
    var isArchived: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    var transactions: [Transaction]

    init(
        name: String,
        icon: String,
        colorHex: String,
        currencyCode: String,
        accountType: AccountType,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.currencyCode = currencyCode
        self.balance = 0
        self.accountType = accountType
        self.isDefault = isDefault
        self.isArchived = false
        self.sortOrder = 0
        self.createdAt = Date()
        self.transactions = []
    }
}
