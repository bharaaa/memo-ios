//
//  PersistenceController.swift
//  Memo
//
//  Single source of truth for the SwiftData ModelContainer.
//
//  CloudKit-readiness: to enable sync, change ModelConfiguration to:
//    ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
//  No other changes are required.
//
//  First-launch seeding:
//  - Default expense & income categories
//  - "Cash" and "Bank" accounts using the user's chosen currency
//

import SwiftData
import Foundation

@MainActor
final class PersistenceController {

    static let shared = PersistenceController()

    let container: ModelContainer

    // All SwiftData model types must be registered here.
    static let schema = Schema([
        Transaction.self,
        Account.self,
        Category.self,
        Budget.self,
        Tag.self,
        Attachment.self,
        Merchant.self,
        RecurringTransaction.self,
        Transfer.self,
    ])

    private init() {
        let configuration = ModelConfiguration(
            schema: Self.schema,
            isStoredInMemoryOnly: false
            // Future: cloudKitDatabase: .automatic
        )
        do {
            container = try ModelContainer(for: Self.schema, configurations: [configuration])
        } catch {
            fatalError("PersistenceController: failed to create ModelContainer — \(error)")
        }
    }

    /// In-memory container for SwiftUI Previews and unit tests.
    static var preview: PersistenceController = {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let pc = PersistenceController()
        return pc
    }()

    // MARK: - First-Launch Seeding

    /// Call once after onboarding completes.
    /// Creates default categories and accounts if they don't already exist.
    func seedDefaultDataIfNeeded(currencyCode: String) throws {
        let context = container.mainContext

        // Guard: only seed once
        let categoryDescriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.isSystem == true }
        )
        let existingCategories = try context.fetch(categoryDescriptor)
        guard existingCategories.isEmpty else { return }

        // --- Expense Categories ---
        let expenseCategories: [(String, String, String, Int)] = [
            ("Food & Drink",    "fork.knife",              "#F97316", 0),
            ("Transport",       "car.fill",                "#3B82F6", 1),
            ("Shopping",        "bag.fill",                "#EC4899", 2),
            ("Entertainment",   "popcorn.fill",            "#8B5CF6", 3),
            ("Health",          "heart.fill",              "#EF4444", 4),
            ("Bills & Utilities","bolt.fill",              "#F59E0B", 5),
            ("Education",       "book.fill",               "#10B981", 6),
            ("Travel",          "airplane",                "#06B6D4", 7),
            ("Personal Care",   "sparkles",                "#F472B6", 8),
            ("Other",           "ellipsis.circle.fill",    "#6B7280", 9),
        ]

        var createdExpense: [Category] = []
        for (name, icon, hex, order) in expenseCategories {
            let cat = Category(
                name: name, icon: icon, colorHex: hex,
                categoryType: .expense, isSystem: true, sortOrder: order
            )
            context.insert(cat)
            createdExpense.append(cat)
        }

        // --- Income Categories ---
        let incomeCategories: [(String, String, String, Int)] = [
            ("Salary",      "briefcase.fill",       "#10B981", 0),
            ("Freelance",   "laptopcomputer",        "#6366F1", 1),
            ("Investment",  "chart.line.uptrend.xyaxis", "#F59E0B", 2),
            ("Gift",        "gift.fill",             "#EC4899", 3),
            ("Other Income","plus.circle.fill",      "#6B7280", 4),
        ]

        for (name, icon, hex, order) in incomeCategories {
            let cat = Category(
                name: name, icon: icon, colorHex: hex,
                categoryType: .income, isSystem: true, sortOrder: order
            )
            context.insert(cat)
        }

        // --- Default Accounts ---
        let cash = Account(
            name: "Cash",
            icon: "banknote",
            colorHex: "#10B981",
            currencyCode: currencyCode,
            accountType: .cash,
            isDefault: true      // Cash is the default account
        )
        let bank = Account(
            name: "Bank",
            icon: "building.columns",
            colorHex: "#3B82F6",
            currencyCode: currencyCode,
            accountType: .bank,
            isDefault: false
        )
        bank.sortOrder = 1

        context.insert(cash)
        context.insert(bank)

        try context.save()
    }
}
