//
//  ConversationComposer.swift
//  Memo
//
//  A native, Apple-style input composer.
//

import SwiftUI

struct ConversationComposer: View {
    @Binding var text: String
    let isProcessing: Bool
    let onSend: () -> Void
    
    let onImport: () -> Void
    let onScan: () -> Void
    let onSpeak: () -> Void
    
    @FocusState private var isFocused: Bool
    
    // Auto-rotate placeholders for inspiration
    @State private var placeholderIndex = 0
    let placeholders = [
        "Remember an expense...",
        "Coffee 35k",
        "Lunch 45k yesterday",
        "Paid Netflix using Jago",
        "Transfer 500k to GoPay"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Composer Box
            VStack(alignment: .leading, spacing: 10) {
                // Text Input area
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color.memoPrimary)
                        .padding(.top, 8)
                    
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty && !isFocused {
                            Text(placeholders[placeholderIndex])
                                .font(.body)
                                .foregroundStyle(Color(UIColor.placeholderText))
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                        
                        TextField("", text: $text, axis: .vertical)
                            .font(.body)
                            .foregroundStyle(Color.primary)
                            .focused($isFocused)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                            .lineLimit(1...6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                
                // Toolbar Area
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
                                .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(UIColor.quaternaryLabel) : Color.memoPrimary)
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                    .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            .memoScreenPadding()
            
            // Subtle guidance below composer
            if !isFocused && text.isEmpty {
                Text("Type naturally, AI will organize it.")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 32)
            }
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
