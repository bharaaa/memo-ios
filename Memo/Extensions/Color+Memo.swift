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
import UIKit

fileprivate func dynamicColor(
    lh: CGFloat, ls: CGFloat, lb: CGFloat,
    dh: CGFloat, ds: CGFloat, db: CGFloat
) -> Color {
    Color(UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(hue: dh, saturation: ds, brightness: db, alpha: 1.0)
        } else {
            return UIColor(hue: lh, saturation: ls, brightness: lb, alpha: 1.0)
        }
    })
}

// MARK: - Brand

extension ShapeStyle where Self == Color {

    /// Primary indigo — used for key interactive elements and the app icon tint.
    static var memoPrimary: Color  { 
        dynamicColor(lh: 0.672, ls: 0.72, lb: 0.92,
                     dh: 0.672, ds: 0.60, db: 1.00)
    }

    /// Warm amber — accent for confirmations and highlights.
    static var memoAccent: Color   { 
        dynamicColor(lh: 0.10, ls: 0.88, lb: 0.96,
                     dh: 0.10, ds: 0.75, db: 1.00)
    }
}

// MARK: - Semantic Transaction Colours

extension ShapeStyle where Self == Color {

    /// Expense colour — muted coral red.
    static var memoExpense: Color  { 
        dynamicColor(lh: 0.01, ls: 0.75, lb: 0.88,
                     dh: 0.01, ds: 0.60, db: 1.00)
    }

    /// Income colour — calm emerald green.
    static var memoIncome: Color   { 
        dynamicColor(lh: 0.38, ls: 0.60, lb: 0.75,
                     dh: 0.38, ds: 0.50, db: 0.90)
    }

    /// Transfer colour — sky blue.
    static var memoTransfer: Color { 
        dynamicColor(lh: 0.58, ls: 0.65, lb: 0.88,
                     dh: 0.58, ds: 0.55, db: 1.00)
    }
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
