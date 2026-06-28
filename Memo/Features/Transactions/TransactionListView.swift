//
//  TransactionListView.swift
//  Memo
//
//  Full transaction history timeline, styled like Apple Journal.
//  Accessible via the second tab in ContentView.
//

import SwiftUI
import SwiftData

struct TransactionListView: View {

    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    var onGoToComposer: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var transactionToEdit: Transaction?
    
    @State private var searchText = ""
    @State private var activeFilters: Set<MemoryFilter> = []

    private var filtered: [Transaction] {
        var result = transactions
        
        // 1. Apply Search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.merchant?.name.lowercased().contains(q) == true ||
                $0.note.lowercased().contains(q) ||
                $0.category?.name.lowercased().contains(q) == true
            }
        }
        
        // 2. Apply Quick Filters (Intersection: all active filters must pass)
        if !activeFilters.isEmpty {
            result = result.filter { tx in
                for filter in activeFilters {
                    if !filter.applies(to: tx) {
                        return false
                    }
                }
                return true
            }
        }
        
        return result
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
                    EmptyMemoriesView {
                        if let action = onGoToComposer {
                            action()
                        } else {
                            dismiss()
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .focusComposer, object: nil)
                        }
                    }
                } else if filtered.isEmpty {
                    // Filtered empty state
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.secondary)
                        Text("No memories found")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                        Spacer()
                    }
                } else {
                    List {
                        FilterChipBar(activeFilters: $activeFilters)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.bottom, 8)
                            .padding(.top, 4)
                            
                        ForEach(grouped, id: \.0) { (dateLabel, group) in
                            Section {
                                ForEach(group) { transaction in
                                    NavigationLink(value: transaction) {
                                        MemoryRow(transaction: transaction)
                                            .listRowInsets(EdgeInsets())
                                    }
                                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                                        64 // Align divider with text, skipping icon
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            Task {
                                                try? await appContainer.transactionService.delete(transaction)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            Task {
                                                try? await appContainer.transactionService.duplicate(transaction)
                                            }
                                        } label: {
                                            Label("Duplicate", systemImage: "doc.on.doc")
                                        }
                                        .tint(.memoSecondaryText)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            transactionToEdit = transaction
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.memoPrimary)
                                    }
                                }
                            } header: {
                                Text(dateLabel)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.primary)
                                    .textCase(.none)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.memoBackground)
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search memories")
            .navigationDestination(for: Transaction.self) { transaction in
                TransactionDetailView(transaction: transaction)
            }
        }
        .sheet(item: $transactionToEdit) { transaction in
            TransactionEditView(transaction: transaction)
                .environment(appContainer)
        }
    }
}
