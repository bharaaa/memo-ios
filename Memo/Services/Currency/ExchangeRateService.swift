//
//  ExchangeRateService.swift
//  Memo
//
//  Responsible for fetching exchange rates. Falls back to static rates if offline.
//

import Foundation

enum ExchangeRateError: Error {
    case networkError
    case invalidResponse
    case rateNotFound
}

protocol ExchangeRateServiceProtocol {
    func fetchRate(from source: CurrencyCode, to target: CurrencyCode) async throws -> Decimal
}

final class ExchangeRateService: ExchangeRateServiceProtocol {
    
    // For now, we use a static fallback dictionary if the API fails or is not yet implemented.
    // Rates relative to USD for simplicity in cross-calculation
    private let staticRatesToUSD: [CurrencyCode: Decimal] = [
        .usd: 1.0,
        .idr: 16250.0,
        .eur: 0.92,
        .jpy: 156.50,
        .gbp: 0.79,
        .sgd: 1.35,
        .aud: 1.51
    ]
    
    func fetchRate(from source: CurrencyCode, to target: CurrencyCode) async throws -> Decimal {
        if source == target { return 1.0 }
        
        // TODO: Implement actual API fetch here.
        // For now, simulate network failure and fallback to static rates.
        
        guard let sourceRate = staticRatesToUSD[source],
              let targetRate = staticRatesToUSD[target] else {
            throw ExchangeRateError.rateNotFound
        }
        
        // Example: IDR to EUR
        // 1 USD = 16250 IDR -> 1 IDR = 1/16250 USD
        // 1 USD = 0.92 EUR
        // Rate = (1 / 16250) * 0.92 = 0.92 / 16250
        let rate = targetRate / sourceRate
        return rate
    }
}
