//
//  TransactionPreviewView.swift
//  Memo
//
//  The critical validation gate. Shown after AI parses an input.
//  User can review, edit any field, and confirm or discard.
//  Nothing is written to SwiftData until "Save Memory" is tapped.
//

import SwiftUI
import SwiftData

struct TransactionPreviewView: View {

    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let parsed: ParsedTransaction
    var onSaved: ((Transaction?) -> Void)?

    @State private var viewModel: TransactionPreviewViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    content(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.memoSecondaryText)
                }
            }
        }
        .onAppear { setupViewModel() }
        .onChange(of: parsed) { newValue in
            viewModel?.update(with: newValue)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Main Content

    @ViewBuilder
    private func content(vm: TransactionPreviewViewModel) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    // Amount Hero
                    PreviewAmountHeader(
                        amount: Binding(get: { vm.amount }, set: { vm.amount = $0 }),
                        transactionType: vm.transactionType,
                        currencyCode: vm.currencyCode,
                        merchantName: Binding(get: { vm.merchantName }, set: { vm.merchantName = $0 }),
                        category: vm.selectedCategory,
                        date: vm.date
                    )
                    
                    // Smart Badge
                    SmartConfirmationBadge(confidence: vm.confidence, status: vm.status)
                        .padding(.horizontal, 16)
                    
                    // Details
                    EditableDetailSection(
                        transactionType: Binding(get: { vm.transactionType }, set: { vm.transactionType = $0 }),
                        category: vm.selectedCategory,
                        account: vm.selectedAccount,
                        paymentMethod: Binding(get: { vm.paymentMethod }, set: { vm.userSelected(paymentMethod: $0) }),
                        date: Binding(get: { vm.date }, set: { vm.date = $0 }),
                        isThinkingCategory: vm.status == .parsing && !vm.userDidSelectCategory,
                        isThinkingAccount: vm.status == .parsing && !vm.userDidSelectAccount,
                        isThinkingPayment: vm.status == .parsing && !vm.userDidSelectPaymentMethod,
                        onCategoryTap: { vm.showCategoryPicker = true },
                        onAccountTap: { vm.showAccountPicker = true }
                    )
                    .padding(.horizontal, 16)
                    
                    // Notes
                    EditableNotesSection(
                        note: Binding(get: { vm.note }, set: { vm.note = $0 })
                    )
                    .padding(.horizontal, 16)
                    
                    // Error
                    if let error = vm.saveError {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color.red)
                            .padding()
                    }
                    
                    // Bottom padding to clear the toolbar
                    Spacer(minLength: 100)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            // Pinned Save Button
            SaveActionToolbar(
                isSaving: vm.isSaving,
                onSave: {
                    vm.save { savedTransaction in
                        onSaved?(savedTransaction)
                        dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: Binding(get: { vm.showCategoryPicker }, set: { vm.showCategoryPicker = $0 })) {
            categoryPickerSheet(vm: vm)
        }
        .sheet(isPresented: Binding(get: { vm.showAccountPicker }, set: { vm.showAccountPicker = $0 })) {
            accountPickerSheet(vm: vm)
        }
    }

    // MARK: - Category Picker Sheet

    private func categoryPickerSheet(vm: TransactionPreviewViewModel) -> some View {
        NavigationStack {
            List(appContainer.categoryService.allCategories(type: vm.transactionType == .income ? .income : .expense)) { cat in
                Button {
                    vm.userSelected(category: cat)
                    vm.showCategoryPicker = false
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
                        if vm.selectedCategory?.id == cat.id {
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
                    Button("Done") { vm.showCategoryPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Account Picker Sheet

    private func accountPickerSheet(vm: TransactionPreviewViewModel) -> some View {
        NavigationStack {
            List(vm.allAccounts()) { account in
                Button {
                    vm.userSelected(account: account)
                    vm.showAccountPicker = false
                } label: {
                    HStack {
                        Image(systemName: account.icon)
                            .foregroundStyle(Color(hex: account.colorHex))
                        Text(account.name).foregroundStyle(.memoPrimaryText)
                        Spacer()
                        if vm.selectedAccount?.id == account.id {
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
                    Button("Done") { vm.showAccountPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Setup

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = TransactionPreviewViewModel(
                parsed: parsed,
                transactionService: appContainer.transactionService,
                categoryService: appContainer.categoryService,
                modelContext: modelContext,
                defaultCurrency: appContainer.preferredCurrencyCode
            )
        }
    }
}
