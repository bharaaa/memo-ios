//
//  RecentMemoriesSection.swift
//  Memo
//
//  Displays a native Apple-style list of recent transactions.
//

import SwiftUI

struct RecentMemoriesSection: View {
    let transactions: [Transaction]
    let onEmptyAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT MEMORIES")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)
                Spacer()
                NavigationLink(value: "SeeAll") {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(Color.memoPrimary)
                }
            }
            .memoScreenPadding()
            
            if transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.secondary)
                    
                    Text("Nothing remembered yet.")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    
                    Text("Try typing an expense above")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(transactions) { transaction in
                        NavigationLink(value: transaction) {
                            MemoryRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                        
                        if transaction != transactions.last {
                            Divider()
                                .padding(.leading, 64) // Aligns with the text, skipping the icon
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .memoScreenPadding()
            }
        }
        .padding(.bottom, 32)
    }
}

