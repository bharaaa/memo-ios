//
//  TransactionForm.swift
//  Memo
//
//  Reusable form component for creating, previewing, and editing transactions.
//

import SwiftUI
import SwiftData

struct TransactionForm: View {
    @Binding var transactionType: TransactionType
    @Binding var merchantName: String
    @Binding var selectedCategory: Category?
    @Binding var selectedAccount: Account?
    @Binding var date: Date
    @Binding var paymentMethod: PaymentMethod
    @Binding var note: String
    
    let onCategoryTap: () -> Void
    let onAccountTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Type toggle
            formRow {
                HStack {
                    Label("Type", systemImage: "arrow.up.arrow.down.circle")
                        .foregroundStyle(.memoSecondaryText)
                        .font(.memoBody)
                    Spacer()
                    Picker("Type", selection: $transactionType) {
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
                    TextField("e.g. Grab", text: $merchantName)
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
                    if let cat = selectedCategory {
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
                .onTapGesture(perform: onCategoryTap)
            }
            divider
            
            // Account
            formRow {
                HStack {
                    Label("Account", systemImage: "creditcard")
                        .foregroundStyle(.memoSecondaryText)
                        .font(.memoBody)
                    Spacer()
                    Text(selectedAccount?.name ?? "Cash")
                        .font(.memoBody)
                        .foregroundStyle(.memoPrimaryText)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.memoTertiaryText)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onAccountTap)
            }
            divider
            
            // Date
            formRow {
                DatePicker(
                    "Date",
                    selection: $date,
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
                    Picker("Payment", selection: $paymentMethod) {
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
                    TextField("Optional note", text: $note, axis: .vertical)
                        .font(.memoBody)
                        .lineLimit(1...4)
                }
            }
        }
        .memoCardStyle()
        .memoScreenPadding()
    }
    
    // MARK: - Helpers
    
    private func formRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }
}
