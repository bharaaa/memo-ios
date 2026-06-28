//
//  CategoryRepository.swift
//  Memo
//
//  Handles all persistence and querying of categories.
//

import Foundation
import SwiftData

@MainActor
final class CategoryRepository: CategoryRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func allCategories(type: TransactionType) -> [Category] {
        var descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        // Map TransactionType to CategoryType
        let catType: CategoryType = type == .income ? .income : .expense
        descriptor.predicate = #Predicate { $0.categoryType == catType }
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func allCategories() -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func category(byName name: String) -> Category? {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == name }
        )
        return try? context.fetch(descriptor).first
    }
    
    func defaultCategory(for type: TransactionType) -> Category? {
        return allCategories(type: type).first
    }
    
    func save(_ category: Category) throws {
        context.insert(category)
        try context.save()
    }
    
    func delete(_ category: Category) throws {
        context.delete(category)
        try context.save()
    }
}
