//
//  Decimal+Currency.swift
//  Memo
//
//  Decimal → localised currency string helpers.
//  Using Decimal (not Double) throughout ensures cent-accurate arithmetic
//  regardless of currency denomination.
//

import Foundation

extension Decimal {

    /// Formats as a localised currency string.
    /// e.g. Decimal(45000).formatted(currency: "IDR") → "Rp 45.000"
    ///      Decimal(12.50).formatted(currency: "USD") → "$12.50"
    func formatted(currency currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = currencyCode == "IDR" || currencyCode == "JPY" ? 0 : 2
        return formatter.string(from: self as NSDecimalNumber) ?? "\(currencyCode) \(self)"
    }

    /// Short formatted string — drops trailing zeroes for zero-decimal currencies.
    /// e.g. 45000 IDR → "Rp 45.000" but 45000.50 USD → "$45,000.50"
    func shortFormatted(currency currencyCode: String) -> String {
        formatted(currency: currencyCode)
    }

    /// Compact representation — "45k", "1.2M" — for chart axis labels.
    var compactFormatted: String {
        let d = NSDecimalNumber(decimal: self).doubleValue
        switch abs(d) {
        case 1_000_000...: return String(format: "%.1fM", d / 1_000_000)
        case 1_000...:     return String(format: "%.0fk", d / 1_000)
        default:           return String(format: "%.0f", d)
        }
    }

    /// Parse "35k", "35.000", "35,000" into a Decimal amount.
    /// Returns nil if the string cannot be resolved.
    static func parse(_ string: String) -> Decimal? {
        let cleaned = string.trimmingCharacters(in: .whitespaces).lowercased()

        // Handle "k" suffix — 35k → 35000
        if cleaned.hasSuffix("k") {
            let base = cleaned.dropLast()
            if let d = Decimal(string: String(base)) {
                return d * 1000
            }
        }

        // Handle "m" suffix — 1.5m → 1500000
        if cleaned.hasSuffix("m") {
            let base = cleaned.dropLast()
            if let d = Decimal(string: String(base)) {
                return d * 1_000_000
            }
        }

        // Standard decimal — try locale-aware parsing first
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if let n = formatter.number(from: cleaned) {
            return Decimal(string: n.stringValue)
        }

        // Fallback — remove common separators and parse
        let stripped = cleaned.replacingOccurrences(of: ",", with: "")
                               .replacingOccurrences(of: ".", with: "")
        return Decimal(string: stripped)
    }
}
