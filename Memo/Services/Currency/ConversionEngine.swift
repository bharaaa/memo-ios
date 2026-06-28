//
//  ConversionEngine.swift
//  Memo
//
//  Coordinates currency conversion logic between Original Money and Converted Money.
//

import Foundation

final class ConversionEngine {
    
    private let exchangeRateService: ExchangeRateServiceProtocol
    
    init(exchangeRateService: ExchangeRateServiceProtocol = ExchangeRateService()) {
        self.exchangeRateService = exchangeRateService
    }
    
    /// Converts the original money into the target currency.
    func convert(_ money: Money, to targetCurrency: CurrencyCode) async throws -> (convertedMoney: Money, rate: Decimal) {
        if money.currencyCode == targetCurrency {
            return (money, 1.0)
        }
        
        let rate = try await exchangeRateService.fetchRate(from: money.currencyCode, to: targetCurrency)
        let convertedMoney = MoneyCalculator.multiply(money, by: rate, targetCurrency: targetCurrency)
        
        return (convertedMoney, rate)
    }
}
