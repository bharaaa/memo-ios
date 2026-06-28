//
//  TransactionService.swift
//  Memo
//
//  The only class that writes Transaction objects to SwiftData.
//  AI providers never write here directly — everything goes through
//  validate() → save(). This enforces the pipeline contract.
//

import Foundation
import SwiftData

@MainActor
final class TransactionService {

    private let repository: TransactionRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol
    private let categoryService: CategoryService
    private let context: ModelContext
    private let conversionEngine: ConversionEngine
    private let currencyService: CurrencyService

    init(
        repository: TransactionRepositoryProtocol,
        accountRepository: AccountRepositoryProtocol,
        categoryService: CategoryService,
        context: ModelContext,
        conversionEngine: ConversionEngine = ConversionEngine(),
        currencyService: CurrencyService = CurrencyService.shared
    ) {
        self.repository = repository
        self.accountRepository = accountRepository
        self.categoryService = categoryService
        self.context = context
        self.conversionEngine = conversionEngine
        self.currencyService = currencyService
    }

    // MARK: - Validation

    enum ValidationError: LocalizedError {
        case missingAmount
        case negativeAmount
        case missingAccount
        case missingDate

        var errorDescription: String? {
            switch self {
            case .missingAmount:   return "Please enter an amount."
            case .negativeAmount:  return "Amount must be greater than zero."
            case .missingAccount:  return "Please select an account."
            case .missingDate:     return "Please select a date."
            }
        }
    }

    func validate(_ parsed: ParsedTransaction) throws {
        // No longer enforcing strict validation at creation time
        // so that transactions can be saved immediately while LLM runs.
    }

    // MARK: - Save from ParsedTransaction

    /// Converts a validated ParsedTransaction into a Transaction and persists it.
    /// - Parameters:
    ///   - parsed: The validated AI result
    ///   - account: The account to associate (defaults to the first default account)
    ///   - preferredCurrency: Fallback currency if the AI didn't detect one
    @discardableResult
    func save(
        parsed: ParsedTransaction,
        account: Account?
    ) async throws -> Transaction {
        try validate(parsed)

        let resolvedAccount: Account?
        if let acc = account {
            resolvedAccount = acc
        } else if let hint = parsed.accountHint, let hintedAcc = fetchAccount(hint: hint) {
            resolvedAccount = hintedAcc
        } else {
            resolvedAccount = accountRepository.defaultAccount()
        }
        
        let originalCurrency: CurrencyCode
        if let acc = resolvedAccount {
            originalCurrency = acc.currencyCode
        } else {
            if let parsedCurrencyRaw = parsed.currencyCode, let parsedCurrency = CurrencyCode(rawValue: parsedCurrencyRaw) {
                originalCurrency = parsedCurrency
            } else {
                originalCurrency = currencyService.baseCurrency
            }
        }

        var finalAmount = parsed.amount!
        
        // If AI parsed a different currency than the account, we theoretically should convert it.
        // For now, if the user picks an IDR account, the money is stored as IDR.
        // If AI parsed USD, we convert it to the account's currency first.
        if let parsedCurrencyRaw = parsed.currencyCode,
           let parsedCurrency = CurrencyCode(rawValue: parsedCurrencyRaw),
           parsedCurrency != originalCurrency {
            let parsedMoney = Money(amount: finalAmount, currencyCode: parsedCurrency)
            let conversion = try await conversionEngine.convert(parsedMoney, to: originalCurrency)
            finalAmount = conversion.convertedMoney.amount
        }
        
        let originalMoney = Money(amount: finalAmount, currencyCode: originalCurrency)
        
        // Convert to Base Currency for reports/summaries
        let baseCurrency = currencyService.baseCurrency
        let conversion = try await conversionEngine.convert(originalMoney, to: baseCurrency)
        
        let transaction = Transaction(
            originalMoney: originalMoney,
            convertedMoney: conversion.convertedMoney,
            exchangeRate: conversion.rate,
            exchangeRateDate: Date(),
            note: parsed.note ?? "",
            date: parsed.date ?? Date(),
            paymentMethod: parsed.paymentMethod ?? .cash,
            transactionType: parsed.transactionType,
            source: .chat,
            confidence: parsed.confidence,
            isConfirmed: true
        )

        transaction.account = resolvedAccount

        // Resolve category from hint
        if let hint = parsed.categoryHint {
            transaction.category = categoryService.match(hint: hint)
        }

        // Find or create merchant
        if let merchantName = parsed.merchantName, !merchantName.isEmpty {
            transaction.merchant = findOrCreateMerchant(
                named: merchantName,
                suggestedCategory: transaction.category
            )
        }

        try repository.save(transaction)

        return transaction
    }

    // MARK: - Direct Save

