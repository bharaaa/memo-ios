//
//  AccountListView.swift
//  Memo
//
//  List of all accounts, beautifully presented as Wallet cards.
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
                if vm.accounts.isEmpty {
                    EmptyAccountsView()
                } else {
                    List {
                        Section {
                            AccountSummaryHeader(
                                activeCount: vm.activeCount,
                                totalBalance: vm.totalBalance
                            )
                        }
                        
                        Section {
                            ForEach(vm.filteredAccounts) { account in
                                NavigationLink(value: account) {
                                    AccountListRow(
                                        account: account,
                                        transactionCount: appContainer.accountRepository.transactionCount(for: account)
                                    )
                                }
                                .contextMenu {
                                    NavigationLink(value: account) {
                                        Label("Edit Account", systemImage: "pencil")
                                    }
                                    
                                    Button {
                                        if !account.isDefault {
                                            account.isDefault = true
                                            for other in vm.accounts where other.id != account.id {
                                                other.isDefault = false
                                            }
                                            try? modelContext.save()
                                            vm.load()
                                        }
                                    } label: {
                                        Label("Set as Default", systemImage: "star")
                                    }
                                    
                                    Button {
                                        let newAccount = Account(
                                            name: "\(account.name) Copy",
                                            icon: account.icon,
                                            colorHex: account.colorHex,
                                            currencyCode: account.currencyCode,
                                            accountType: account.accountType,
                                            isDefault: false
                                        )
                                        newAccount.openingBalance = account.openingBalance
                                        modelContext.insert(newAccount)
                                        try? modelContext.save()
                                        vm.load()
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        if let index = vm.accounts.firstIndex(of: account) {
                                            vm.deleteAccounts(at: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        if !account.isDefault {
                                            account.isDefault = true
                                            for other in vm.accounts where other.id != account.id {
                                                other.isDefault = false
                                            }
                                            try? modelContext.save()
                                            vm.load()
                                        }
                                    } label: {
                                        Label("Default", systemImage: "star.fill")
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        if let index = vm.accounts.firstIndex(of: account) {
                                            vm.deleteAccounts(at: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        account.isArchived.toggle()
                                        try? modelContext.save()
                                        vm.load()
                                    } label: {
                                        Label(account.isArchived ? "Unarchive" : "Archive", systemImage: "archivebox")
                                    }
                                    .tint(.gray)
                                }
                            }
                            .onMove { source, destination in
                                vm.moveAccounts(from: source, to: destination)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            } else {
                ProgressView()
            }
        }
        .background(Color.memoBackground)
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        ), prompt: "Search Accounts")
        .toolbar {
            if let vm = viewModel, !vm.accounts.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
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
                context: modelContext
            )
        }
        .navigationDestination(for: String.self) { value in
            if value == "new_account" {
                AccountDetailView(
                    context: modelContext
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
