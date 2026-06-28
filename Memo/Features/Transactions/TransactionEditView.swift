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
    @Environment(\.locale) private var locale
    
    let transaction: Transaction
    
    @State private var amountString: String = ""
    @State private var merchantName: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var paymentMethod: PaymentMethod = .cash
    @State private var transactionType: TransactionType = .expense
    @State private var selectedAccount: Account?
    @State private var selectedCategory: Category?
    @State private var currencyCode: CurrencyCode = .idr
    
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
                    TransactionForm(
                        transactionType: $transactionType,
                        merchantName: $merchantName,
                        selectedCategory: $selectedCategory,
                        selectedAccount: $selectedAccount,
                        date: $date,
                        paymentMethod: $paymentMethod,
                        note: $note,
                        onCategoryTap: { showCategoryPicker = true },
                        onAccountTap: { showAccountPicker = true }
                    )
                    
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
            CurrencyTextField(
                placeholder: "Amount",
                text: $amountString,
                font: UIFont.systemFont(ofSize: 34, weight: .heavy),
                textColor: UIColor(transactionType.color),
                textAlignment: .center
            )
            .frame(height: 50)
            .padding(.top, 20)
            
            Text(currencyCode.rawValue)
                .font(.memoCaption)
                .foregroundStyle(.memoSecondaryText)
        }
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
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: cat.colorHex))
                                    .frame(width: 28, height: 28)
                                Image(systemName: cat.icon)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            Text(cat.name)
                                .font(.body)
                                .foregroundStyle(.memoPrimaryText)
                        }
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
        amountString = MoneyFormatter.format(transaction.originalMoney, locale: locale, showSign: false)
        merchantName = transaction.merchant?.name ?? ""
        note = transaction.note
        date = transaction.date
        paymentMethod = transaction.paymentMethod
        transactionType = transaction.transactionType
        selectedAccount = transaction.account
        selectedCategory = transaction.category
        currencyCode = transaction.originalMoney.currencyCode
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
        
        transaction.originalMoney = Money(amount: amountDecimal, currencyCode: currencyCode)
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
        
        Task {
            do {
                try await appContainer.transactionService.update(transaction)
                dismiss()
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
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
