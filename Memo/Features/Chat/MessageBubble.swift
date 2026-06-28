//
//  MessageBubble.swift
//  Memo
//
//  Renders a single chat message.
//  Three variants:
//  - User bubble (right, indigo)
//  - Memo text bubble (left, material glass)
//  - Memo parsed-transaction card (left, actionable)
//

import SwiftUI

struct MessageBubble: View {
    @Environment(\.locale) private var locale
    let message: ChatViewModel.Message
    var onConfirm: ((ParsedTransaction) -> Void)? = nil

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 60)
                userBubble
            }
        case .memo:
            HStack(alignment: .top) {
                // Memo avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.memoPrimary, Color(hue: 0.75, saturation: 0.8, brightness: 0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    Image(systemName: "brain")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 28, height: 28)

                memoBubble
                Spacer(minLength: 60)
            }
        }
    }

    // MARK: - User Bubble

    private var userBubble: some View {
        Group {
            if case .text(let text) = message.content {
                Text(text)
                    .font(.memoBody)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        BubbleShape(isUser: true)
                            .fill(Color.memoUserBubble)
                    )
            }
        }
    }

    // MARK: - Memo Bubble

    @ViewBuilder
    private var memoBubble: some View {
        switch message.content {
        case .text(let text):
            Text(text)
                .font(.memoBody)
                .foregroundStyle(.memoPrimaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    BubbleShape(isUser: false)
                        .fill(.regularMaterial)
                )

        case .parsedTransaction(let pt):
            parsedCard(pt)

        case .error(let msg):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.memoExpense)
                Text(msg)
                    .font(.memoSubheadline)
                    .foregroundStyle(.memoSecondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            )
        }
    }

    // MARK: - Parsed Transaction Card

    private func parsedCard(_ pt: ParsedTransaction) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 10) {
                // Amount + type
                HStack(alignment: .firstTextBaseline) {
                    Text(pt.transactionType == .income ? "+" : "−")
                        .font(.memoAmount)
                        .foregroundStyle(pt.transactionType.color)
                    
                    if let amount = pt.amount {
                        let money = Money(amount: amount, currencyCode: CurrencyCode(rawValue: pt.currencyCode ?? "") ?? .idr)
                        Text(MoneyFormatter.format(money, locale: locale, showSign: false))
                            .font(.memoAmountSmall)
                            .foregroundStyle(pt.transactionType.color)
                    } else {
                        Text("?")
                            .font(.memoAmountSmall)
                            .foregroundStyle(pt.transactionType.color)
                    }
                }

                // Merchant + category hint
                if let merchant = pt.merchantName {
                    Text(merchant)
                        .font(.memoSubheadline)
                        .foregroundStyle(.memoPrimaryText)
                }

                if let hint = pt.categoryHint {
                    CategoryBadge(icon: "tag.fill", name: hint.capitalized, colorHex: "#6366F1", style: .outlined)
                }

                // Date
                if let date = pt.date {
                    Label(date.memoRelativeLabel, systemImage: "calendar")
                        .font(.memoCaption)
                        .foregroundStyle(.memoSecondaryText)
                }

                Divider()

                // Actions
                HStack {
                    Button("Edit") { onConfirm?(pt) }
                        .font(.memoSubheadline)
                        .foregroundStyle(.memoSecondaryText)
                    Spacer()
                    Button {
                        onConfirm?(pt)
                    } label: {
                        Label("Save", systemImage: "checkmark")
                            .font(.memoHeadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(.memoPrimary))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.memoPrimary.opacity(0.3), lineWidth: 0.5)
                    }
            }
            .frame(maxWidth: 280)
            
            // Subtle Provider Status
            if let type = AIProviderType(rawValue: pt.providerName) {
                Text(type.statusLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.memoSecondaryText)
                    .padding(.leading, 12)
            }
        }
    }
}

// MARK: - Chat Bubble Shape

struct BubbleShape: Shape {
    let isUser: Bool
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 18
        let tailSize: CGFloat = 6
        var path = Path()

        if isUser {
            // Right-aligned tail
            path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width - tailSize, height: rect.height), cornerSize: CGSize(width: r, height: r))
        } else {
            // Left-aligned tail
            path.addRoundedRect(in: CGRect(x: tailSize, y: 0, width: rect.width - tailSize, height: rect.height), cornerSize: CGSize(width: r, height: r))
        }
        return path
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubble(message: .user("Coffee 35k"))
        MessageBubble(message: .memo("Got it! 🍜"))
        MessageBubble(message: .parsed(ParsedTransaction(
            amount: 35000,
            currencyCode: "IDR",
            merchantName: "Coffee Shop",
            categoryHint: "food",
            confidence: 0.92,
            rawInput: "Coffee 35k",
            providerName: "rule_based"
        )))
    }
    .padding()
}
