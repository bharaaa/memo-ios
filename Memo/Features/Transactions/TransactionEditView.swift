//
//  TransactionEditView.swift
//  Memo
//
//  Full-featured edit screen for an existing transaction.
//  Similar to TransactionPreviewView but updates the existing model directly.
//

import SwiftUI
import SwiftData

struct TransactionEditView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let transaction: Transaction
    
    @State private var amountString: String = ""
    @State private var merchantName: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var paymentMethod: PaymentMethod = .cash
    @State private var transactionType: TransactionType = .expense
    @State private var selectedAccount: Account?
    @State private var selectedCategory: Category?
    @State private var currencyCode: String = "IDR"
    
    @State private var showAccountPicker = false
    @State private var showCategoryPicker = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Amount hero
                    amountSection
                    
                    // Form fields
                    VStack(spacing: 0) {
                        // Type toggle
                        formRow {
                            HStack {
                                Label("Type", systemImage: "arrow.up.arrow.down.circle")
                                    .foregroundStyle(.memoSecondaryText)
                                    .font(.memoBody)
                                Spacer()
                                Picker("Type", selection: $transactionType) {
                                    ForEach(TransactionType.allCases, id: \.self) { t in
                                        Text(t.displayName).tag(t)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 200)
                            }
                        }
                        divider
                        
                        // Merchant
                        formRow {
                            HStack {
                                Label("Merchant", systemImage: "storefront")
                                    .foregroundStyle(.memoSecondaryText)
                                    .font(.memoBody)
                                Spacer()
                                TextField("e.g. Grab", text: $merchantName)
                                    .multilineTextAlignment(.trailing)
                                    .font(.memoBody)
                            }
                        }
                        divider
                        
                        // Category
                        formRow {
                            HStack {
                                Label("Category", systemImage: "tag")
                                    .foregroundStyle(.memoSecondaryText)
                                    .font(.memoBody)
                                Spacer()
                                if let cat = selectedCategory {
                                    CategoryBadge(category: cat, style: .filled)
                                } else {
                                    Text("None")
                                        .font(.memoBody)
                                        .foregroundStyle(.memoTertiaryText)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.memoTertiaryText)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { showCategoryPicker = true }
                        }
                        divider
                        
                        // Account
                        formRow {
                            HStack {
                                Label("Account", systemImage: "creditcard")
                                    .foregroundStyle(.memoSecondaryText)
                                    .font(.memoBody)
                                Spacer()
                                Text(selectedAccount?.name ?? "None")
                                    .font(.memoBody)
                                    .foregroundStyle(.memoPrimaryText)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.memoTertiaryText)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { showAccountPicker = true }
                        }
                        divider
                        
                        // Date
                        formRow {
                            DatePicker(
                                "Date",
                                selection: $date,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .font(.memoBody)
                        }
                        divider
                        
                        // Payment method
                        formRow {
                            HStack {
                                Label("Payment", systemImage: "banknote")
                                    .foregroundStyle(.memoSecondaryText)
                                    .font(.memoBody)
                                Spacer()
                                Picker("Payment", selection: $paymentMethod) {
                                    ForEach(PaymentMethod.allCases, id: \.self) { m in
                                        Text(m.displayName).tag(m)
                                    }
                                }
                            }
                        }
                        divider
                        
                        // Note
                        formRow {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Note", systemImage: "text.alignleft")
                                    .foregroundStyle(.memoSecondaryText)
                                    .font(.memoBody)
                                TextField("Optional note", text: $note, axis: .vertical)
                                    .font(.memoBody)
                                    .lineLimit(1...4)
                            }
                        }
                    }
                    .background(Color.memoCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.memoSubheadline)
                            .foregroundStyle(.memoExpense)
                            .padding()
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.memoBackground)
            .navigationTitle("Edit Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.memoSecondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveTransaction() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                categoryPickerSheet
            }
            .sheet(isPresented: $showAccountPicker) {
                accountPickerSheet
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { loadData() }
    }
    
    // MARK: - Subviews
    
    private var amountSection: some View {
        VStack(spacing: 8) {
            TextField(
                "Amount",
                text: $amountString
            )
            .font(.memoAmountLarge)
            .foregroundStyle(transactionType.color)
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
            .padding(.top, 20)
            
            Text(currencyCode)
                .font(.memoCaption)
                .foregroundStyle(.memoSecondaryText)
        }
    }
    
    private func formRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }
    
    private var divider: some View {
        Divider().padding(.leading, 16)
    }
    
    // MARK: - Picker Sheets
    
    private var categoryPickerSheet: some View {
        NavigationStack {
            List(appContainer.categoryService.allCategories(type: transactionType == .income ? .income : .expense)) { cat in
                Button {
                    selectedCategory = cat
                    showCategoryPicker = false
                } label: {
                    HStack {
                        CategoryBadge(category: cat, style: .filled)
                        Spacer()
                        if selectedCategory?.id == cat.id {
                            Image(systemName: "checkmark").foregroundStyle(.memoPrimary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showCategoryPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var accountPickerSheet: some View {
        NavigationStack {
            List(allAccounts()) { account in
                Button {
                    selectedAccount = account
                    showAccountPicker = false
                } label: {
                    HStack {
                        Image(systemName: account.icon)
                            .foregroundStyle(Color(hex: account.colorHex))
                        Text(account.name).foregroundStyle(.memoPrimaryText)
                        Spacer()
                        if selectedAccount?.id == account.id {
                            Image(systemName: "checkmark").foregroundStyle(.memoPrimary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showAccountPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Logic
    
    private func loadData() {
        amountString = transaction.amount.formatted(currency: transaction.currencyCode)
        merchantName = transaction.merchant?.name ?? ""
        note = transaction.note
        date = transaction.date
        paymentMethod = transaction.paymentMethod
        transactionType = transaction.transactionType
        selectedAccount = transaction.account
        selectedCategory = transaction.category
        currencyCode = transaction.currencyCode
    }
    
    private func saveTransaction() {
        // Parse amount
        let stripped = amountString
            .components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".,km")).inverted)
            .joined()
            
        guard let amountDecimal = Decimal.parse(stripped), amountDecimal > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }
        
        guard let account = selectedAccount else {
            errorMessage = "Please select an account."
            return
        }
        
        transaction.amount = amountDecimal
        transaction.currencyCode = currencyCode
        transaction.note = note
        transaction.date = date
        transaction.paymentMethod = paymentMethod
        transaction.transactionType = transactionType
        transaction.account = account
        transaction.category = selectedCategory
        
        // Handle Merchant
        let trimmedMerchant = merchantName.trimmingCharacters(in: .whitespaces)
        if trimmedMerchant.isEmpty {
            transaction.merchant = nil
        } else if transaction.merchant?.name != trimmedMerchant {
            // Very simplified: create a new one or find existing.
            // A more robust implementation would use a MerchantService.
            let normalised = trimmedMerchant.lowercased()
            let descriptor = FetchDescriptor<Merchant>(predicate: #Predicate { $0.normalizedName == normalised })
            if let existing = try? modelContext.fetch(descriptor).first {
                transaction.merchant = existing
            } else {
                let newMerchant = Merchant(name: trimmedMerchant.capitalized, defaultCategory: selectedCategory)
                modelContext.insert(newMerchant)
                transaction.merchant = newMerchant
            }
        }
        
        do {
            try appContainer.transactionService.update(transaction)
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
    
    private func allAccounts() -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
