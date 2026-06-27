//
//  EmptyState.swift
//  Memo
//
//  Displayed when a list has no items (no transactions, no results, etc.).
//

import SwiftUI

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.memoTertiaryText)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 6) {
                Text(title)
                    .font(.memoTitle2)
                    .foregroundStyle(.memoPrimaryText)
                Text(message)
                    .font(.memoSubheadline)
                    .foregroundStyle(.memoSecondaryText)
                    .multilineTextAlignment(.center)
            }

            if let action, let label = actionLabel {
                Button(action: action) {
                    Label(label, systemImage: "plus")
                        .font(.memoHeadline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.memoPrimary))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyState(
        icon: "sparkles",
        title: "Nothing here yet",
        message: "Tell Memo about a purchase and it will remember it for you.",
        action: {},
        actionLabel: "Add your first memory"
    )
}
