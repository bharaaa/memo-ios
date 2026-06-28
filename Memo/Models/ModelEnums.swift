//
//  ModelEnums.swift
//  Memo
//
//  Centralised enum definitions shared across models, AI providers,
//  and UI layers. Adding a case here is the only change required
//  when the domain grows.
//

import Foundation

// MARK: - Transaction

enum TransactionType: String, Codable, CaseIterable, Sendable {
    case expense = "expense"
    case income  = "income"
    case transfer = "transfer"

    var displayName: String {
        switch self {
        case .expense:  return "Expense"
        case .income:   return "Income"
        case .transfer: return "Transfer"
        }
    }

    var symbol: String {
        switch self {
        case .expense:  return "arrow.up.circle.fill"
        case .income:   return "arrow.down.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Sendable {
    case cash     = "cash"
    case debit    = "debit"
    case credit   = "credit"
    case transfer = "transfer"
    case other    = "other"

    var displayName: String {
        switch self {
        case .cash:     return "Cash"
        case .debit:    return "Debit Card"
        case .credit:   return "Credit Card"
        case .transfer: return "Bank Transfer"
        case .other:    return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .cash:     return "banknote"
        case .debit:    return "creditcard"
        case .credit:   return "creditcard.fill"
        case .transfer: return "arrow.left.arrow.right"
        case .other:    return "questionmark.circle"
        }
    }
}

/// Where the transaction data originally came from.
enum TransactionSource: String, Codable, Sendable {
    case manual    = "manual"
    case chat      = "chat"
    case ocr       = "ocr"
    case share     = "share"
    case `import`  = "import"
    case recurring = "recurring"

    var displayName: String {
        switch self {
        case .manual:    return "Manual"
        case .chat:      return "Chat"
        case .ocr:       return "Scan / OCR"
        case .share:     return "Share Extension"
        case .import:    return "Import"
        case .recurring: return "Recurring"
        }
    }
}

// MARK: - Account

enum AccountType: String, Codable, CaseIterable, Sendable {
    case cash       = "cash"
    case bank       = "bank"
    case credit     = "credit"
    case investment = "investment"
    case savings    = "savings"

    var displayName: String {
        switch self {
        case .cash:       return "Cash"
        case .bank:       return "Bank Account"
        case .credit:     return "Credit Card"
        case .investment: return "Investment"
        case .savings:    return "Savings"
        }
    }

    var symbol: String {
        switch self {
        case .cash:       return "banknote"
        case .bank:       return "building.columns"
        case .credit:     return "creditcard.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .savings:    return "dollarsign.circle"
        }
    }
}

// MARK: - Category

enum CategoryType: String, Codable, CaseIterable, Sendable {
    case expense = "expense"
    case income  = "income"

    var displayName: String {
        switch self {
        case .expense: return "Expense"
        case .income:  return "Income"
        }
    }
}

// MARK: - Budget

enum BudgetPeriod: String, Codable, CaseIterable, Sendable {
    case weekly  = "weekly"
    case monthly = "monthly"
    case yearly  = "yearly"

    var displayName: String {
        switch self {
        case .weekly:  return "Weekly"
        case .monthly: return "Monthly"
        case .yearly:  return "Yearly"
        }
    }
}

// MARK: - Recurring

enum RecurrenceFrequency: String, Codable, CaseIterable, Sendable {
    case daily     = "daily"
    case weekly    = "weekly"
    case biweekly  = "biweekly"
    case monthly   = "monthly"
    case quarterly = "quarterly"
    case yearly    = "yearly"

    var displayName: String {
        switch self {
        case .daily:     return "Daily"
        case .weekly:    return "Weekly"
        case .biweekly:  return "Every 2 Weeks"
        case .monthly:   return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly:    return "Yearly"
        }
    }
}
