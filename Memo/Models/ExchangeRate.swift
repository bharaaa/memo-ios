//
//  ExchangeRate.swift
//  Memo
//
//  Cached historical exchange rates for offline support and reporting.
//

import Foundation
import SwiftData

@Model
final class ExchangeRate {
    var id: UUID
    var fromCurrencyCode: String
    var toCurrencyCode: String
    var rate: Decimal
    var effectiveDate: Date
    var isManualFallback: Bool
    
    init(
        fromCurrencyCode: String,
        toCurrencyCode: String,
        rate: Decimal,
        effectiveDate: Date = Date(),
        isManualFallback: Bool = false
    ) {
        self.id = UUID()
        self.fromCurrencyCode = fromCurrencyCode
        self.toCurrencyCode = toCurrencyCode
        self.rate = rate
        self.effectiveDate = effectiveDate
        self.isManualFallback = isManualFallback
    }
}
