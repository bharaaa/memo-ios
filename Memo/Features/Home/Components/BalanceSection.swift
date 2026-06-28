import SwiftUI

struct BalanceSection: View {
    let totalAssets: String
    let accounts: [Account]
    
    @AppStorage("isBalanceHidden") private var isBalanceHidden = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("TOTAL BALANCE")
                .font(.memoCaption)
                .foregroundStyle(.memoTertiaryText)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, 24)
            
            // Total Balance
            HStack {
                Text(isBalanceHidden ? "Rp •••••••••" : totalAssets)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.memoPrimaryText)
                
                Spacer()
                
                Button {
                    isBalanceHidden.toggle()
                } label: {
                    Image(systemName: isBalanceHidden ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.memoTertiaryText)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
            // Accounts Card
            VStack(spacing: 0) {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    NavigationLink(value: account) {
                        AccountListRow(account: account, isBalanceHidden: isBalanceHidden)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 56)
                }
                
                NavigationLink(value: "ViewAllAccounts") {
                    Text("View all accounts")
                        .font(.memoBody)
                        .foregroundStyle(Color.memoPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
            }
            .background(Color.memoCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
    }
}

fileprivate struct AccountListRow: View {
    let account: Account
    let isBalanceHidden: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: account.colorHex).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: account.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: account.colorHex))
            }
            
            Text(account.name)
                .font(.memoBody)
                .foregroundStyle(.memoPrimaryText)
            
            Spacer()
            
            if isBalanceHidden {
                Text("••••••")
                    .font(.memoBody)
                    .foregroundStyle(.memoPrimaryText)
            } else {
                AmountText(
                    amount: account.currentBalance,
                    currencyCode: account.currencyCode,
                    transactionType: account.currentBalance < 0 ? .expense : .income,
                    size: .small,
                    showSign: false
                )
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.memoTertiaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
