//
//  MoneyCalculator.swift
//  Memo
//
//  Centralizes arithmetic and rounding logic for Money to prevent
//  floating point drift and ensure currency parity.
//

import Foundation

enum MoneyCalculatorError: Error {
    case mismatchedCurrencies(CurrencyCode, CurrencyCode)
}

struct MoneyCalculator {
    
    /// Adds two Money objects. Throws if currencies don't match.
    static func add(_ lhs: Money, _ rhs: Money) throws -> Money {
        guard lhs.currencyCode == rhs.currencyCode else {
            throw MoneyCalculatorError.mismatchedCurrencies(lhs.currencyCode, rhs.currencyCode)
        }
        return Money(amount: lhs.amount + rhs.amount, currencyCode: lhs.currencyCode)
    }
    
    /// Subtracts rhs from lhs. Throws if currencies don't match.
    static func subtract(_ lhs: Money, _ rhs: Money) throws -> Money {
        guard lhs.currencyCode == rhs.currencyCode else {
            throw MoneyCalculatorError.mismatchedCurrencies(lhs.currencyCode, rhs.currencyCode)
        }
        return Money(amount: lhs.amount - rhs.amount, currencyCode: lhs.currencyCode)
    }
    
    /// Multiplies a Money object by a Decimal rate and rounds properly.
    static func multiply(_ money: Money, by multiplier: Decimal, targetCurrency: CurrencyCode? = nil) -> Money {
        let result = money.amount * multiplier
        
        // Use Banker's Rounding (to nearest even)
        var roundedResult = Decimal()
        var original = result
        NSDecimalRound(&roundedResult, &original, 2, .bankers)
        
        return Money(amount: roundedResult, currencyCode: targetCurrency ?? money.currencyCode)
    }
    
    /// Divides a Money object by a Decimal rate and rounds properly.
    static func divide(_ money: Money, by divisor: Decimal, targetCurrency: CurrencyCode? = nil) -> Money {
        guard divisor != 0 else { return Money(amount: 0, currencyCode: targetCurrency ?? money.currencyCode) }
        let result = money.amount / divisor
        
        var roundedResult = Decimal()
        var original = result
        NSDecimalRound(&roundedResult, &original, 2, .bankers)
        
        return Money(amount: roundedResult, currencyCode: targetCurrency ?? money.currencyCode)
    }
}
