//
//  Tag.swift
//  Memo
//

import Foundation
import SwiftData

@Model
final class Tag: Identifiable {
    var id: UUID
    var name: String
    var colorHex: String

    // Inverse relationship declared in Transaction
    var transactions: [Transaction]

    init(name: String, colorHex: String = "#A78BFA") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.transactions = []
    }
}
