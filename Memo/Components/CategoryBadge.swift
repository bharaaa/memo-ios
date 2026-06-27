//
//  CategoryBadge.swift
//  Memo
//
//  Pill-shaped badge showing a category icon + name.
//  Used in transaction rows, preview sheets, and list headers.
//

import SwiftUI

struct CategoryBadge: View {
    let icon: String
    let name: String
    let colorHex: String
    var style: BadgeStyle = .filled

    enum BadgeStyle { case filled, outlined, minimal }

    private var badgeColor: Color { Color(hex: colorHex) }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            if style != .minimal {
                Text(name)
                    .font(.memoCaption)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(style == .filled ? .white : badgeColor)
        .padding(.horizontal, style == .minimal ? 6 : 10)
        .padding(.vertical, style == .minimal ? 4 : 5)
        .background {
            Capsule()
                .fill(style == .filled ? badgeColor : badgeColor.opacity(0.15))
        }
    }
}

// MARK: - Category Convenience

extension CategoryBadge {
    init(category: Category, style: BadgeStyle = .filled) {
        self.icon = category.icon
        self.name = category.name
        self.colorHex = category.colorHex
        self.style = style
    }
}

#Preview {
    HStack(spacing: 8) {
        CategoryBadge(icon: "fork.knife", name: "Food", colorHex: "#F97316")
        CategoryBadge(icon: "car.fill", name: "Transport", colorHex: "#3B82F6", style: .outlined)
        CategoryBadge(icon: "bag.fill", name: "Shopping", colorHex: "#EC4899", style: .minimal)
    }
    .padding()
}
