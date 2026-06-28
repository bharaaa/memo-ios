//
//  ConversationComposer.swift
//  Memo
//
//  A native, Apple-style input composer with progressive expansion.
//

import SwiftUI

struct ConversationComposer: View {
    @Binding var text: String
    let isProcessing: Bool
    let onSend: () -> Void
    
    let onImport: () -> Void
    let onScan: () -> Void
    let onSpeak: () -> Void
    
    var isFocused: FocusState<Bool>.Binding
    
    // Auto-rotate placeholders for inspiration
    @State private var placeholderIndex = 0
    let placeholders = [
        "Remember an expense...",
        "Coffee 35k",
        "Lunch 45k yesterday",
        "Paid Netflix using Jago",
        "Transfer 500k to Cash",
        "Bought groceries 180k"
    ]
    
    var isExpanded: Bool {
        isFocused.wrappedValue || !text.isEmpty || isProcessing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Composer Box
            VStack(alignment: .leading, spacing: 0) {
                // Text Input area
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(isExpanded ? Color.memoPrimary : Color(UIColor.secondaryLabel))
                        // Make sure it visually centers with the single line text field when collapsed
                        .padding(.top, isExpanded ? 4 : 0)
                    
                    ZStack(alignment: isExpanded ? .topLeading : .leading) {
                        if text.isEmpty && !isFocused.wrappedValue {
                            Text(placeholders[placeholderIndex])
                                .font(.body)
                                .foregroundStyle(Color(UIColor.quaternaryLabel))
                                .padding(.top, isExpanded ? 4 : 0)
                                .allowsHitTesting(false)
                        }
                        
                        TextField("", text: $text, axis: .vertical)
                            .font(.body)
                            .foregroundStyle(Color.primary)
                            .focused(isFocused)
                            .padding(.top, isExpanded ? 4 : 0)
                            .lineLimit(isExpanded ? 1...6 : 1...1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, isExpanded ? 12 : 16)
                
                // Toolbar Area (Only visible when expanded)
                if isExpanded {
                    Divider()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        
                    HStack(spacing: 24) {
                        Button(action: onImport) {
                            Image(systemName: "paperclip")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(Color.secondary)
                        }
                        
                        Button(action: onScan) {
                            Image(systemName: "camera")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(Color.secondary)
                        }
                        
                        Button(action: onSpeak) {
                            Image(systemName: "mic")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(Color.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: onSend) {
                            if isProcessing {
                                ProgressView()
                                    .tint(Color.memoPrimary)
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(text.isEmpty ? Color.memoPrimary.opacity(0.5) : Color.white)
                                    .background(
                                        Circle().fill(text.isEmpty ? Color.gray.opacity(0.2) : Color.memoPrimary)
                                    )
                            }
                        }
                        .disabled(text.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, isExpanded ? 16 : 14)
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isFocused.wrappedValue ? Color.memoPrimary.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused.wrappedValue)
            .memoScreenPadding()
        }
        .onAppear {
            startPlaceholderTimer()
        }
    }
    
    private func startPlaceholderTimer() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                placeholderIndex = (placeholderIndex + 1) % placeholders.count
            }
        }
    }
}
