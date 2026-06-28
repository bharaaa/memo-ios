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
    var currencyCodeRaw: String
    var openingBalanceAmount: Decimal
    
    // Computed properties for clean Money access
    @Transient var currencyCode: CurrencyCode {
        get { CurrencyCode(rawValue: currencyCodeRaw) ?? .idr }
        set { currencyCodeRaw = newValue.rawValue }
    }
    
    @Transient var openingBalance: Money {
        get { Money(amount: openingBalanceAmount, currencyCode: currencyCode) }
        set { 
            openingBalanceAmount = newValue.amount
            currencyCodeRaw = newValue.currencyCode.rawValue
        }
    }
    var accountType: AccountType
    var isDefault: Bool        // one account can be the default for new transactions
    var isArchived: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    var transactions: [Transaction]

    var currentBalance: Money {
        let income = transactions
            .filter { $0.transactionType == .income }
            .reduce(Decimal(0)) { $0 + $1.originalMoneyAmount }
        let expense = transactions
            .filter { $0.transactionType == .expense }
            .reduce(Decimal(0)) { $0 + $1.originalMoneyAmount }
        let balance = openingBalanceAmount + income - expense
        return Money(amount: balance, currencyCode: currencyCode)
    }

    init(
        name: String,
        icon: String,
        colorHex: String,
        currencyCode: CurrencyCode,
        accountType: AccountType,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.currencyCodeRaw = currencyCode.rawValue
        self.openingBalanceAmount = 0
        self.accountType = accountType
        self.isDefault = isDefault
        self.isArchived = false
        self.sortOrder = 0
        self.createdAt = Date()
        self.transactions = []
    }
}
