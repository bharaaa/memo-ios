import SwiftUI

// MARK: - Modifiers

struct MemoCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.memoCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MemoScreenPadding: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(.horizontal, 24)
    }
}

// MARK: - View Extension

extension View {
    /// Applies the standard white rounded card style.
    func memoCardStyle() -> some View {
        modifier(MemoCardStyle())
    }
    
    /// Applies standard horizontal padding (24pt).
    func memoScreenPadding() -> some View {
        modifier(MemoScreenPadding())
    }
}
