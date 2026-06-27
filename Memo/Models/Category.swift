//
//  Category.swift
//  Memo
//
//  Supports parent/child hierarchy so the app can have top-level
//  "Food & Drink" with children "Coffee", "Restaurant", "Groceries".
//  `isSystem` categories are seeded by the app and cannot be deleted.
//

import Foundation
import SwiftData

@Model
final class Category: Identifiable {
    var id: UUID
    var name: String
    var icon: String       // SF Symbol name
    var colorHex: String
    var categoryType: CategoryType
    var isSystem: Bool     // true = seeded by app, user cannot delete
    var sortOrder: Int

    @Relationship(deleteRule: .nullify)
    var parent: Category?

    @Relationship(deleteRule: .cascade, inverse: \Category.parent)
    var children: [Category]

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]

    init(
        name: String,
        icon: String,
        colorHex: String,
        categoryType: CategoryType = .expense,
        isSystem: Bool = false,
        sortOrder: Int = 0,
        parent: Category? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.categoryType = categoryType
        self.isSystem = isSystem
        self.sortOrder = sortOrder
        self.parent = parent
        self.children = []
        self.transactions = []
    }
}
