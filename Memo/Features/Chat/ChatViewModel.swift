//
//  ChatViewModel.swift
//  Memo
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class ChatViewModel {

    // MARK: - Types

    struct Message: Identifiable {
        enum Role { case user, memo }
        enum Content {
            case text(String)
            case parsedTransaction(ParsedTransaction)
            case error(String)
        }

        let id: UUID
        let role: Role
        let content: Content
        let timestamp: Date

        static func user(_ text: String)            -> Message { .init(id: UUID(), role: .user, content: .text(text), timestamp: Date()) }
        static func memo(_ text: String)            -> Message { .init(id: UUID(), role: .memo, content: .text(text), timestamp: Date()) }
        static func parsed(_ pt: ParsedTransaction) -> Message { .init(id: UUID(), role: .memo, content: .parsedTransaction(pt), timestamp: Date()) }
        static func error(_ msg: String)            -> Message { .init(id: UUID(), role: .memo, content: .error(msg), timestamp: Date()) }
    }

    // MARK: - State

    var messages: [Message] = []
    var inputText = ""
    var isProcessing = false
    var showingPreview: ParsedTransaction?
    
    /// Set when user saves while LLM is still running.
    private var didSaveCurrentStream = false
    var pendingEnrichment: ParsedTransaction?
    private var savedTransaction: Transaction?

    // MARK: - Dependencies

    private let memoService: MemoService
    private let transactionService: TransactionService
    private let categoryService: CategoryService?
    private let accountRepository: AccountRepositoryProtocol

    // MARK: - Init

    init(
        memoService: MemoService,
        transactionService: TransactionService,
        categoryService: CategoryService? = nil,
        accountRepository: AccountRepositoryProtocol
    ) {
        self.memoService = memoService
        self.transactionService = transactionService
        self.categoryService = categoryService
        self.accountRepository = accountRepository
    }

    // MARK: - Send

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        messages.append(.user(text))
        isProcessing = true
        didSaveCurrentStream = false
        pendingEnrichment = nil
        
        let stream = memoService.parseStream(input: text)
        var firstYield = true
        
        // We need an ID to update the exact same message in the array
        var processingMessageId: UUID?

        do {
            for await tx in stream {
                if firstYield {
                    isProcessing = false
                    if tx.isUsable {
                        let msg = Message.parsed(tx)
                        processingMessageId = msg.id
                        messages.append(msg)
                    } else {
                        messages.append(.memo("I couldn't quite understand that. Could you try again with an amount?"))
                        break
                    }
                    firstYield = false
                } else {
                    if didSaveCurrentStream {
                        // User already saved — store for deferred patching
                        if tx.status != .failed {
                            pendingEnrichment = tx
                            patchSavedTransactionIfNeeded(with: tx)
                        }
                    } else {
                        // Preview still open — update message in place
                        if let id = processingMessageId, let index = messages.firstIndex(where: { $0.id == id }) {
                            if tx.status != .failed {
                                messages[index] = Message(id: id, role: .memo, content: .parsedTransaction(tx), timestamp: messages[index].timestamp)
                            }
                        }
                    }
                }
            }
        } catch {
            isProcessing = false
            messages.append(.error("Something went wrong: \(error.localizedDescription)"))
        }
    }
    
    /// Called when user saves from preview while LLM may still be running.
    func markAsSaved(transaction: Transaction? = nil) {
        didSaveCurrentStream = true
        showingPreview = nil
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
            let accounts = accountRepository.allAccounts()
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
        
        if tx.originalMoneyAmount == .zero, let amt = enriched.amount, amt > 0 {
            tx.originalMoneyAmount = amt
            tx.convertedMoneyAmount = amt // Rough fallback without API lookup, fine for late patch
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
    }

    // MARK: - Save from preview

    func save(parsed: ParsedTransaction, account: Account?, currency: String) async throws -> Transaction {
        try await transactionService.save(
            parsed: parsed,
            account: account
        )
    }

    // MARK: - Confirm transaction from bubble

    func confirmTransaction(_ parsed: ParsedTransaction) {
        showingPreview = parsed
    }
}
