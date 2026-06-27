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
    var onSaved: (() -> Void)?

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
                ToolbarItem(placement: .topBarTrailing) {
                    if let vm = viewModel {
                        Button {
                            vm.save {
                                onSaved?()
                                dismiss()
                            }
                        } label: {
                            if vm.isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save")
                                    .font(.memoHeadline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(.memoPrimary))
                            }
                        }
                        .disabled(vm.isSaving)
                    }
                }
            }
        }
        .onAppear { setupViewModel() }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Main Content

    @ViewBuilder
    private func content(vm: TransactionPreviewViewModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Amount hero
                amountSection(vm: vm)

                // Form fields
                VStack(spacing: 0) {
                    // Type toggle
                    formRow {
                        HStack {
                            Label("Type", systemImage: "arrow.up.arrow.down.circle")
                                .foregroundStyle(.memoSecondaryText)
                                .font(.memoBody)
                            Spacer()
                            Picker("Type", selection: Binding(
                                get: { vm.transactionType },
                                set: { vm.transactionType = $0 }
                            )) {
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
                            TextField("e.g. Grab", text: Binding(
                                get: { vm.merchantName },
                                set: { vm.merchantName = $0 }
                            ))
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
                            if let cat = vm.selectedCategory {
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
                        .onTapGesture { vm.showCategoryPicker = true }
                    }
                    divider

                    // Account
                    formRow {
                        HStack {
                            Label("Account", systemImage: "creditcard")
                                .foregroundStyle(.memoSecondaryText)
                                .font(.memoBody)
                            Spacer()
                            Text(vm.selectedAccount?.name ?? "Cash")
                                .font(.memoBody)
                                .foregroundStyle(.memoPrimaryText)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.memoTertiaryText)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { vm.showAccountPicker = true }
                    }
                    divider

                    // Date
                    formRow {
                        DatePicker(
                            "Date",
                            selection: Binding(
                                get: { vm.date },
                                set: { vm.date = $0 }
                            ),
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
                            Picker("Payment", selection: Binding(
                                get: { vm.paymentMethod },
                                set: { vm.paymentMethod = $0 }
                            )) {
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
                            TextField("Optional note", text: Binding(
                                get: { vm.note },
                                set: { vm.note = $0 }
                            ), axis: .vertical)
                            .font(.memoBody)
                            .lineLimit(1...4)
                        }
                    }
                }
                .background(Color.memoCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)

                // Confidence badge
                confidenceBadge(vm: vm)

                // Error
                if let error = vm.saveError {
                    Text(error)
                        .font(.memoSubheadline)
                        .foregroundStyle(.memoExpense)
                        .padding()
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.memoBackground)
        .sheet(isPresented: Binding(get: { vm.showCategoryPicker }, set: { vm.showCategoryPicker = $0 })) {
            categoryPickerSheet(vm: vm)
        }
        .sheet(isPresented: Binding(get: { vm.showAccountPicker }, set: { vm.showAccountPicker = $0 })) {
            accountPickerSheet(vm: vm)
        }
    }

    // MARK: - Amount Hero

    private func amountSection(vm: TransactionPreviewViewModel) -> some View {
        VStack(spacing: 8) {
            TextField(
                "Amount",
                text: Binding(get: { vm.amount }, set: { vm.amount = $0 })
            )
            .font(.memoAmountLarge)
            .foregroundStyle(vm.transactionType.color)
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
            .padding(.top, 20)

            Text(vm.currencyCode)
                .font(.memoCaption)
                .foregroundStyle(.memoSecondaryText)
        }
    }

    // MARK: - Form Helpers

    private func formRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }

    // MARK: - Category Picker Sheet

    private func categoryPickerSheet(vm: TransactionPreviewViewModel) -> some View {
        NavigationStack {
            List(appContainer.categoryService.allCategories(type: vm.transactionType == .income ? .income : .expense)) { cat in
                Button {
                    vm.selectedCategory = cat
                    vm.showCategoryPicker = false
                } label: {
                    HStack {
                        CategoryBadge(category: cat, style: .filled)
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
                    vm.selectedAccount = account
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

    // MARK: - Confidence Badge

    private func confidenceBadge(vm: TransactionPreviewViewModel) -> some View {
        HStack(spacing: 6) {
            Image(systemName: vm.confidence >= 0.8 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(vm.confidence >= 0.8 ? Color.memoIncome : Color.memoAccent)
            Text(vm.confidence >= 0.8
                 ? "High confidence · \(vm.providerName.replacingOccurrences(of: "_", with: " ").capitalized)"
                 : "Low confidence — please review carefully")
            .font(.memoCaption)
            .foregroundStyle(.memoSecondaryText)
        }
        .padding(.horizontal, 20)
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

#Preview {
    TransactionPreviewView(parsed: ParsedTransaction(
        amount: 35000,
        currencyCode: "IDR",
        merchantName: "Coffee Shop",
        categoryHint: "food",
        confidence: 0.92,
        rawInput: "Coffee 35k",
        providerName: "rule_based"
    ))
    .environment(AppContainer())
    .modelContainer(PersistenceController.shared.container)
}
