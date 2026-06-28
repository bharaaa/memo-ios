//
//  MemoMigrationPlan.swift
//  Memo
//
//  Handles the migration from V1 (primitive amounts) to V2 (Money value objects).
//

import SwiftData
import Foundation

enum MemoMigrationPlan: SchemaMigrationPlan {
    
    static var schemas: [VersionedSchema.Type] {
        [MemoSchemaV1.self, MemoSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: MemoSchemaV1.self,
        toVersion: MemoSchemaV2.self,
        willMigrate: { context in
            // Pre-migration logic if needed
        },
        didMigrate: { context in
            // Post-migration logic
            // Fetch all V2 transactions
            let transactions = try? context.fetch(FetchDescriptor<MemoSchemaV2.Transaction>())
            transactions?.forEach { transaction in
                // Converted Money (defaults to original for existing data)
                transaction.convertedMoneyAmount = transaction.originalMoneyAmount
                transaction.convertedMoneyCurrencyRaw = transaction.originalMoneyCurrencyRaw
                
                transaction.exchangeRate = 1.0
                transaction.exchangeRateDate = transaction.date
            }
            
            try? context.save()
        }
    )
}
