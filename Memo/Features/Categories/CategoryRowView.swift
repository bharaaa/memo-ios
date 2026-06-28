//
//  CategoryRowView.swift
//  Memo
//
//  A native iOS-style settings row for a category.
//

import SwiftUI
import SwiftData

struct CategoryRowView: View {
    let category: Category
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                // Circular icon
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                // Name & Transaction Count
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.body)
                        .foregroundStyle(.memoPrimaryText)
                    
                    // Transaction count (optional)
                    if !category.transactions.isEmpty {
                        Text("\(category.transactions.count) transactions")
                            .font(.caption)
                            .foregroundStyle(.memoSecondaryText)
                    }
                }
                
                Spacer()
                
                if category.isSystem {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.memoTertiaryText)
                        .padding(.trailing, 4)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            
            if !category.isSystem {
                Divider()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !category.isSystem {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.memoAccent)
        }
    }
}
