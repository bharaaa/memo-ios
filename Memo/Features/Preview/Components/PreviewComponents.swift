//
//  PreviewComponents.swift
//  Memo
//
//  Wallet-style UI components for the Transaction Preview confirmation screen.
//

import SwiftUI

// MARK: - Amount Header

struct PreviewAmountHeader: View {
    @Binding var amount: String
    let transactionType: TransactionType
    let currencyCode: String
    @Binding var merchantName: String
    let category: Category?
    let date: Date
    
    var body: some View {
        VStack(spacing: 8) {
            // Editable Hero Amount
            CurrencyTextField(
                placeholder: "Amount",
                text: $amount,
                font: UIFont.systemFont(ofSize: 42, weight: .bold),
                textColor: UIColor(transactionType.color),
                textAlignment: .center
            )
            .frame(height: 60)
            .padding(.top, 24)
            
            VStack(spacing: 4) {
                // Editable Merchant
                TextField("Merchant", text: $merchantName)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                
                Text(category?.name ?? "Transaction")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                
                let dateStr = date.formatted(date: .abbreviated, time: .omitted)
                let timeStr = date.formatted(date: .omitted, time: .shortened)
                Text("\(dateStr) • \(timeStr)")
                    .font(.caption)
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
    }
}

// MARK: - Smart Confirmation Badge

struct SmartConfirmationBadge: View {
    let confidence: Double
    let status: ParsingStatus
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if status == .parsing {
                    ProgressView()
                        .controlSize(.small)
                    Text("Still thinking about the category…")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                } else {
                    Image(systemName: confidence >= 0.8 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(confidence >= 0.8 ? Color.green : Color.orange)
                    
                    Text(confidence >= 0.8 ? "Looks good!" : "Please review a few details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                }
            }
            
            if status == .parsing {
                Text("You don't have to wait — save now and we'll fill in the rest.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.easeInOut(duration: 0.3), value: status)
    }
}

// MARK: - Editable Row

struct EditableRow<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var isLast: Bool = false
    @ViewBuilder let valueContent: () -> Content
    let action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
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
        .buttonStyle(.plain)
    }
}

// MARK: - Editable Detail Section

struct EditableDetailSection: View {
    @Binding var transactionType: TransactionType
    let category: Category?
    let account: Account?
    @Binding var paymentMethod: PaymentMethod
    @Binding var date: Date
    let status: ParsingStatus
    
    let onCategoryTap: () -> Void
    let onAccountTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Type
            EditableRow(
                title: "Type",
                icon: "arrow.up.arrow.down",
                iconColor: .gray,
                valueContent: {
                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                },
                action: nil
            )
            
            // Category
            let catName = category?.name ?? "None"
            let catIcon = category?.icon ?? transactionType.symbol
            EditableRow(
                title: "Category",
                icon: catIcon,
                iconColor: categoryColor,
                valueContent: {
                    if status == .parsing && category == nil {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Thinking…")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(catName)
                    }
                },
                action: onCategoryTap
            )
            .animation(.easeInOut(duration: 0.3), value: category?.name)
            
            // Account
            let accName = account?.name ?? "None"
            let accIcon = account?.icon ?? "creditcard"
            let accColor = account != nil ? Color(hex: account!.colorHex) : Color.memoPrimary
            EditableRow(
                title: "Account",
                icon: accIcon,
                iconColor: accColor,
                valueContent: { Text(accName) },
                action: onAccountTap
            )
            
            // Payment Method
            EditableRow(
                title: "Payment",
                icon: "banknote",
                iconColor: Color.memoIncome,
                valueContent: {
                    Picker("Payment", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                },
                action: nil
            )
            
            // Date
            EditableRow(
                title: "Date",
                icon: "calendar",
                iconColor: Color.memoAccent,
                isLast: true,
                valueContent: {
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .tint(Color.memoPrimary)
                },
                action: nil
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var categoryColor: Color {
        guard let hex = category?.colorHex else {
            switch transactionType {
            case .expense: return .memoExpense
            case .income: return .memoIncome
            case .transfer: return .memoPrimary
            }
        }
        return Color(hex: hex)
    }
}

// MARK: - Editable Notes Section

struct EditableNotesSection: View {
    @Binding var note: String
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Add a note (optional)", text: $note, axis: .vertical)
                .font(.body)
                .foregroundStyle(Color.primary)
                .padding(16)
                .frame(minHeight: 100, alignment: .topLeading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Save Toolbar

struct SaveActionToolbar: View {
    let isSaving: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                onSave()
            } label: {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save Memory")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(Color.memoPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .disabled(isSaving)
        }
        .background(.ultraThinMaterial)
    }
}
