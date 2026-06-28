//
//  AccountListView.swift
//  Memo
//
//  List of all accounts, allowing creation, edit, reorder, and delete.
//

import SwiftUI
import SwiftData

struct AccountListView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: AccountListViewModel?
    
    var body: some View {
        Group {
            if let vm = viewModel {
                List {
                    ForEach(vm.accounts) { account in
                        NavigationLink(value: account) {
                            HStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: account.colorHex).opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: account.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color(hex: account.colorHex))
                                }
                                
                                // Name and Type
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                        .font(.memoBody)
                                        .foregroundStyle(.memoPrimaryText)
                                    
                                    HStack {
                                        Text(account.accountType.displayName)
                                        if account.isDefault {
                                            Text("· Default")
                                        }
                                        if account.isArchived {
                                            Text("· Archived")
                                        }
                                    }
                                    .font(.memoCaption)
                                    .foregroundStyle(.memoSecondaryText)
                                }
                                
                                Spacer()
                                
                                // Balance
                                AmountText(
                                    amount: account.currentBalance,
                                    currencyCode: account.currencyCode,
                                    transactionType: account.currentBalance < 0 ? .expense : .income,
                                    size: .small,
                                    showSign: false
                                )
                            }
                            .padding(.vertical, 4)
                        }
                        .opacity(account.isArchived ? 0.6 : 1.0)
                    }
                    .onMove { source, destination in
                        vm.moveAccounts(from: source, to: destination)
                    }
                    .onDelete { offsets in
                        vm.deleteAccounts(at: offsets)
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: "new_account") {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: Account.self) { account in
            AccountDetailView(
                account: account,
                context: modelContext,
                defaultCurrency: appContainer.preferredCurrencyCode
            )
        }
        .navigationDestination(for: String.self) { value in
            if value == "new_account" {
                AccountDetailView(
                    context: modelContext,
                    defaultCurrency: appContainer.preferredCurrencyCode
                )
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AccountListViewModel(repository: appContainer.accountRepository)
            }
            viewModel?.load()
        }
    }
}

#Preview {
    NavigationStack {
        AccountListView()
            .environment(AppContainer())
            .modelContainer(PersistenceController.shared.container)
    }
}
