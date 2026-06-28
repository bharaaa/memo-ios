//
//  CurrencyCode.swift
//  Memo
//
//  Strongly-typed currency codes supported by the app.
//

import Foundation

enum CurrencyCode: String, Codable, CaseIterable, Hashable, Identifiable {
    case idr = "IDR"
    case usd = "USD"
    case eur = "EUR"
    case jpy = "JPY"
    case gbp = "GBP"
    case sgd = "SGD"
    case aud = "AUD"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .idr: return "Rp"
        case .usd: return "$"
        case .eur: return "€"
        case .jpy: return "¥"
        case .gbp: return "£"
        case .sgd: return "S$"
        case .aud: return "A$"
        }
    }
    
    var displayName: String {
        switch self {
        case .idr: return "Indonesian Rupiah"
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .jpy: return "Japanese Yen"
        case .gbp: return "British Pound"
        case .sgd: return "Singapore Dollar"
        case .aud: return "Australian Dollar"
        }
    }
}
