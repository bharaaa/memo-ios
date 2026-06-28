//
//  AccountListComponents.swift
//  Memo
//
//  Wallet-style UI components for the Account List screen.
//

import SwiftUI
import SwiftData

// MARK: - Summary Header

struct AccountSummaryHeader: View {
    let activeCount: Int
    let totalBalance: Decimal
    let preferredCurrency: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(activeCount) Active Accounts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            AmountText(
                amount: totalBalance,
                currencyCode: preferredCurrency,
                transactionType: totalBalance < 0 ? .expense : .income,
                size: .small,
                showSign: false
            )
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Account Row (Minimalist Wallet Style)

struct AccountListRow: View {
    let account: Account
    let transactionCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: account.colorHex).opacity(0.15))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: account.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: account.colorHex))
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(account.name)
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                        
                        if account.isDefault {
                            Text("Default")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(account.accountType.displayName)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
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
            
            // Metadata Footer
            HStack {
                Text("\(transactionCount) Transactions")
                if account.isArchived {
                    Text("·")
                    Text("Archived").foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(Color(UIColor.tertiaryLabel))
        }
        .padding(.vertical, 8)
        .opacity(account.isArchived ? 0.6 : 1.0)
    }
}

// MARK: - Empty State

struct EmptyAccountsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "creditcard")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentColor)
            }
            
            Text("No Accounts Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.primary)
            
            Text("Create your first account to start remembering your finances.")
                .font(.body)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}
