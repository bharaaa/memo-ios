//
//  HomeView.swift
//  Memo
//
//  The primary screen. Philosophy: calm, welcoming, action-first.
//  No charts. No overwhelming data. Just a greeting, quick actions,
//  and today's memories.
//

import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Account> { $0.isArchived == false }, sort: \Account.sortOrder) private var accounts: [Account]

    @State private var viewModel: HomeViewModel?
    @State private var showChat = false
    @State private var showSpeechOverlay = false
    @State private var showScan = false
    @State private var showImport = false
    @State private var showTransfer = false
    @State private var showPreview = false
    @State private var parsedTransaction: ParsedTransaction?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        accountsSection
                        quickActionsSection
                        todaySection
                    }
                }
                .scrollIndicators(.hidden)
            }
            .background(Color.memoBackground)
            .navigationBarHidden(true)
            .navigationDestination(for: Transaction.self) { transaction in
                TransactionDetailView(transaction: transaction)
            }
        }
        .onAppear { setupViewModel() }
        .sheet(isPresented: $showChat, onDismiss: { viewModel?.load() }) {
            ChatView()
                .environment(appContainer)
        }
        .sheet(isPresented: $showSpeechOverlay, onDismiss: { viewModel?.load() }) {
            SpeechOverlayView { transcript in
                // We're just returning text. We can pass it to a new ChatView if we wanted,
                // but since SpeechOverlay handles opening ChatView manually in HomeView logic:
                // Actually, let's just use it to open chat and pre-fill.
                // For simplicity here, we'll open chat.
                showChat = true
            }
        }
        .sheet(isPresented: $showScan) {
            ScanView(appContainer: appContainer)
        }
        .sheet(isPresented: $showImport) {
            ImportView(appContainer: appContainer)
        }
        .sheet(isPresented: $showTransfer, onDismiss: { viewModel?.load() }) {
            TransferView(context: modelContext, transactionService: appContainer.transactionService)
                .environment(appContainer)
        }
        .sheet(item: $parsedTransaction) { pt in
            TransactionPreviewView(parsed: pt) {
                viewModel?.load()
            }
            .environment(appContainer)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel?.greeting ?? "Hello 👋")
                .font(.memoLargeTitle)
                .foregroundStyle(.memoPrimaryText)

            if let vm = viewModel, !vm.todayTransactions.isEmpty {
                Text(vm.todaySummaryText)
                    .font(.memoSubheadline)
                    .foregroundStyle(.memoSecondaryText)
            } else {
                Text("What would you like to remember?")
                    .font(.memoSubheadline)
                    .foregroundStyle(.memoSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
    
    // MARK: - Accounts Summary
    
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts")
                .font(.memoCaption)
                .foregroundStyle(.memoTertiaryText)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(accounts) { account in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: account.icon)
                                    .foregroundStyle(Color(hex: account.colorHex))
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name)
                                    .font(.memoCaption)
                                    .foregroundStyle(.memoSecondaryText)
                                AmountText(
                                    amount: account.currentBalance,
                                    currencyCode: account.currencyCode,
                                    transactionType: account.currentBalance < 0 ? .expense : .income,
                                    size: .small,
                                    showSign: false
                                )
                            }
                        }
                        .padding(16)
                        .frame(width: 140, alignment: .leading)
                        .background(Color.memoCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a memory")
                .font(.memoCaption)
                .foregroundStyle(.memoTertiaryText)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "keyboard",
                    label: "Type",
                    color: .memoPrimary
                ) { showChat = true }

                QuickActionButton(
                    icon: "mic.fill",
                    label: "Speak",
                    color: .memoAccent
                ) { showSpeechOverlay = true }

                QuickActionButton(
                    icon: "camera.viewfinder",
                    label: "Scan",
                    color: Color(hue: 0.93, saturation: 0.7, brightness: 0.9)
                ) { showScan = true }
                
                QuickActionButton(
                    icon: "arrow.left.arrow.right",
                    label: "Transfer",
                    color: .memoIncome
                ) { showTransfer = true }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Today's Transactions

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(.memoCaption)
                    .foregroundStyle(.memoTertiaryText)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                if let vm = viewModel, !vm.todayTransactions.isEmpty {
                    Text("−\(vm.formattedTodayTotal)")
                        .font(.memoAmountSmall)
                        .foregroundStyle(.memoExpense)
                }
            }
            .padding(.horizontal, 24)

            if let vm = viewModel {
                if vm.todayTransactions.isEmpty {
                    EmptyState(
                        icon: "sparkles",
                        title: "All clear",
                        message: "Tell Memo about a purchase and it will appear here.",
                        action: { showChat = true },
                        actionLabel: "Add first memory"
                    )
                    .padding(.top, 8)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.todayTransactions) { transaction in
                            NavigationLink(value: transaction) {
                                TransactionRowView(transaction: transaction)
                                    .padding(.horizontal, 24)
                            }
                            .buttonStyle(.plain)
                            
                            if transaction != vm.todayTransactions.last {
                                Divider()
                                    .padding(.leading, 72)
                                    .padding(.trailing, 24)
                            }
                        }
                    }
                    .background(Color.memoCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 24)
                }
            }
        }
        .padding(.bottom, 100) // space for tab bar
    }

    // MARK: - Setup

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = HomeViewModel(
                transactionService: appContainer.transactionService,
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
