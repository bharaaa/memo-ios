//
//  AccountDetailComponents.swift
//  Memo
//
//  Wallet-style UI components for creating and editing accounts.
//

import SwiftUI

// MARK: - Live Preview Card

struct AccountPreviewCard: View {
    let name: String
    let icon: String
    let colorHex: String
    let currencyCode: CurrencyCode
    let balanceString: String
    let accountType: AccountType
    
    var body: some View {
        let accentColor = Color(hex: colorHex)
        let displayName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Account Name" : name
        
        // Remove non-numeric characters for the preview parse
        let strippedBalance = balanceString.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let balanceValue = Decimal(string: strippedBalance) ?? 0
        
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text(accountType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 24)
            
            Text(displayName)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
            
            AmountText(
                money: Money(amount: balanceValue, currencyCode: currencyCode),
                transactionType: balanceValue < 0 ? .expense : .income,
                size: .large,
                showSign: false
            )
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.gradient)
        )
        .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: colorHex)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: icon)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: name)
    }
}

// MARK: - Editable Info Section

struct AccountInformationSection: View {
    @Binding var name: String
    @Binding var accountType: AccountType
    let currencyCode: CurrencyCode
    let onCurrencyTap: () -> Void
    @Binding var openingBalanceString: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Name
            AccountEditableRow(title: "Name", icon: "pencil", iconColor: .gray) {
                TextField("e.g. Jago", text: $name)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Color.primary)
            }
            
            // Type
            AccountEditableRow(title: "Type", icon: "building.columns", iconColor: .blue) {
                Picker("Account Type", selection: $accountType) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(.secondary)
            }
            
            // Currency
            AccountEditableRow(title: "Currency", icon: "dollarsign.circle", iconColor: .green, action: onCurrencyTap) {
                Text(currencyCode.rawValue)
            }
            
            // Balance
            AccountEditableRow(title: "Initial Balance", icon: "plus.forwardslash.minus", iconColor: .orange, isLast: true) {
                CurrencyTextField(placeholder: "0", text: $openingBalanceString)
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Appearance Section

struct AccountAppearanceSection: View {
    let icon: String
    let colorHex: String
    let onIconTap: () -> Void
    let onColorTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            AccountEditableRow(title: "Icon", icon: "star", iconColor: .purple, action: onIconTap) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: colorHex))
            }
            
            AccountEditableRow(title: "Color", icon: "paintpalette", iconColor: .pink, isLast: true, action: onColorTap) {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 24, height: 24)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Metadata / Summary Section

struct AccountMetadataSection: View {
    @Binding var isArchived: Bool
    
    let totalIncome: Money
    let totalExpense: Money
    let transferIn: Money
    let transferOut: Money
    let transactionCount: Int
    
    var body: some View {
        VStack(spacing: 0) {
            AccountEditableRow(title: "Archive Account", icon: "archivebox", iconColor: .gray) {
                Toggle("", isOn: $isArchived)
                    .labelsHidden()
                    .tint(.memoPrimary)
            }
            
            summaryRow(title: "Income", icon: "arrow.down.left", iconColor: .green, money: totalIncome)
            summaryRow(title: "Expenses", icon: "arrow.up.right", iconColor: .red, money: totalExpense)
            
            if transferIn.amount > 0 || transferOut.amount > 0 {
                Divider()
                    .padding(.leading, 44)
                
                summaryRow(title: "Transfers In", icon: "arrow.right.to.line", iconColor: .blue, money: transferIn)
                summaryRow(title: "Transfers Out", icon: "arrow.left.from.line", iconColor: .orange, money: transferOut)
            }
            
            AccountEditableRow(title: "Transactions", icon: "list.bullet", iconColor: .black, isLast: true) {
                Text("\(transactionCount)")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func summaryRow(title: String, icon: String, iconColor: Color, money: Money) -> some View {
        AccountEditableRow(title: title, icon: icon, iconColor: iconColor) {
            AmountText(
                money: money,
                transactionType: money.amount < 0 ? .expense : .income,
                size: .small,
                showSign: false
            )
        }
    }
}

// MARK: - Danger Zone

struct AccountDangerZone: View {
    let onDeleteTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(role: .destructive, action: onDeleteTap) {
                HStack {
                    Spacer()
                    Text("Delete Account")
                        .font(.body)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Reusable Editable Row

struct AccountEditableRow<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var isLast: Bool = false
    let action: (() -> Void)?
    @ViewBuilder let valueContent: () -> Content
    
    init(title: String, icon: String, iconColor: Color, isLast: Bool = false, action: (() -> Void)? = nil, @ViewBuilder valueContent: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.isLast = isLast
        self.action = action
        self.valueContent = valueContent
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) { rowContent }
                    .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
    }
    
    private var rowContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                valueContent()
                    .font(.body)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.trailing)
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            
            if !isLast {
                Divider()
                    .padding(.leading, 64)
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}
