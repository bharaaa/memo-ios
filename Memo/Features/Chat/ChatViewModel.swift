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

        let id: UUID = UUID()
        let role: Role
        let content: Content
        let timestamp: Date = Date()

        static func user(_ text: String)            -> Message { .init(role: .user, content: .text(text)) }
        static func memo(_ text: String)            -> Message { .init(role: .memo, content: .text(text)) }
        static func parsed(_ pt: ParsedTransaction) -> Message { .init(role: .memo, content: .parsedTransaction(pt)) }
        static func error(_ msg: String)            -> Message { .init(role: .memo, content: .error(msg)) }
    }

    // MARK: - State

    var messages: [Message] = []
    var inputText = ""
    var isProcessing = false
    var showingPreview: ParsedTransaction?

    // MARK: - Dependencies

    private let memoService: MemoService
    private let transactionService: TransactionService

    // MARK: - Init

    init(memoService: MemoService, transactionService: TransactionService) {
        self.memoService = memoService
        self.transactionService = transactionService
    }

    // MARK: - Send

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        messages.append(.user(text))
        isProcessing = true

        do {
            let parsed = try await memoService.parse(input: text)
            isProcessing = false

            if parsed.isUsable {
                messages.append(.parsed(parsed))
            } else {
                messages.append(.memo("I couldn't quite understand that. Could you try again with an amount?"))
            }
        } catch AIProviderError.unavailable {
            isProcessing = false
            messages.append(.error("AI is not available right now. Try a simpler format like \"Coffee 35k\"."))
        } catch {
            isProcessing = false
            messages.append(.error("Something went wrong: \(error.localizedDescription)"))
        }
    }

    // MARK: - Save from preview

    func save(parsed: ParsedTransaction, account: Account?, currency: String) throws -> Transaction {
        try transactionService.save(
            parsed: parsed,
            account: account,
            preferredCurrency: currency
        )
    }

    // MARK: - Confirm transaction from bubble

    func confirmTransaction(_ parsed: ParsedTransaction) {
        showingPreview = parsed
    }
}
