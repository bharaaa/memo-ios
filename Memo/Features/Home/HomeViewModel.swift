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
    
    var recentTransactions: [Transaction] = []
    var totalAssets: Decimal = 0
    var timeGreeting: String = ""
    var userGreetingName: String = ""
    
    // Composer State
    var inputText: String = ""
    var isProcessing: Bool = false
    var parsedTransaction: ParsedTransaction?
    var parseError: String?
    
    // Accounts State
    var accounts: [Account] = []

    // MARK: - Dependencies

    private let transactionRepository: TransactionRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol
    private let memoService: MemoService
    private let currency: String
    private let userName: String

    // MARK: - Init

    init(
        transactionRepository: TransactionRepositoryProtocol,
        accountRepository: AccountRepositoryProtocol,
        memoService: MemoService,
        currency: String,
        userName: String
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.memoService = memoService
        self.currency = currency
        self.userName = userName
    }

    // MARK: - Load

    func load() {
        recentTransactions = transactionRepository.recentTransactions(limit: 5)
        totalAssets = accountRepository.totalAssets()
        accounts = accountRepository.allAccounts()
        let (time, name) = buildGreetingParts()
        timeGreeting = time
        userGreetingName = name
    }

    // MARK: - Greeting

    private func buildGreetingParts() -> (String, String) {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeString: String
        switch hour {
        case 5..<12:  timeString = "Good morning"
        case 12..<17: timeString = "Good afternoon"
        case 17..<21: timeString = "Good evening"
        default:      timeString = "Good night"
        }
        return (timeString, userName.isEmpty ? "" : userName)
    }
    
    // MARK: - Composer Actions
    
    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isProcessing = true
        parseError = nil
        
        do {
            let parsed = try await memoService.parse(input: text)
            isProcessing = false
            
            if parsed.isUsable {
                parsedTransaction = parsed
                inputText = ""
            } else {
                parseError = "I couldn't quite understand that. Could you try again with an amount?"
            }
        } catch AIProviderError.unavailable {
            isProcessing = false
            parseError = "AI is not available right now. Try a simpler format like \"Coffee 35k\"."
        } catch {
            isProcessing = false
            parseError = "Something went wrong: \(error.localizedDescription)"
        }
    }

    // MARK: - Balance Formatting
    
    var formattedTotalAssets: String {
        totalAssets.formatted(currency: currency)
    }
}
