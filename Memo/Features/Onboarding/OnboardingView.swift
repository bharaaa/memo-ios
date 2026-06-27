//
//  OnboardingView.swift
//  Memo
//
//  First-launch experience. Three screens:
//  1. Welcome — product introduction
//  2. Currency Picker — user selects their primary currency
//  3. Name — optional, used for the home screen greeting
//
//  After completing onboarding, AppContainer.completeOnboarding()
//  seeds default data and sets hasCompletedOnboarding = true.
//

import SwiftUI

struct OnboardingView: View {

    @Environment(AppContainer.self) private var appContainer

    @State private var step = 0
    @State private var selectedCurrency = "IDR"
    @State private var name = ""
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hue: 0.67, saturation: 0.6, brightness: 0.18),
                    Color(hue: 0.72, saturation: 0.5, brightness: 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient orb
            Circle()
                .fill(Color.memoPrimary.opacity(0.25))
                .blur(radius: 80)
                .frame(width: 320)
                .offset(x: -80, y: -160)
                .allowsHitTesting(false)

            VStack {
                Spacer()

                // Step content
                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: currencyStep
                    case 2: nameStep
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step)

                Spacer()

                // Bottom controls
                VStack(spacing: 12) {
                    // Step indicator
                    HStack(spacing: 6) {
                        ForEach(0..<3) { i in
                            Capsule()
                                .fill(i == step ? Color.white : Color.white.opacity(0.3))
                                .frame(width: i == step ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4), value: step)
                        }
                    }

                    // Continue button
                    Button(action: advance) {
                        Text(step == 2 ? "Let's go →" : "Continue")
                            .font(.memoHeadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(.memoPrimary))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    if step == 2 {
                        Button("Skip name") { finishOnboarding() }
                            .font(.memoSubheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            // App icon placeholder
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.memoPrimary, Color(hue: 0.75, saturation: 0.8, brightness: 0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                Image(systemName: "brain")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white)
            }
            .shadow(color: .memoPrimary.opacity(0.5), radius: 24)

            VStack(spacing: 12) {
                Text("Meet Memo")
                    .font(.memoLargeTitle)
                    .foregroundStyle(.white)

                Text("Memo remembers your money,\nso you don't have to.")
                    .font(.memoTitle2)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "bubble.left.and.text.bubble.right.fill", text: "Just tell Memo what you spent")
                featureRow(icon: "camera.viewfinder", text: "Scan receipts instantly")
                featureRow(icon: "brain",              text: "AI figures out the details")
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    }
            }
        }
        .padding(.horizontal, 32)
    }

    private var currencyStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.memoAccent)

                Text("Your Currency")
                    .font(.memoLargeTitle)
                    .foregroundStyle(.white)

                Text("Pick the currency you use most.\nYou can change this later in Settings.")
                    .font(.memoSubheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            CurrencyPickerView(selected: $selectedCurrency)
        }
        .padding(.horizontal, 24)
    }

    private var nameStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.memoAccent)

            VStack(spacing: 12) {
                Text("What should I call you?")
                    .font(.memoLargeTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Optional — for the greeting on your home screen.")
                    .font(.memoSubheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            TextField("Your name", text: $name)
                .font(.memoTitle2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .tint(.memoAccent)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.08))
                }
                .submitLabel(.done)
                .onSubmit { finishOnboarding() }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.memoPrimary)
                .frame(width: 28)
            Text(text)
                .font(.memoBody)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private func advance() {
        if step == 2 { finishOnboarding(); return }
        withAnimation { step += 1 }
    }

    private func finishOnboarding() {
        appContainer.completeOnboarding(currency: selectedCurrency, name: name)
    }
}

#Preview {
    OnboardingView()
        .environment(AppContainer())
}
