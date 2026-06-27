//
//  Color+Memo.swift
//  Memo
//
//  Brand colour palette. Uses HSL-based curated values so colours
//  look cohesive across light and dark mode. All semantic colours
//  adapt automatically via SwiftUI's dynamic color system.
//
//  Defined as `ShapeStyle where Self == Color` so they resolve in
//  both Color and ShapeStyle contexts (foregroundStyle, fill, etc.).
//

import SwiftUI

// MARK: - Brand

extension ShapeStyle where Self == Color {

    /// Primary indigo — used for key interactive elements and the app icon tint.
    static var memoPrimary: Color  { Color(hue: 0.672, saturation: 0.72, brightness: 0.92) }

    /// Warm amber — accent for confirmations and highlights.
    static var memoAccent: Color   { Color(hue: 0.10,  saturation: 0.88, brightness: 0.96) }
}

// MARK: - Semantic Transaction Colours

extension ShapeStyle where Self == Color {

    /// Expense colour — muted coral red.
    static var memoExpense: Color  { Color(hue: 0.01,  saturation: 0.75, brightness: 0.88) }

    /// Income colour — calm emerald green.
    static var memoIncome: Color   { Color(hue: 0.38,  saturation: 0.60, brightness: 0.75) }

    /// Transfer colour — sky blue.
    static var memoTransfer: Color { Color(hue: 0.58,  saturation: 0.65, brightness: 0.88) }
}

// MARK: - Surfaces (adaptive)

extension ShapeStyle where Self == Color {

    static var memoBackground: Color          { Color(.systemBackground) }
    static var memoSecondaryBackground: Color { Color(.secondarySystemBackground) }
    static var memoCard: Color                { Color(.tertiarySystemBackground) }
    static var memoSeparator: Color           { Color(.separator) }
}

// MARK: - Text

extension ShapeStyle where Self == Color {

    static var memoPrimaryText: Color    { Color(.label) }
    static var memoSecondaryText: Color  { Color(.secondaryLabel) }
    static var memoTertiaryText: Color   { Color(.tertiaryLabel) }
}

// MARK: - Chat Bubbles

extension ShapeStyle where Self == Color {

    static var memoUserBubble: Color  { Color.memoPrimary.opacity(0.85) }
    static var memoMemoBubble: Color  { Color(.secondarySystemFill) }
}

// MARK: - Hex Initialiser
// Used by models that store colorHex strings (Category, Account, Tag…)

extension Color {

    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }

        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let r, g, b, a: Double
        switch cleaned.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8)  & 0xFF) / 255
            b = Double(int         & 0xFF) / 255
            a = 1.0
        case 8:
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8)  & 0xFF) / 255
            a = Double(int         & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - TransactionType convenience

extension TransactionType {
    var color: Color {
        switch self {
        case .expense:  return .memoExpense
        case .income:   return .memoIncome
        case .transfer: return .memoTransfer
        }
    }
}
