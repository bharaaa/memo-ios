//
//  QuickActionButton.swift
//  Memo
//
//  Large tappable button with an SF Symbol icon and label.
//  Used on the Home screen for Type / Speak / Scan / Import.
//

import SwiftUI

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.memoCaption)
                    .fontWeight(.medium)
                    .foregroundStyle(.memoSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color.opacity(0.2), lineWidth: 0.5)
                    }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
    }
}

// MARK: - Press Event Modifier

private struct PressEventModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded   { _ in onRelease() }
            )
    }
}

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventModifier(onPress: onPress, onRelease: onRelease))
    }
}

#Preview {
    HStack(spacing: 12) {
        QuickActionButton(icon: "keyboard", label: "Type", color: .memoPrimary) {}
        QuickActionButton(icon: "mic.fill", label: "Speak", color: .memoAccent) {}
        QuickActionButton(icon: "camera.fill", label: "Scan", color: .memoExpense) {}
        QuickActionButton(icon: "square.and.arrow.down", label: "Import", color: .memoIncome) {}
    }
    .padding()
}
