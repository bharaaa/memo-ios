//
//  BalanceSection.swift
//  Memo
//
//  Displays the total balance as the visual hero, followed by account cards.
//

import SwiftUI

struct BalanceSection: View {
    let totalAssets: String
    let accounts: [Account]
    
    @AppStorage("isBalanceHidden") private var isBalanceHidden = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // MARK: - Total Balance Hero
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(L10n.balance)
                        .textCase(.uppercase)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .tracking(0.5)
                    
                    Button {
                        withAnimation(.spring) {
                            isBalanceHidden.toggle()
                        }
                    } label: {
                        Image(systemName: isBalanceHidden ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(UIColor.tertiaryLabel))
                    }
                }
                
                Text(isBalanceHidden ? "Rp •••••••••" : totalAssets)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
            .memoScreenPadding()
            
            // MARK: - Account Cards (Wallet Passes)
            if accounts.isEmpty {
                // Empty state for accounts
                NavigationLink(value: "ViewAllAccounts") {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.memoPrimary)
                        Text(L10n.addAccount)
                            .font(.body)
                            .foregroundStyle(Color.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .memoScreenPadding()
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(accounts) { account in
                            NavigationLink(value: account) {
                                WalletPassCard(account: account, isBalanceHidden: isBalanceHidden)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // View All Button
                        NavigationLink(value: "ViewAllAccounts") {
                            VStack {
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                                Text("View All")
                                    .font(.caption2)
                                    .foregroundStyle(Color.secondary)
                                    .padding(.top, 2)
                            }
                            .frame(width: 80, height: 90)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24) // Match memoScreenPadding
                }
            }
        }
        .padding(.bottom, 32) // More breathing room
    }
}

fileprivate struct WalletPassCard: View {
    let account: Account
    let isBalanceHidden: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                // Compact icon
                ZStack {
                    Circle()
                        .fill(Color(hex: account.colorHex))
                        .frame(width: 28, height: 28)
                    Image(systemName: account.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(account.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                
                Spacer(minLength: 16)
            }
            
            Spacer(minLength: 12)
            
            if isBalanceHidden {
                Text("••••••")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
            } else {
                AmountText(
                    amount: account.currentBalance,
                    currencyCode: account.currencyCode,
                    transactionType: account.currentBalance < 0 ? .expense : .income,
                    size: .regular,
                    showSign: false
                )
            }
        }
        .padding(16)
        .frame(width: 180, height: 90, alignment: .topLeading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2) // Softer shadow
    }
}
