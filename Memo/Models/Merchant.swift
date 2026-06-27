//
//  Merchant.swift
//  Memo
//
//  Merchants are auto-created or enriched from AI parsing.
//  They power smart category suggestions — if the user pays
//  "Grab" three times and always picks Transport, future Grab
//  entries will auto-suggest Transport.
//

import Foundation
import SwiftData

@Model
final class Merchant: Identifiable {
    var id: UUID
    var name: String
    var normalizedName: String  // lowercased, trimmed — used for deduplication
    var iconName: String?       // SF Symbol or custom asset name
    var colorHex: String

    @Relationship(deleteRule: .nullify)
    var defaultCategory: Category?

    @Relationship(deleteRule: .nullify, inverse: \Transaction.merchant)
    var transactions: [Transaction]

    init(name: String, defaultCategory: Category? = nil) {
        self.id = UUID()
        self.name = name
        self.normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)
        self.colorHex = "#6366F1"
        self.defaultCategory = defaultCategory
        self.transactions = []
    }
}