    /// Saves an already-constructed Transaction (from the preview/edit screen).
    func save(_ transaction: Transaction) async throws {
        guard let account = transaction.account else { throw ValidationError.missingAccount }
        
        // Ensure the transaction currency matches the account currency
        if transaction.originalMoney.currencyCode != account.currencyCode {
            transaction.originalMoney = Money(amount: transaction.originalMoney.amount, currencyCode: account.currencyCode)
        }
        
        // Always re-convert when saving manually to ensure base currency is up to date
        let baseCurrency = currencyService.baseCurrency
        let conversion = try await conversionEngine.convert(transaction.originalMoney, to: baseCurrency)
        
        transaction.convertedMoney = conversion.convertedMoney
        transaction.exchangeRate = conversion.rate
        // We do NOT update exchangeRateDate here if it's an old transaction, 
        // to preserve historical rates. But if it's a new edit, we might.
        // For simplicity, we just keep the original date unless it's a brand new transaction.
        
        transaction.updatedAt = Date()
        try repository.save(transaction)
    }

    // MARK: - Delete

    func delete(_ transaction: Transaction) throws {
        try repository.delete(transaction)
    }

    // MARK: - Transfer
    
    @discardableResult
    func createTransfer(
        amount: Decimal, // The amount in the source account's currency
        from sourceAccount: Account,
        to destinationAccount: Account,
        date: Date = Date(),
        note: String = ""
    ) async throws -> Transfer {
        guard amount > 0 else { throw ValidationError.negativeAmount }

        let sourceMoney = Money(amount: amount, currencyCode: sourceAccount.currencyCode)
        let baseCurrency = currencyService.baseCurrency
        let conversion = try await conversionEngine.convert(sourceMoney, to: baseCurrency)
        
        let transfer = Transfer(
            money: sourceMoney,
            date: date,
            note: note,
            fromAccount: sourceAccount,
            toAccount: destinationAccount
        )
        context.insert(transfer)

        let debit = Transaction(
            originalMoney: sourceMoney,
            convertedMoney: conversion.convertedMoney,
            exchangeRate: conversion.rate,
            exchangeRateDate: date,
            note: note.isEmpty ? "Transfer to \(destinationAccount.name)" : note,
            date: date,
            paymentMethod: .transfer,
            transactionType: .expense,
            source: .manual,
            confidence: 1.0,
            isConfirmed: true
        )
        debit.account = sourceAccount
        debit.linkedTransferID = transfer.id
        context.insert(debit)
        transfer.debitTransaction = debit

        // Credit side needs to be in destination account's currency
        let destConversion = try await conversionEngine.convert(sourceMoney, to: destinationAccount.currencyCode)
        let destMoney = destConversion.convertedMoney
        let destToBaseConversion = try await conversionEngine.convert(destMoney, to: baseCurrency)
        
        let credit = Transaction(
            originalMoney: destMoney,
            convertedMoney: destToBaseConversion.convertedMoney,
            exchangeRate: destToBaseConversion.rate,
            exchangeRateDate: date,
            note: note.isEmpty ? "Transfer from \(sourceAccount.name)" : note,
            date: date,
            paymentMethod: .transfer,
            transactionType: .income,
            source: .manual,
            confidence: 1.0,
            isConfirmed: true
        )
        credit.account = destinationAccount
        credit.linkedTransferID = transfer.id
        context.insert(credit)
        transfer.creditTransaction = credit

        try repository.saveTransfer(transfer: transfer, debit: debit, credit: credit)
        return transfer
    }
    
    // MARK: - Duplicate
    
    @discardableResult
    func duplicate(_ transaction: Transaction) async throws -> Transaction {
        let newTransaction = Transaction(
            originalMoney: transaction.originalMoney,
            convertedMoney: transaction.convertedMoney, // will be re-calculated in save
            exchangeRate: transaction.exchangeRate,
            exchangeRateDate: Date(),
            note: transaction.note + " (Copy)",
            date: Date(), // Usually duplicates are for a new date (today)
            paymentMethod: transaction.paymentMethod,
            transactionType: transaction.transactionType,
            source: transaction.source,
            confidence: transaction.confidence,
            isConfirmed: transaction.isConfirmed
        )
        newTransaction.account = transaction.account
        newTransaction.category = transaction.category
        newTransaction.merchant = transaction.merchant
        
        try await save(newTransaction)
        
        return newTransaction
    }

    // MARK: - Update

    func update(_ transaction: Transaction) async throws {
        try await save(transaction)
    }


    
    private func fetchAccount(hint: String) -> Account? {
        let normalised = hint.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isArchived == false }
        )
        if let accounts = try? context.fetch(descriptor) {
            return accounts.first { $0.name.lowercased() == normalised }
        }
        return nil
    }

    private func findOrCreateMerchant(named name: String, suggestedCategory: Category?) -> Merchant {
        let normalised = name.lowercased().trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<Merchant>(
            predicate: #Predicate { $0.normalizedName == normalised }
        )
        if let existing = try? context.fetch(descriptor).first {
            // Update default category if we now have a better suggestion
            if existing.defaultCategory == nil, let cat = suggestedCategory {
                existing.defaultCategory = cat
            }
            return existing
        }

        let merchant = Merchant(name: name.capitalized, defaultCategory: suggestedCategory)
        context.insert(merchant)
        return merchant
    }
}
