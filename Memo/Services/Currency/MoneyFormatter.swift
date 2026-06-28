//
//  MoneyFormatter.swift
//  Memo
//
//  Formats Money objects locale-safely.
//

import Foundation

struct MoneyFormatter {
    
    static func format(
        _ money: Money,
        locale: Locale = .autoupdatingCurrent,
        showSign: Bool = false
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode.rawValue
        formatter.locale = locale
        
        // Let NumberFormatter handle the currency symbol positioning based on locale
        let formattedStr = formatter.string(from: money.amount as NSDecimalNumber) ?? "\(money.currencyCode.symbol)\(money.amount)"
        
        if showSign && money.amount > 0 {
            return "+\(formattedStr)"
        } else if showSign && money.amount < 0 {
            // Negative amounts already have a minus sign from NumberFormatter usually,
            // but we might want to standardize it for our UI layout.
            // For now, rely on standard NumberFormatter layout.
            return formattedStr
        }
        
        return formattedStr
    }
}
