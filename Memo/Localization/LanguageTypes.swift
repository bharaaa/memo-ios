//
//  LanguageTypes.swift
//  Memo
//
//  Core language definitions separating UI language from AI parsing
//  and speech recognition languages.
//

import Foundation

/// The language used for the app's user interface.
enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system = "system"
    case english = "en"
    case indonesian = "id"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .indonesian: return "Bahasa Indonesia"
        }
    }
    
    /// Maps the selected app language to a Locale identifier.
    var localeIdentifier: String {
        switch self {
        case .system:
            return Locale.current.identifier
        case .english:
            return "en_US"
        case .indonesian:
            return "id_ID"
        }
    }
}

/// The language used by AI models for parsing transactions.
/// Kept separate from UI language for future multilingual support.
enum ParsingLanguage: String, Codable, CaseIterable, Sendable {
    case auto = "auto"
    case english = "en"
    case indonesian = "id"
    case multilingual = "multilingual"
}

/// The language used for speech recognition.
enum SpeechRecognitionLanguage: String, Codable, CaseIterable, Sendable {
    case auto = "auto"
    case english = "en"
    case indonesian = "id"
}
