//
//  ChatView.swift
//  Memo
//
//  The primary input experience. Looks like Messages.
//  User types naturally; Memo responds concisely with parsed
//  transaction cards that can be confirmed or edited.
//

import SwiftUI
import SwiftData

struct ChatView: View {

    @Environment(AppContainer.self) private var appContainer
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ChatViewModel?
    @State private var scrollID: UUID?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Introductory hint
                            if viewModel?.messages.isEmpty == true {
                                hintBubbles
                            }

                            ForEach(viewModel?.messages ?? []) { message in
                                MessageBubble(message: message) { parsed in
                                    viewModel?.confirmTransaction(parsed)
                                }
                                .id(message.id)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            // Typing indicator
                            if viewModel?.isProcessing == true {
                                typingIndicator
                            }

                            // Invisible anchor for scrolling to bottom
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel?.messages.count)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel?.messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .onChange(of: viewModel?.isProcessing) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                // Input
                InputBar(
                    text: Binding(
                        get: { viewModel?.inputText ?? "" },
                        set: { viewModel?.inputText = $0 }
                    ),
                    isLoading: viewModel?.isProcessing ?? false
                ) {
                    Task { await viewModel?.send() }
                }
            }
            .background(Color.memoBackground)
            .navigationTitle("Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.memoHeadline)
                }
            }
        }
        .onAppear { setupViewModel() }
        .sheet(item: Binding(
            get: { viewModel?.showingPreview },
            set: { viewModel?.showingPreview = $0 }
        )) { parsed in
            TransactionPreviewView(parsed: parsed) { savedTransaction in
                viewModel?.markAsSaved(transaction: savedTransaction)
                dismiss()
            }
            .environment(appContainer)
        }
    }

    // MARK: - Hint Bubbles

    private var hintBubbles: some View {
        VStack(spacing: 8) {
            Text("Hi, I'm Memo.")
                .font(.memoHeadline)
                .foregroundStyle(.memoPrimaryText)
            Text("Tell me about a purchase and I'll remember it for you.")
                .font(.memoSubheadline)
                .foregroundStyle(.memoSecondaryText)
                .multilineTextAlignment(.center)

            VStack(spacing: 6) {
                ForEach(examples, id: \.self) { example in
                    Button {
                        viewModel?.inputText = example
                    } label: {
                        Text(example)
                            .font(.memoBody)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.memoSecondaryBackground))
                            .foregroundStyle(.memoPrimaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private let examples = [
        "Coffee 35k",
        "Lunch 45k at Warung Bu Sari",
        "Grab 22k",
        "Yesterday dinner 80k",
    ]

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.memoTertiaryText)
                        .frame(width: 6, height: 6)
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(i) * 0.15),
                            value: viewModel?.isProcessing
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(.regularMaterial)
            )
            Spacer()
        }
    }

    // MARK: - Setup

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = ChatViewModel(
                memoService: appContainer.memoService,
                transactionService: appContainer.transactionService,
                categoryService: appContainer.categoryService,
                accountRepository: appContainer.accountRepository
            )
        }
    }
}

#Preview {
    ChatView()
        .environment(AppContainer())
        .modelContainer(PersistenceController.shared.container)
}
