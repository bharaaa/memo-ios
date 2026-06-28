//
//  CategoryListView.swift
//  Memo
//
//  List of all categories grouped by type (Expense/Income) using native iOS HIG.
//

import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    
    @State private var searchText: String = ""
    @State private var categoryToEdit: Category?
    @State private var showAddSheet: Bool = false
    @State private var categoryToDelete: Category?
    @State private var showDeleteConfirmation: Bool = false
    
    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var expenseCategories: [Category] {
        filteredCategories.filter { $0.categoryType == .expense }
    }
    
    private var incomeCategories: [Category] {
        filteredCategories.filter { $0.categoryType == .income }
    }
    
    var body: some View {
        Group {
            if categories.isEmpty && searchText.isEmpty {
                EmptyCategoryView(onAddTapped: { showAddSheet = true })
            } else {
                List {
                    if !expenseCategories.isEmpty {
                        Section {
                            ForEach(expenseCategories) { category in
                                CategoryRowView(
                                    category: category,
                                    onEdit: { categoryToEdit = category },
                                    onDuplicate: { duplicate(category) },
                                    onDelete: { requestDelete(category) }
                                )
                            }
                        } header: {
                            Text("Expense").textCase(.none)
                        }
                    }
                    
                    if !incomeCategories.isEmpty {
                        Section {
                            ForEach(incomeCategories) { category in
                                CategoryRowView(
                                    category: category,
                                    onEdit: { categoryToEdit = category },
                                    onDuplicate: { duplicate(category) },
                                    onDelete: { requestDelete(category) }
                                )
                            }
                        } header: {
                            Text("Income").textCase(.none)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search categories")
                .animation(.default, value: filteredCategories)
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title3)
                }
            }
        }
        .sheet(item: $categoryToEdit) { category in
            NavigationStack {
                CategoryEditView(category: category)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                CategoryEditView(defaultType: .expense)
            }
        }
        .confirmationDialog(
            "Delete Category?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible,
            presenting: categoryToDelete
        ) { category in
            Button("Delete Category", role: .destructive) {
                delete(category)
            }
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
        } message: { category in
            Text("Transactions in '\(category.name)' will become uncategorized.")
        }
    }
    
    // MARK: - Actions
    
    private func duplicate(_ category: Category) {
        let newCategory = Category(
            name: "\(category.name) Copy",
            icon: category.icon,
            colorHex: category.colorHex,
            categoryType: category.categoryType,
            isSystem: false,
            sortOrder: categories.count
        )
        modelContext.insert(newCategory)
        try? modelContext.save()
    }
    
    private func requestDelete(_ category: Category) {
        categoryToDelete = category
        showDeleteConfirmation = true
    }
    
    private func delete(_ category: Category) {
        modelContext.delete(category)
        try? modelContext.save()
        categoryToDelete = nil
    }
}
