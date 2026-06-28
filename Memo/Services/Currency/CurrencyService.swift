//
//  CurrencyService.swift
//  Memo
//
//  Manages the app's base currency preference.
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class CurrencyService {
    static let shared = CurrencyService()
    
    private let defaults = UserDefaults.standard
    private let baseCurrencyKey = "preferredCurrencyCode"
    
    var baseCurrency: CurrencyCode {
        didSet {
            defaults.set(baseCurrency.rawValue, forKey: baseCurrencyKey)
            // Changing base currency requires re-calculating reports/summaries
            // Views observing `CurrencyService` will automatically redraw.
        }
    }
    
    private init() {
        if let saved = defaults.string(forKey: "preferredCurrencyCode"),
           let code = CurrencyCode(rawValue: saved) {
            self.baseCurrency = code
        } else {
            // Default to IDR if no preference is set
            self.baseCurrency = .idr
        }
    }
}
