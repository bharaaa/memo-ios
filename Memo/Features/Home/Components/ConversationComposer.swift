import SwiftUI

struct ConversationComposer: View {
    @Binding var text: String
    let isProcessing: Bool
    let onSend: () -> Void
    
    let onImport: () -> Void
    let onScan: () -> Void
    let onSpeak: () -> Void
    
    @FocusState private var isFocused: Bool
    
    let suggestions = [
        "Coffee 35k",
        "Lunch 45k yesterday",
        "Grab 95k",
        "Netflix 59k using Jago",
        "Groceries 180k"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Composer Box
            VStack(alignment: .leading, spacing: 12) {
                // Text Input area
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.memoPrimary)
                        .padding(.top, 8)
                    
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty && !isFocused {
                            Text("Remember an expense...")
                                .font(.memoBody)
                                .foregroundStyle(.memoTertiaryText)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                        
                        TextField("", text: $text, axis: .vertical)
                            .font(.memoBody)
                            .foregroundStyle(.memoPrimaryText)
                            .focused($isFocused)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                            .lineLimit(1...5)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Toolbar Area
                HStack(spacing: 20) {
                    Button(action: onImport) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 20))
                            .foregroundStyle(.memoSecondaryText)
                    }
                    
                    Button(action: onScan) {
                        Image(systemName: "camera")
                            .font(.system(size: 20))
                            .foregroundStyle(.memoSecondaryText)
                    }
                    
                    Button(action: onSpeak) {
                        Image(systemName: "mic")
                            .font(.system(size: 20))
                            .foregroundStyle(.memoSecondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: onSend) {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.memoPrimary)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.memoPrimary.opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0))
                                .clipShape(Circle())
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                    .animation(.easeInOut, value: text.isEmpty)
                    .animation(.easeInOut, value: isProcessing)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .memoCardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.memoPrimary.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: Color.memoPrimary.opacity(0.05), radius: 10, x: 0, y: 4)
            .memoScreenPadding()
            
            // Suggestion Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            text = suggestion
                            isFocused = true
                        } label: {
                            Text(suggestion)
                                .font(.memoCaption)
                                .foregroundStyle(Color.memoPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.memoPrimary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .memoScreenPadding()
            }
        }
    }
}
