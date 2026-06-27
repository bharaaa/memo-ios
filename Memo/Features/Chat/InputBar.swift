//
//  InputBar.swift
//  Memo
//
//  The text input bar at the bottom of ChatView.
//  Grows vertically with content. Send on Return or button tap.
//

import SwiftUI

struct InputBar: View {

    @Binding var text: String
    var isLoading: Bool = false
    var onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Text field
            TextField("Type anything…", text: $text, axis: .vertical)
                .font(.memoBody)
                .lineLimit(1...5)
                .focused($isFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(.regularMaterial)
                }
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }

            // Send button
            Button(action: onSend) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.memoSecondaryBackground))
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(
                            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.memoTertiaryText
                            : Color.memoPrimary
                        )
                        .animation(.spring(response: 0.3), value: text.isEmpty)
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

#Preview {
    InputBar(text: .constant("Coffee 35k"), onSend: {})
}
