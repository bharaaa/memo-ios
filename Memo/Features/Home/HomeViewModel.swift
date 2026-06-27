//
//  HomeViewModel.swift
//  Memo
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - State

    var todayTransactions: [Transaction] = []
    var todayTotal: Decimal = 0
    var greeting: String = ""

    // MARK: - Dependencies

    private let transactionService: TransactionService
    private let currency: String
    private let userName: String

    // MARK: - Init

    init(transactionService: TransactionService, currency: String, userName: String) {
        self.transactionService = transactionService
        self.currency = currency
        self.userName = userName
    }

    // MARK: - Load

    func load() {
        todayTransactions = transactionService.todaysTransactions()
        todayTotal = todayTransactions
            .filter { $0.transactionType == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
        greeting = buildGreeting()
    }

    // MARK: - Greeting

    private func buildGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12:  timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<21: timeGreeting = "Good evening"
        default:      timeGreeting = "Good night"
        }
        let name = userName.isEmpty ? "" : ", \(userName)"
        return "\(timeGreeting)\(name) 👋"
    }

    // MARK: - Today Summary

    var todaySummaryText: String {
        if todayTransactions.isEmpty { return "Nothing recorded yet today" }
        let count = todayTransactions.count
        let word = count == 1 ? "transaction" : "transactions"
        return "\(count) \(word) today"
    }

    var formattedTodayTotal: String {
        todayTotal.formatted(currency: currency)
    }
}
