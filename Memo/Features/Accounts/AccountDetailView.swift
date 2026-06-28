//
//  AccountDetailView.swift
//  Memo
//
//  Wallet-style interactive screen for creating and editing accounts.
//

import SwiftUI
import SwiftData

@MainActor
struct AccountDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer
    
    @State private var viewModel: AccountFormViewModel?
    private let accountToEdit: Account?
    
    init(account: Account? = nil, context: ModelContext, defaultCurrency: String) {
        self.accountToEdit = account
    }
    
    var body: some View {
        Group {
            if let vm = viewModel {
                content(viewModel: vm)
            } else {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AccountFormViewModel(
                    account: accountToEdit,
                    modelContext: modelContext,
                    defaultCurrency: appContainer.preferredCurrencyCode
                )
            }
        }
    }
    
    @ViewBuilder
    private func content(viewModel: AccountFormViewModel) -> some View {
        @Bindable var viewModel = viewModel
        
        ScrollView {
            VStack(spacing: 24) {
                // Live Preview Card
                AccountPreviewCard(
                    name: viewModel.name,
                    icon: viewModel.icon,
                    colorHex: viewModel.colorHex,
                    currencyCode: viewModel.currencyCode,
                    balanceString: viewModel.openingBalanceString,
                    accountType: viewModel.accountType
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Account Information
                AccountInformationSection(
                    name: $viewModel.name,
                    accountType: $viewModel.accountType,
                    currencyCode: viewModel.currencyCode,
                    onCurrencyTap: { viewModel.showCurrencyPicker = true },
                    openingBalanceString: $viewModel.openingBalanceString
                )
                .padding(.horizontal, 16)
                
                // Appearance
                AccountAppearanceSection(
                    icon: viewModel.icon,
                    colorHex: viewModel.colorHex,
                    onIconTap: { viewModel.showIconPicker = true },
                    onColorTap: { viewModel.showColorPicker = true }
                )
                .padding(.horizontal, 16)
                
                // Read-Only Metadata (If Editing)
                if let account = viewModel.existingAccount {
                    AccountMetadataSection(
                        isArchived: $viewModel.isArchived,
                        totalIncome: appContainer.accountRepository.totalIncome(for: account),
                        totalExpenses: appContainer.accountRepository.totalExpenses(for: account),
                        transferIn: appContainer.accountRepository.transferIn(for: account),
                        transferOut: appContainer.accountRepository.transferOut(for: account),
                        transactionCount: appContainer.accountRepository.transactionCount(for: account),
                        currencyCode: account.currencyCode
                    )
                    .padding(.horizontal, 16)
                    
                    AccountDangerZone(
                        onDeleteTap: { viewModel.showDeleteConfirmation = true }
                    )
                    .padding(.horizontal, 16)
                }
                
                // Errors
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(viewModel.isEditing ? "Edit Account" : "Add Account")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    if viewModel.save() {
                        dismiss()
                    }
                }
                .fontWeight(.bold)
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
}
