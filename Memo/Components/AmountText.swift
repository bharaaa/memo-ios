//
//  AmountText.swift
//  Memo
//
//  Renders a currency amount with the correct color (red/green/blue),
//  sign prefix, and monospaced digit font to prevent layout shifts.
//

import SwiftUI

struct AmountText: View {
    @Environment(\.locale) private var locale
    
    let money: Money
    let transactionType: TransactionType
    var size: AmountSize = .regular
    var showSign: Bool = true

    enum AmountSize {
        case small, regular, large
        var font: Font {
            switch self {
            case .small:   return .memoAmountSmall
            case .regular: return .memoAmount
            case .large:   return .memoAmountLarge
            }
        }
    }

    private var sign: String {
        guard showSign else { return "" }
        switch transactionType {
        case .expense:  return "−"
        case .income:   return "+"
        case .transfer: return ""
        }
    }

    var body: some View {
        Text("\(sign)\(MoneyFormatter.format(money, locale: locale, showSign: false))")
            .font(size.font)
            .foregroundStyle(transactionType.color)
            .contentTransition(.numericText())
    }
}

#Preview {
    VStack(spacing: 16) {
        AmountText(money: Money(amount: 45000, currencyCode: .idr), transactionType: .expense, size: .large)
        AmountText(money: Money(amount: 5000000, currencyCode: .idr), transactionType: .income, size: .regular)
        AmountText(money: Money(amount: 12.50, currencyCode: .usd), transactionType: .expense, size: .small)
    }
    .padding()
}
