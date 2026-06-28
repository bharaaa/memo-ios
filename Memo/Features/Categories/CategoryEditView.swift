//
//  CategoryEditView.swift
//  Memo
//

import SwiftUI
import SwiftData

@MainActor
struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let existingCategory: Category?
    let defaultType: TransactionType
    
    @State private var name: String = ""
    @State private var icon: String = "tag.fill"
    @State private var colorHex: String = "#6366F1"
    @State private var categoryType: CategoryType = .expense
    
    @State private var showIconPicker = false
    @State private var showColorPicker = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    
    init(category: Category? = nil, defaultType: TransactionType = .expense) {
        self.existingCategory = category
        self.defaultType = defaultType
    }
    
    var body: some View {
        Form {
            Section("Category Details") {
                TextField("Name", text: $name)
                
                Picker("Type", selection: $categoryType) {
                    ForEach(CategoryType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .disabled(existingCategory?.isSystem == true)
            }
            
            Section("Appearance") {
                Button {
                    showIconPicker = true
                } label: {
                    HStack {
                        Text("Icon")
                            .foregroundStyle(.memoPrimaryText)
                        Spacer()
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(Color(hex: colorHex))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.memoTertiaryText)
                            .padding(.leading, 8)
                    }
                }
                
                Button {
                    showColorPicker = true
                } label: {
                    HStack {
                        Text("Color")
                            .foregroundStyle(.memoPrimaryText)
                        Spacer()
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 24, height: 24)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.memoTertiaryText)
                            .padding(.leading, 8)
                    }
                }
            }
            
            if let category = existingCategory, !category.isSystem {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Category")
                            Spacer()
                        }
                    }
                }
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.memoExpense)
                        .font(.memoCaption)
                }
            }
        }
        .navigationTitle(existingCategory != nil ? "Edit Category" : "New Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(.memoSecondaryText)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showIconPicker) {
            NavigationStack {
                IconPickerView(selectedIcon: $icon)
                    .navigationTitle("Select Icon")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showIconPicker = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showColorPicker) {
            NavigationStack {
                ColorPickerGrid(selectedHex: $colorHex)
                    .navigationTitle("Select Color")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showColorPicker = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Delete Category?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Category", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Transactions in this category will become uncategorized.")
        }
        .onAppear { loadData() }
    }
    
    private func loadData() {
        if let cat = existingCategory {
            name = cat.name
            icon = cat.icon
            colorHex = cat.colorHex
            categoryType = cat.categoryType
        } else {
            categoryType = defaultType == .income ? .income : .expense
        }
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a name."
            return
        }
        
        if let cat = existingCategory {
            cat.name = trimmedName
            cat.icon = icon
            cat.colorHex = colorHex
            cat.categoryType = categoryType
        } else {
            let cat = Category(name: trimmedName, icon: icon, colorHex: colorHex, categoryType: categoryType)
            modelContext.insert(cat)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
    
    private func delete() {
        guard let cat = existingCategory else { return }
        modelContext.delete(cat)
        try? modelContext.save()
        dismiss()
    }
}
