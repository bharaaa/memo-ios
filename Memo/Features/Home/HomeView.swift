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

    @Query(filter: #Predicate<Account> { $0.isArchived == false }, sort: \Account.sortOrder) private var accounts: [Account]

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
                        
                        GreetingSection(greeting: viewModel?.greeting ?? "Hello 👋")
                        
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
                                accounts: accounts
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
            .background(Color.memoBackground)
            .navigationBarHidden(true)
            .navigationDestination(for: Transaction.self) { transaction in
                TransactionDetailView(transaction: transaction)
            }
            .navigationDestination(for: Account.self) { account in
                AccountDetailView(
                    account: account,
                    context: modelContext,
                    defaultCurrency: appContainer.preferredCurrencyCode
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
            set: { if !$0 { viewModel?.parsedTransaction = nil } }
        )) {
            if let pt = viewModel?.parsedTransaction {
                TransactionPreviewView(parsed: pt) {
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
                transactionService: appContainer.transactionService,
                accountRepository: appContainer.accountRepository,
                memoService: appContainer.memoService,
                currency: appContainer.preferredCurrencyCode,
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
