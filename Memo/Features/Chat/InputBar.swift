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
    @State private var showSpeechOverlay = false

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
            
            // Mic button
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading {
                Button {
                    showSpeechOverlay = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.memoSecondaryText)
                        .frame(width: 44, height: 44)
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Send button
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading {
                Button(action: onSend) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.memoSecondaryBackground))
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(Color.memoPrimary)
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .animation(.spring(response: 0.3), value: text.isEmpty)
        .animation(.spring(response: 0.3), value: isLoading)
        .sheet(isPresented: $showSpeechOverlay) {
            SpeechOverlayView { transcript in
                text = transcript
            }
        }
    }
}

#Preview {
    InputBar(text: .constant("Coffee 35k"), onSend: {})
}
