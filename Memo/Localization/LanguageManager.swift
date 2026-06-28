//
//  LanguageManager.swift
//  Memo
//
//  Manages the application's runtime language switching and provides
//  a reactive locale for SwiftUI environments.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class LanguageManager {
    static let shared = LanguageManager()
    
    // We use a private property mapped to UserDefaults for persistence.
    // We must manually trigger Observation when it changes.
    private let defaults = UserDefaults.standard
    private let languageKey = "ui_language_preference"
    
    var currentLanguage: AppLanguage {
        didSet {
            defaults.set(currentLanguage.rawValue, forKey: languageKey)
            // Trigger UI update
            currentLocale = LanguageManager.calculateLocale(for: currentLanguage)
        }
    }
    
    // The reactive locale exposed to the environment
    private(set) var currentLocale: Locale
    
    private init() {
        // Initialize the locale based on the stored preference
        let savedLang: AppLanguage
        if let saved = defaults.string(forKey: languageKey),
           let lang = AppLanguage(rawValue: saved) {
            savedLang = lang
        } else {
            savedLang = .system
        }
        
        self.currentLanguage = savedLang
        self.currentLocale = LanguageManager.calculateLocale(for: savedLang)
    }
    
    private static func calculateLocale(for language: AppLanguage) -> Locale {
        switch language {
        case .system:
            return Locale.autoupdatingCurrent
        case .english:
            return Locale(identifier: "en_US")
        case .indonesian:
            return Locale(identifier: "id_ID")
        }
    }
}
