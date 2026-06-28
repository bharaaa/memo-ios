//
//  MemoSchemaV2.swift
//  Memo
//
//  Snapshot of the Multi-Currency architecture schema.
//

import SwiftData
import Foundation

enum MemoSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Transaction.self, Account.self, Category.self, Merchant.self, Attachment.self, Tag.self, RecurringTransaction.self, Budget.self, Transfer.self, ExchangeRate.self]
    }
    
    @Model
    final class Account {
        var id: UUID = UUID()
        var name: String = ""
        var icon: String = ""
        var colorHex: String = ""
        @Attribute(originalName: "currencyCode") var currencyCodeRaw: String = "IDR"
        @Attribute(originalName: "openingBalance") var openingBalanceAmount: Decimal = 0
        var accountType: Int = 0 
        var isDefault: Bool = false
        var isArchived: Bool = false
        var sortOrder: Int = 0
        var createdAt: Date = Date()
        
        @Relationship(deleteRule: .nullify)
        var transactions: [MemoSchemaV2.Transaction]?
        
        init() {}
    }
    
    @Model
    final class Transaction {
        var id: UUID = UUID()
        @Attribute(originalName: "amount") var originalMoneyAmount: Decimal = 0
        @Attribute(originalName: "currencyCode") var originalMoneyCurrencyRaw: String = "IDR"
        
        var convertedMoneyAmount: Decimal = 0
        var convertedMoneyCurrencyRaw: String = "IDR"
        
        var exchangeRate: Decimal = 1.0
        var exchangeRateDate: Date = Date()
        
        var note: String = ""
        var date: Date = Date()
        var paymentMethod: Int = 0
        var transactionType: Int = 0
        var source: Int = 0
        var confidence: Double = 1.0
        var isConfirmed: Bool = false
        var isProcessing: Bool = false
        var createdAt: Date = Date()
        var updatedAt: Date = Date()
        
        @Relationship(deleteRule: .nullify)
        var account: MemoSchemaV2.Account?
        
        var linkedTransferID: UUID?
        
        @Relationship(deleteRule: .nullify)
        var category: MemoSchemaV2.Category?
        
        @Relationship(deleteRule: .nullify)
        var merchant: MemoSchemaV2.Merchant?
        
        @Relationship(deleteRule: .cascade)
        var attachments: [MemoSchemaV2.Attachment]?
        
        @Relationship(deleteRule: .nullify)
        var tags: [MemoSchemaV2.Tag]?
        
        @Relationship(deleteRule: .nullify)
        var recurringSource: MemoSchemaV2.RecurringTransaction?
        
        init() {}
    }
    
    @Model final class Category { var id = UUID(); init() {} }
    @Model final class Merchant { var id = UUID(); init() {} }
    @Model final class Attachment { var id = UUID(); init() {} }
    @Model final class Tag { var id = UUID(); init() {} }
    @Model final class RecurringTransaction { var id = UUID(); init() {} }
    @Model final class Budget { var id = UUID(); init() {} }
    @Model final class Transfer { var id = UUID(); init() {} }
    @Model final class ExchangeRate { var id = UUID(); init() {} }
}
