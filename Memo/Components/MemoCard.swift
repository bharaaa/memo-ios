//
//  MemoCard.swift
//  Memo
//
//  Base card container with adaptive glass background.
//  Used for transaction rows, summary panels, and quick actions.
//

import SwiftUI

struct MemoCard<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.memoPrimary.opacity(0.3), .memoAccent.opacity(0.15)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        MemoCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Food & Drink").font(.memoHeadline)
                Text("Rp 45.000").font(.memoAmount).foregroundStyle(.memoExpense)
            }
        }
        .padding()
    }
}
