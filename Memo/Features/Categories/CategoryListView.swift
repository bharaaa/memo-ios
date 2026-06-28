//
//  CategoryListView.swift
//  Memo
//
//  List of all categories grouped by type (Expense/Income).
//

import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    
    private var expenseCategories: [Category] {
        categories.filter { $0.categoryType == .expense }
    }
    
    private var incomeCategories: [Category] {
        categories.filter { $0.categoryType == .income }
    }
    
    var body: some View {
        List {
            Section("Expenses") {
                ForEach(expenseCategories) { category in
                    categoryRow(category)
                }
                .onMove { moveCategories(from: $0, to: $1, in: expenseCategories) }
            }
            
            Section("Income") {
                ForEach(incomeCategories) { category in
                    categoryRow(category)
                }
                .onMove { moveCategories(from: $0, to: $1, in: incomeCategories) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: "new_category") {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: Category.self) { category in
            CategoryEditView(category: category)
        }
        .navigationDestination(for: String.self) { value in
            if value == "new_category" {
                CategoryEditView(defaultType: .expense)
            }
        }
    }
    
    private func categoryRow(_ category: Category) -> some View {
        NavigationLink(value: category) {
            HStack(spacing: 16) {
                CategoryBadge(category: category, style: .filled)
                
                if category.isSystem {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.memoTertiaryText)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int, in list: [Category]) {
        var ordered = list
        ordered.move(fromOffsets: source, toOffset: destination)
        
        for (index, category) in ordered.enumerated() {
            category.sortOrder = index
        }
        
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        CategoryListView()
            .modelContainer(PersistenceController.shared.container)
    }
}
