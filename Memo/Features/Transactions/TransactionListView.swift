//
//  TransactionListView.swift
//  Memo
//
//  Full transaction history, grouped by date.
//  Accessible via the second tab in ContentView.
//

import SwiftUI
import SwiftData

struct TransactionListView: View {

    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var showChat = false
    @State private var selectedTransaction: Transaction?
    @State private var searchText = ""

    private var filtered: [Transaction] {
        guard !searchText.isEmpty else { return transactions }
        let q = searchText.lowercased()
        return transactions.filter {
            $0.merchant?.name.lowercased().contains(q) == true ||
            $0.note.lowercased().contains(q) ||
            $0.category?.name.lowercased().contains(q) == true
        }
    }

    private var grouped: [(String, [Transaction])] {
        let groups = Dictionary(grouping: filtered) { $0.date.memoRelativeLabel }
        return groups.sorted { a, b in
            guard let first = filtered.first(where: { $0.date.memoRelativeLabel == a.key }),
                  let second = filtered.first(where: { $0.date.memoRelativeLabel == b.key }) else { return false }
            return first.date > second.date
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    EmptyState(
                        icon: "brain",
                        title: "No memories yet",
                        message: "Start by telling Memo about a purchase.",
                        action: { showChat = true },
                        actionLabel: "Add first memory"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(grouped, id: \.0) { (dateLabel, group) in
                            Section {
                                ForEach(group) { transaction in
                                    TransactionRowView(transaction: transaction)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            deleteButton(transaction)
                                        }
                                        .onTapGesture {
                                            selectedTransaction = transaction
                                        }
                                }
                            } header: {
                                Text(dateLabel)
                                    .font(.memoCaption)
                                    .foregroundStyle(.memoSecondaryText)
                                    .textCase(.none)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search transactions")
                }
            }
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showChat = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.memoPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showChat) {
            ChatView().environment(appContainer)
        }
    }

    // MARK: - Delete

    private func deleteButton(_ transaction: Transaction) -> some View {
        Button(role: .destructive) {
            try? appContainer.transactionService.delete(transaction)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

#Preview {
    TransactionListView()
        .environment(AppContainer())
        .modelContainer(PersistenceController.shared.container)
}
