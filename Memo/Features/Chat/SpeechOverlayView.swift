//
//  SpeechOverlayView.swift
//  Memo
//
//  Fullscreen overlay for speech recording, displaying live transcripts.
//

import SwiftUI
internal import Combine

@MainActor
struct SpeechOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var speechService: SpeechService
    
    var onComplete: (String) -> Void
    
    @State private var isAnimating = false
    
    init(onComplete: @escaping (String) -> Void) {
        self.onComplete = onComplete
        _speechService = State(wrappedValue: SpeechService())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.memoBackground.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Waveform (Simulated for UI)
                    HStack(spacing: 6) {
                        ForEach(0..<7) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.memoPrimary)
                                .frame(width: 8, height: isAnimating ? CGFloat.random(in: 20...100) : 10)
                                .animation(
                                    speechService.isRecording ? 
                                        .easeInOut(duration: 0.3).repeatForever().delay(Double(index) * 0.1) : 
                                        .default,
                                    value: isAnimating
                                )
                        }
                    }
                    .frame(height: 100)
                    .onReceive(Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()) { _ in
                        if speechService.isRecording {
                            isAnimating.toggle()
                        } else {
                            isAnimating = false
                        }
                    }
                    
                    // Transcript
                    ScrollView {
                        Text(speechService.transcript.isEmpty ? "Listening..." : speechService.transcript)
                            .font(.memoTitle2)
                            .foregroundStyle(speechService.transcript.isEmpty ? .memoSecondaryText : .memoPrimaryText)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(height: 200)
                    
                    Spacer()
                    
                    // Controls
                    Button {
                        if speechService.isRecording {
                            speechService.stopRecording()
                            onComplete(speechService.transcript)
                            dismiss()
                        } else {
                            try? speechService.startRecording()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(speechService.isRecording ? Color.memoExpense : Color.memoPrimary)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Dictate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        speechService.stopRecording()
                        dismiss()
                    }
                    .foregroundStyle(.memoSecondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        speechService.stopRecording()
                        onComplete(speechService.transcript)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(speechService.transcript.isEmpty)
                }
            }
        }
        .task {
            await speechService.requestAuthorization()
            if speechService.isAuthorized {
                try? speechService.startRecording()
            }
        }
        .onDisappear {
            speechService.stopRecording()
        }
    }
}

#Preview {
    SpeechOverlayView { _ in }
}
