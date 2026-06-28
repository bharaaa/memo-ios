//
//  Budget.swift
//  Memo
//

import Foundation
import SwiftData

@Model
final class Budget: Identifiable {
    var id: UUID
    var name: String
    var limitAmountRaw: Decimal
    var limitCurrencyRaw: String
    
    @Transient var limit: Money {
        get { Money(amount: limitAmountRaw, currencyCode: CurrencyCode(rawValue: limitCurrencyRaw) ?? .idr) }
        set {
            limitAmountRaw = newValue.amount
            limitCurrencyRaw = newValue.currencyCode.rawValue
        }
    }
    var period: BudgetPeriod
    var startDate: Date
    var isActive: Bool
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var category: Category?

    @Relationship(deleteRule: .nullify)
    var account: Account?

    init(
        name: String,
        limit: Money,
        period: BudgetPeriod,
        startDate: Date = Date(),
        category: Category? = nil,
        account: Account? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.limitAmountRaw = limit.amount
        self.limitCurrencyRaw = limit.currencyCode.rawValue
        self.period = period
        self.startDate = startDate
        self.isActive = true
        self.colorHex = "#6366F1"
        self.createdAt = Date()
        self.category = category
        self.account = account
    }
}
