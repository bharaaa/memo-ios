//
//  AccountDetailView.swift
//  Memo
//
//  Settings-style form for creating and editing accounts.
//

import SwiftUI
import SwiftData

@MainActor
struct AccountDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer
    
    @State private var viewModel: AccountFormViewModel
    
    init(account: Account? = nil, context: ModelContext, defaultCurrency: String) {
        _viewModel = State(wrappedValue: AccountFormViewModel(
            account: account,
            modelContext: context,
            defaultCurrency: defaultCurrency
        ))
    }
    
    var body: some View {
        Form {
            Section("Account Details") {
                TextField("Name", text: $viewModel.name)
                
                Picker("Account Type", selection: $viewModel.accountType) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                
                Button {
                    viewModel.showCurrencyPicker = true
                } label: {
                    HStack {
                        Text("Currency")
                            .foregroundStyle(.memoPrimaryText)
                        Spacer()
                        Text(viewModel.currencyCode)
                            .foregroundStyle(.memoSecondaryText)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.memoTertiaryText)
                    }
                }
                
                HStack {
                    Text("Opening Balance")
                    Spacer()
                    TextField("0", text: $viewModel.openingBalanceString)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                if let account = viewModel.existingAccount {
                    HStack {
                        Text("Current Balance")
                        Spacer()
                        AmountText(
                            amount: account.currentBalance,
                            currencyCode: account.currencyCode,
                            transactionType: account.currentBalance < 0 ? .expense : .income,
                            size: .small,
                            showSign: false
                        )
                    }
                }
            }
            
            if let account = viewModel.existingAccount {
                Section("Activity Summary") {
                    summaryRow(title: "Total Income", amount: appContainer.accountRepository.totalIncome(for: account), currency: account.currencyCode)
                    summaryRow(title: "Total Expenses", amount: appContainer.accountRepository.totalExpenses(for: account), currency: account.currencyCode)
                    summaryRow(title: "Transfer In", amount: appContainer.accountRepository.transferIn(for: account), currency: account.currencyCode)
                    summaryRow(title: "Transfer Out", amount: appContainer.accountRepository.transferOut(for: account), currency: account.currencyCode)
                    HStack {
                        Text("Transactions")
                            .foregroundStyle(.memoSecondaryText)
                        Spacer()
                        Text("\(appContainer.accountRepository.transactionCount(for: account))")
                    }
                }
            }
            
            Section("Appearance") {
                Button {
                    viewModel.showIconPicker = true
                } label: {
                    HStack {
                        Text("Icon")
                            .foregroundStyle(.memoPrimaryText)
                        Spacer()
                        Image(systemName: viewModel.icon)
                            .font(.title3)
                            .foregroundStyle(Color(hex: viewModel.colorHex))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.memoTertiaryText)
                            .padding(.leading, 8)
                    }
                }
                
                Button {
                    viewModel.showColorPicker = true
                } label: {
                    HStack {
                        Text("Color")
                            .foregroundStyle(.memoPrimaryText)
                        Spacer()
                        Circle()
                            .fill(Color(hex: viewModel.colorHex))
                            .frame(width: 24, height: 24)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.memoTertiaryText)
                            .padding(.leading, 8)
                    }
                }
            }
            
            if viewModel.isEditing {
                Section {
                    Toggle("Archive Account", isOn: $viewModel.isArchived)
                        .tint(.memoPrimary)
                } header: {
                    Text("Status")
                } footer: {
                    Text("Archived accounts won't appear in the main picker, but their transactions remain visible.")
                }
                
                Section {
                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Account")
                            Spacer()
                        }
                    }
                }
            }
            
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.memoExpense)
                        .font(.memoCaption)
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Account" : "New Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    if viewModel.save() {
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $viewModel.showIconPicker) {
            NavigationStack {
                IconPickerView(selectedIcon: $viewModel.icon)
                    .navigationTitle("Select Icon")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { viewModel.showIconPicker = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showColorPicker) {
            NavigationStack {
                ColorPickerGrid(selectedHex: $viewModel.colorHex)
                    .navigationTitle("Select Color")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { viewModel.showColorPicker = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showCurrencyPicker) {
            NavigationStack {
                CurrencyPickerView(selected: $viewModel.currencyCode)
                    .padding()
                    .navigationTitle("Select Currency")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { viewModel.showCurrencyPicker = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                if viewModel.delete() {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the account. Transactions associated with this account may lose their account reference.")
        }
    }
    
    private func summaryRow(title: String, amount: Decimal, currency: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.memoSecondaryText)
            Spacer()
            AmountText(
                amount: amount,
                currencyCode: currency,
                transactionType: amount < 0 ? .expense : .income,
                size: .small,
                showSign: false
            )
        }
    }
}
