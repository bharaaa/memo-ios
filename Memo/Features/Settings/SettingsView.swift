//
//  SettingsView.swift
//  Memo
//
//  The primary Settings screen modeled strictly after Apple HIG.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppContainer.self) private var appContainer
    
    @State private var openAIKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    @State private var openAIBaseURL = UserDefaults.standard.string(forKey: "openai_base_url") ?? "https://api.openai.com/v1"
    @State private var openAIModel = UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4o-mini"
    @State private var providerStatus: [String: Bool] = [:]
    
    @AppStorage("preferredCurrencyCode") private var preferredCurrency = "IDR"
    @AppStorage("userName") private var userName = ""
    
    @State private var searchText = ""
    @State private var showCurrencyPicker = false
    @State private var showLogoutConfirmation = false
    
    enum SettingsRoute: Hashable {
        case appearance
        case accounts
        case categories
        case budgets
    }

    var body: some View {
        NavigationStack {
            List {
                ProfileSection(userName: $userName, searchText: searchText)
                
                PreferencesSection(
                    searchText: searchText,
                    preferredCurrency: preferredCurrency,
                    onCurrencyTap: { showCurrencyPicker = true }
                )
                
                FinanceSection(searchText: searchText)
                
                AISettingsSection(
                    searchText: searchText,
                    openAIKey: $openAIKey,
                    openAIBaseURL: $openAIBaseURL,
                    openAIModel: $openAIModel,
                    providerStatus: providerStatus
                )
                
                DataSection(searchText: searchText)
                
                AboutSection(searchText: searchText)
                
                DangerZoneSection(
                    searchText: searchText,
                    onLogoutTap: { showLogoutConfirmation = true }
                )
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search Settings")
            .task { await loadProviderStatus() }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .appearance:
                    AppearanceSettingsView()
                case .accounts:
                    AccountListView()
                case .categories:
                    CategoryListView()
                case .budgets:
                    Text("Budgets Coming Soon").navigationTitle("Budgets")
                }
            }
        }
        .sheet(isPresented: $showCurrencyPicker) {
            NavigationStack {
                CurrencyPickerView(selected: $preferredCurrency)
                    .padding()
                    .navigationTitle("Currency")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showCurrencyPicker = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Logout from Memo?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Logout", role: .destructive) {
                // Logout logic here
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out? Your local data will remain on this device.")
        }
    }

    private func loadProviderStatus() async {
        providerStatus = await appContainer.memoService.providerStatus()
    }
}

#Preview {
    SettingsView()
        .environment(AppContainer())
}
