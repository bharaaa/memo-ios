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
    
    /// Set to true after user saves — prevents the stream from
    /// reopening the preview sheet with subsequent LLM yields.
    private var didSave = false
    
    /// Holds the final LLM-enriched result after user already saved.
    /// The TransactionPreviewViewModel reads this for deferred patching.
    var pendingEnrichment: ParsedTransaction?
    
    /// Reference to the saved Transaction for deferred patching.
    private var savedTransaction: Transaction?
    
    // Accounts State
    var accounts: [Account] = []

    // MARK: - Dependencies

    private let transactionRepository: TransactionRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol
    private let memoService: MemoService
    private let categoryService: CategoryService?
    private let currency: String
    private let userName: String

    // MARK: - Init

    init(
        transactionRepository: TransactionRepositoryProtocol,
        accountRepository: AccountRepositoryProtocol,
        memoService: MemoService,
        categoryService: CategoryService? = nil,
        currency: String,
        userName: String
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.memoService = memoService
        self.categoryService = categoryService
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
        didSave = false
        pendingEnrichment = nil
        
        let stream = memoService.parseStream(input: text)
        var firstYield = true
        
        do {
            for await tx in stream {
                if firstYield {
                    isProcessing = false
                    if tx.isUsable {
                        parsedTransaction = tx
                        inputText = ""
                    } else {
                        parseError = "I couldn't quite understand that. Could you try again with an amount?"
                        break
                    }
                    firstYield = false
                } else {
                    if didSave {
                        // User already saved — don't touch parsedTransaction.
                        // Store enrichment for deferred patching instead.
                        if tx.status != .failed {
                            pendingEnrichment = tx
                            patchSavedTransactionIfNeeded(with: tx)
                        }
                    } else {
                        // Preview is still open — update it live
                        if tx.status != .failed {
                            parsedTransaction = tx
                        }
                    }
                }
            }
        } catch {
            isProcessing = false
            parseError = "Something went wrong: \(error.localizedDescription)"
        }
    }
    
    /// Called by the preview sheet's onSaved callback.
    func markAsSaved(transaction: Transaction? = nil) {
        didSave = true
        parsedTransaction = nil
        if let tx = transaction {
            savedTransaction = tx
        }
    }
    
    /// Silently patches category/note onto the already-saved Transaction.
    private func patchSavedTransactionIfNeeded(with enriched: ParsedTransaction) {
        guard let tx = savedTransaction else { return }
        var didChange = false
        
        if tx.category == nil {
            if let hint = enriched.categoryHint,
               let cat = categoryService?.match(hint: hint) {
                tx.category = cat
                didChange = true
            } else if let merchant = enriched.merchantName,
                      let cat = categoryService?.match(hint: merchant) {
                tx.category = cat
                didChange = true
            }
        }
        
        if (tx.note.isEmpty), let note = enriched.note, !note.isEmpty {
            tx.note = note
            didChange = true
        }
        
        if let hint = enriched.accountHint?.lowercased(), !hint.isEmpty {
            // Find a matching account
            if let matched = accounts.first(where: { $0.name.lowercased().contains(hint) }) {
                if tx.account?.id != matched.id {
                    tx.account = matched
                    didChange = true
                }
            }
        }
        
        if let pm = enriched.paymentMethod, pm != .cash, tx.paymentMethod == .cash {
            tx.paymentMethod = pm
            didChange = true
        }
        
        if didChange {
            tx.isProcessing = false
            tx.updatedAt = Date()
            // SwiftData auto-saves on context changes
        } else {
            tx.isProcessing = false
        }
        
        savedTransaction = nil
        load()
    }

    // MARK: - Balance Formatting
    
    var formattedTotalAssets: String {
        totalAssets.formatted(currency: currency)
    }
}
