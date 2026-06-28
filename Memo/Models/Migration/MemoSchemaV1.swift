//
//  MemoSchemaV1.swift
//  Memo
//
//  Snapshot of the original schema before Multi-Currency architecture.
//

import SwiftData
import Foundation

enum MemoSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Transaction.self, Account.self, Category.self, Merchant.self, Attachment.self, Tag.self, RecurringTransaction.self, Budget.self, Transfer.self]
    }
    
    // Note: To make this compile, we must either redefine all V1 models here, or rely on the fact that 
    // SwiftData can often infer V1 if we use lightweight migration. But since we change property types (amount -> Money),
    // it's not lightweight. We must explicitly define the V1 models.
    
    @Model
    final class Account {
        var id: UUID = UUID()
        var name: String = ""
        var icon: String = ""
        var colorHex: String = ""
        var currencyCode: String = ""
        var openingBalance: Decimal = 0
        var accountType: Int = 0 // Using Int for enum
        var isDefault: Bool = false
        var isArchived: Bool = false
        var sortOrder: Int = 0
        var createdAt: Date = Date()
        
        @Relationship(deleteRule: .nullify)
        var transactions: [MemoSchemaV1.Transaction]?
        
        init() {}
    }
    
    @Model
    final class Transaction {
        var id: UUID = UUID()
        var amount: Decimal = 0
        var currencyCode: String = ""
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
        var account: MemoSchemaV1.Account?
        
        var linkedTransferID: UUID?
        
        @Relationship(deleteRule: .nullify)
        var category: MemoSchemaV1.Category?
        
        @Relationship(deleteRule: .nullify)
        var merchant: MemoSchemaV1.Merchant?
        
        @Relationship(deleteRule: .cascade)
        var attachments: [MemoSchemaV1.Attachment]?
        
        @Relationship(deleteRule: .nullify)
        var tags: [MemoSchemaV1.Tag]?
        
        @Relationship(deleteRule: .nullify)
        var recurringSource: MemoSchemaV1.RecurringTransaction?
        
        init() {}
    }
    
    @Model final class Category { var id = UUID(); init() {} }
    @Model final class Merchant { var id = UUID(); init() {} }
    @Model final class Attachment { var id = UUID(); init() {} }
    @Model final class Tag { var id = UUID(); init() {} }
    @Model final class RecurringTransaction { var id = UUID(); init() {} }
    @Model final class Budget { var id = UUID(); init() {} }
    @Model final class Transfer { var id = UUID(); init() {} }
}
