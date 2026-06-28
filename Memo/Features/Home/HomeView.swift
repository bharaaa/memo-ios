//
//  HomeView.swift
//  Memo
//
//  The primary screen. Philosophy: calm, welcoming, conversation-first.
//

import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: HomeViewModel?
    @State private var showSpeechOverlay = false
    @State private var showScan = false
    @State private var showImport = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Top Padding for Notification Bell
                        Color.clear.frame(height: 16)
                        
                        GreetingSection(
                            timeGreeting: viewModel?.timeGreeting ?? "Hello",
                            userName: viewModel?.userGreetingName ?? ""
                        )
                        
                        if let vm = viewModel {
                            ConversationComposer(
                                text: Binding(
                                    get: { vm.inputText },
                                    set: { vm.inputText = $0 }
                                ),
                                isProcessing: vm.isProcessing,
                                onSend: {
                                    Task {
                                        await vm.send()
                                    }
                                },
                                onImport: { showImport = true },
                                onScan: { showScan = true },
                                onSpeak: { showSpeechOverlay = true }
                            )
                            .padding(.bottom, 24)
                            
                            if let error = vm.parseError {
                                Text(error)
                                    .font(.memoCaption)
                                    .foregroundStyle(.memoExpense)
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 16)
                                    .transition(.opacity)
                            }
                            
                            BalanceSection(
                                totalAssets: vm.formattedTotalAssets,
                                accounts: vm.accounts
                            )
                            
                            RecentMemoriesSection(
                                transactions: vm.recentTransactions,
                                onEmptyAction: {
                                    // Nothing
                                }
                            )
                        }
                    }
                }
                .scrollIndicators(.hidden)
                
                // Top Right Notification Bell
                Button(action: {
                    // Notifications tapped
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundStyle(.memoSecondaryText)
                        
                        Circle()
                            .fill(Color.memoExpense)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
                .padding(.top, 16)
                .padding(.trailing, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .navigationDestination(for: Transaction.self) { transaction in
                TransactionDetailView(transaction: transaction)
            }
            .navigationDestination(for: Account.self) { account in
                AccountDetailView(
                    account: account,
                    context: modelContext
                )
            }
            .navigationDestination(for: String.self) { value in
                if value == "SeeAll" {
                    TransactionListView()
                } else if value == "ViewAllAccounts" {
                    AccountListView()
                }
            }
        }
        .onAppear { setupViewModel() }
        .sheet(isPresented: $showSpeechOverlay, onDismiss: { viewModel?.load() }) {
            SpeechOverlayView { transcript in
                viewModel?.inputText = transcript
            }
        }
        .sheet(isPresented: $showScan) {
            ScanView(appContainer: appContainer)
        }
        .sheet(isPresented: $showImport) {
            ImportView(appContainer: appContainer)
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.parsedTransaction != nil },
            set: { if !$0 { viewModel?.markAsSaved() } }
        )) {
            if let pt = viewModel?.parsedTransaction {
                TransactionPreviewView(parsed: pt) { savedTransaction in
                    viewModel?.markAsSaved(transaction: savedTransaction)
                    viewModel?.load()
                }
                .environment(appContainer)
            }
        }
    }

    // MARK: - Setup

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = HomeViewModel(
                transactionRepository: appContainer.transactionRepository,
                accountRepository: appContainer.accountRepository,
                memoService: appContainer.memoService,
                categoryService: appContainer.categoryService,
                userName: appContainer.userName
            )
        }
        viewModel?.load()
    }
}

// MARK: - ParsedTransaction Identifiable (for sheet binding)

extension ParsedTransaction: Identifiable {
    public var id: String { rawInput + providerName }
}

#Preview {
    HomeView()
        .environment(AppContainer())
        .modelContainer(PersistenceController.shared.container)
}
