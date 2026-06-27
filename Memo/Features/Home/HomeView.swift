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

    @State private var viewModel: HomeViewModel?
    @State private var showChat = false
    @State private var showScan = false
    @State private var showImport = false
    @State private var showPreview = false
    @State private var parsedTransaction: ParsedTransaction?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        quickActionsSection
                        todaySection
                    }
                }
                .scrollIndicators(.hidden)
            }
            .background(Color.memoBackground)
            .navigationBarHidden(true)
        }
        .onAppear { setupViewModel() }
        .sheet(isPresented: $showChat, onDismiss: { viewModel?.load() }) {
            ChatView()
                .environment(appContainer)
        }
        .sheet(isPresented: $showScan) {
            // Placeholder — ScanView coming in next phase
            Text("Scan coming soon")
                .presentationDetents([.medium])
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
                ) { showChat = true }  // Opens chat which will add voice in future

                QuickActionButton(
                    icon: "camera.viewfinder",
                    label: "Scan",
                    color: Color(hue: 0.93, saturation: 0.7, brightness: 0.9)
                ) { showScan = true }

                QuickActionButton(
                    icon: "square.and.arrow.down",
                    label: "Import",
                    color: .memoIncome
                ) { showImport = true }
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
                            TransactionRowView(transaction: transaction)
                                .padding(.horizontal, 24)
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
