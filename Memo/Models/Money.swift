//
//  Money.swift
//  Memo
//
//  A value object representing an exact monetary amount and its currency.
//

import Foundation

struct Money: Codable, Hashable, Equatable {
    let amount: Decimal
    let currencyCode: CurrencyCode
    
    init(amount: Decimal, currencyCode: CurrencyCode) {
        self.amount = amount
        self.currencyCode = currencyCode
    }
    
    static let zero = Money(amount: 0, currencyCode: .idr) // Default fallback zero, but should ideally be constructed with a specific currency
    
    static func zero(in currency: CurrencyCode) -> Money {
        return Money(amount: 0, currencyCode: currency)
    }
}
