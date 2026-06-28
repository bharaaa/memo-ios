//
//  CategoryService.swift
//  Memo
//
//  Utility that maps category hint strings (produced by AI) to actual
//  Category objects persisted in SwiftData. Also used during seeding
//  and Merchant auto-association.
//

import Foundation
import SwiftData

@MainActor
final class CategoryService {

    private let repository: CategoryRepositoryProtocol
    private let context: ModelContext

    init(repository: CategoryRepositoryProtocol, context: ModelContext) {
        self.repository = repository
        self.context = context
    }

    // MARK: - Hint Matching

    /// Find the best matching Category for a natural-language hint.
    /// Returns nil if no reasonable match is found.
    func match(hint: String?) -> Category? {
        guard let hint = hint?.lowercased().trimmingCharacters(in: .whitespaces),
              !hint.isEmpty else { return nil }

        // Keyword → category name mapping
        let hintMap: [String: String] = [
            "food":          "Food & Drink",
            "eat":           "Food & Drink",
            "makan":         "Food & Drink",
            "drink":         "Food & Drink",
            "coffee":        "Food & Drink",
            "restaurant":    "Food & Drink",
            "lunch":         "Food & Drink",
            "dinner":        "Food & Drink",
            "breakfast":     "Food & Drink",
            "burger":        "Food & Drink",
            "pizza":         "Food & Drink",
            "snack":         "Food & Drink",
            "kfc":           "Food & Drink",
            "mcd":           "Food & Drink",
            "mcdonalds":     "Food & Drink",
            "transport":     "Transport",
            "grab":          "Transport",
            "gojek":         "Transport",
            "taxi":          "Transport",
            "bus":           "Transport",
            "mrt":           "Transport",
            "commute":       "Transport",
            "fuel":          "Transport",
            "shopping":      "Shopping",
            "belanja":       "Shopping",
            "clothes":       "Shopping",
            "fashion":       "Shopping",
            "entertainment": "Entertainment",
            "movie":         "Entertainment",
            "game":          "Entertainment",
            "netflix":       "Entertainment",
            "spotify":       "Entertainment",
            "steam":         "Entertainment",
            "health":        "Health",
            "doctor":        "Health",
            "pharmacy":      "Health",
            "medicine":      "Health",
            "bills":         "Bills & Utilities",
            "electricity":   "Bills & Utilities",
            "water":         "Bills & Utilities",
            "internet":      "Bills & Utilities",
            "phone":         "Bills & Utilities",
            "education":     "Education",
            "school":        "Education",
            "course":        "Education",
            "book":          "Education",
            "travel":        "Travel",
            "hotel":         "Travel",
            "flight":        "Travel",
            "salary":        "Salary",
            "gaji":          "Salary",
            "freelance":     "Freelance",
            "investment":    "Investment",
            "saham":         "Investment",
            "gift":          "Gift",
        ]

        // First: exact or contains match in the map
        for (keyword, categoryName) in hintMap {
            if hint.contains(keyword) {
                return fetchCategory(named: categoryName)
            }
        }

        // Second: fuzzy search directly on DB
        return fetchCategory(containing: hint)
    }

    // MARK: - DB Fetch

    private func fetchCategory(named name: String) -> Category? {
        return repository.category(byName: name)
    }

    private func fetchCategory(containing keyword: String) -> Category? {
        let all = repository.allCategories(type: .expense) + repository.allCategories(type: .income)
        return all.first { $0.name.lowercased().contains(keyword) }
    }

    // MARK: - All Categories

    func allCategories(type: CategoryType? = nil) -> [Category] {
        let all = repository.allCategories(type: .expense) + repository.allCategories(type: .income)
        if let type {
            return all.filter { $0.categoryType == type }
        }
        return all
    }
}
