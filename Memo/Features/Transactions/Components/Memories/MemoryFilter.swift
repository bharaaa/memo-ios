//
//  MemoryFilter.swift
//  Memo
//

import Foundation

enum MemoryFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case income = "Income"
    case expense = "Expense"
    case transfer = "Transfer"
    case cash = "Cash"
    case bank = "Bank"
    // Popular Categories
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case bills = "Bills"
    
    var id: String { rawValue }
    
    func applies(to transaction: Transaction) -> Bool {
        let calendar = Calendar.current
        
        switch self {
        case .today:
            return calendar.isDateInToday(transaction.date)
        case .thisWeek:
            return calendar.isDate(transaction.date, equalTo: Date(), toGranularity: .weekOfYear)
        case .thisMonth:
            return calendar.isDate(transaction.date, equalTo: Date(), toGranularity: .month)
        case .income:
            return transaction.transactionType == .income
        case .expense:
            return transaction.transactionType == .expense
        case .transfer:
            return transaction.transactionType == .transfer
        case .cash:
            return transaction.account?.accountType == .cash
        case .bank:
            return transaction.account?.accountType == .bank
        case .food:
            return transaction.category?.name.contains("Food") == true
        case .transport:
            return transaction.category?.name.contains("Transport") == true
        case .shopping:
            return transaction.category?.name.contains("Shopping") == true
        case .bills:
            return transaction.category?.name.contains("Bills") == true
        }
    }
}
