//
//  SettingsView.swift
//  Memo
//
//  The primary Settings screen modeled strictly after Apple HIG.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppContainer.self) private var appContainer
    
    @AppStorage("preferredCurrencyCode") private var preferredCurrency = "IDR"
    
    @State private var searchText = ""
    @State private var showCurrencyPicker = false
    @State private var showLogoutConfirmation = false
    
    enum SettingsRoute: Hashable {
        case appearance
        case accounts
        case categories
        case budgets
        case aiProviderSelection
        case language
    }

    var body: some View {
        NavigationStack {
            List {

                PreferencesSection(
                    searchText: searchText,
                    preferredCurrency: preferredCurrency,
                    onCurrencyTap: { showCurrencyPicker = true }
                )
                
                FinanceSection(searchText: searchText)
                
                AISettingsSection(searchText: searchText)
                
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
                case .aiProviderSelection:
                    AIProviderSelectionView()
                case .language:
                    LanguageSettingsView()
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
        .onChange(of: preferredCurrency) { oldValue, newValue in
            if let code = CurrencyCode(rawValue: newValue) {
                CurrencyService.shared.baseCurrency = code
            }
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
}

#Preview {
    SettingsView()
        .environment(AppContainer())
        .environment(LanguageManager.shared)
}
