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
    var limitAmount: Decimal
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
        limitAmount: Decimal,
        period: BudgetPeriod,
        startDate: Date = Date(),
        category: Category? = nil,
        account: Account? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.limitAmount = limitAmount
        self.period = period
        self.startDate = startDate
        self.isActive = true
        self.colorHex = "#6366F1"
        self.createdAt = Date()
        self.category = category
        self.account = account
    }
}
