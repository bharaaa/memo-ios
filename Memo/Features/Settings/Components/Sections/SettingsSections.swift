//
//  SettingsSections.swift
//  Memo
//
//  Modular section components for the SettingsView.
//

import SwiftUI
import SwiftData

// MARK: - Preferences Section

struct PreferencesSection: View {
    let searchText: String
    let preferredCurrency: String
    let onCurrencyTap: () -> Void
    
    var body: some View {
        Section("Preferences") {
            if matches("Appearance Theme Icon") {
                SettingsNavigationRow(
                    title: "Appearance",
                    icon: "paintpalette.fill",
                    iconColor: .blue,
                    destination: SettingsView.SettingsRoute.appearance
                )
            }
            if matches("Currency Money") {
                SettingsActionRow(
                    title: "Currency",
                    icon: "dollarsign.circle.fill",
                    iconColor: .green,
                    value: preferredCurrency,
                    action: onCurrencyTap
                )
            }
            // Mocks for UI completeness
            if matches("Language") {
                SettingsActionRow(
                    title: "Language",
                    icon: "globe",
                    iconColor: .indigo,
                    value: "English",
                    action: {}
                )
            }
            if matches("Notifications") {
                SettingsActionRow(
                    title: "Notifications",
                    icon: "bell.badge.fill",
                    iconColor: .red,
                    value: "Enabled",
                    action: {}
                )
            }
        }
    }
    
    private func matches(_ keywords: String) -> Bool {
        if searchText.isEmpty { return true }
        return keywords.localizedCaseInsensitiveContains(searchText)
    }
}

// MARK: - Finance Section

struct FinanceSection: View {
    let searchText: String
    
    @Query private var accounts: [Account]
    @Query private var categories: [Category]
    
    var body: some View {
        Section("Finance") {
            if matches("Accounts Banks Cash") {
                SettingsNavigationRow(
                    title: "Accounts",
                    icon: "building.columns.fill",
                    iconColor: .orange,
                    subtitle: "\(accounts.count)",
                    destination: SettingsView.SettingsRoute.accounts
                )
            }
            if matches("Categories Tags") {
                SettingsNavigationRow(
                    title: "Categories",
                    icon: "tag.fill",
                    iconColor: .purple,
                    subtitle: "\(categories.count)",
                    destination: SettingsView.SettingsRoute.categories
                )
            }
            if matches("Budgets Limits") {
                SettingsNavigationRow(
                    title: "Budgets",
                    icon: "chart.pie.fill",
                    iconColor: .pink,
                    subtitle: "0",
                    destination: SettingsView.SettingsRoute.budgets
                )
            }
        }
    }
    
    private func matches(_ keywords: String) -> Bool {
        if searchText.isEmpty { return true }
        return keywords.localizedCaseInsensitiveContains(searchText)
    }
}

// MARK: - AI Settings Section

struct AISettingsSection: View {
    let searchText: String
    @Binding var openAIKey: String
    @Binding var openAIBaseURL: String
    @Binding var openAIModel: String
    let providerStatus: [String: Bool]
    
    var body: some View {
        Section("Artificial Intelligence") {
            if matches("API Key Token OpenAI") {
                HStack(spacing: 14) {
                    SettingsIcon(iconName: "key.fill", backgroundColor: .gray)
                    Text("API Key")
                    Spacer()
                    SecureField("sk-...", text: $openAIKey)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .onChange(of: openAIKey) { _, v in
                            UserDefaults.standard.set(v, forKey: "openai_api_key")
                        }
                }
            }
            if matches("Base URL Host") {
                HStack(spacing: 14) {
                    SettingsIcon(iconName: "network", backgroundColor: .blue)
                    Text("Base URL")
                    Spacer()
                    TextField("https://...", text: $openAIBaseURL)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .onChange(of: openAIBaseURL) { _, v in
                            UserDefaults.standard.set(v, forKey: "openai_base_url")
                        }
                }
            }
            if matches("Model Name AI") {
                HStack(spacing: 14) {
                    SettingsIcon(iconName: "cpu", backgroundColor: .purple)
                    Text("Model")
                    Spacer()
                    TextField("gpt-4o-mini", text: $openAIModel)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .onChange(of: openAIModel) { _, v in
                            UserDefaults.standard.set(v, forKey: "openai_model")
                        }
                }
            }
            
            if !providerStatus.isEmpty && matches("Status Provider Apple") {
                ForEach(providerStatus.sorted(by: { $0.key < $1.key }), id: \.key) { name, available in
                    SettingsRow(
                        title: name.replacingOccurrences(of: "_", with: " ").capitalized,
                        icon: available ? "checkmark.seal.fill" : "xmark.seal.fill",
                        iconColor: available ? .green : .gray,
                        value: available ? "Available" : "Unavailable"
                    )
                }
            }
        }
    }
    
    private func matches(_ keywords: String) -> Bool {
        if searchText.isEmpty { return true }
        return keywords.localizedCaseInsensitiveContains(searchText)
    }
}

// MARK: - Data Section

struct DataSection: View {
    let searchText: String
    
    var body: some View {
        Section("Data") {
            if matches("Export Backup Share") {
                SettingsActionRow(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    iconColor: .teal,
                    value: "Yesterday",
                    action: {}
                )
            }
            if matches("Import Restore") {
                SettingsActionRow(
                    title: "Import Data",
                    icon: "square.and.arrow.down",
                    iconColor: .indigo,
                    action: {}
                )
            }
            if matches("Storage Disk") {
                SettingsActionRow(
                    title: "Storage",
                    icon: "externaldrive.fill",
                    iconColor: .gray,
                    value: "52 MB Used",
                    action: {}
                )
            }
        }
    }
    
    private func matches(_ keywords: String) -> Bool {
        if searchText.isEmpty { return true }
        return keywords.localizedCaseInsensitiveContains(searchText)
    }
}

// MARK: - About Section

struct AboutSection: View {
    let searchText: String
    
    var body: some View {
        Section("About") {
            if matches("Version Build App") {
                SettingsRow(title: "Version", icon: "info.circle.fill", iconColor: .gray, value: "1.0.0")
            }
            if matches("Github Source Code Open") {
                SettingsActionRow(
                    title: "GitHub Repository",
                    icon: "curlybraces",
                    iconColor: .black,
                    action: {}
                )
            }
            if matches("Rate App Store Star") {
                SettingsActionRow(
                    title: "Rate Memo",
                    icon: "star.fill",
                    iconColor: .yellow,
                    action: {}
                )
            }
        }
    }
    
    private func matches(_ keywords: String) -> Bool {
        if searchText.isEmpty { return true }
        return keywords.localizedCaseInsensitiveContains(searchText)
    }
}

// MARK: - Danger Zone Section

struct DangerZoneSection: View {
    let searchText: String
    let onLogoutTap: () -> Void
    
    var body: some View {
        Section {
            if matches("Logout Sign Out Leave") {
                SettingsActionRow(
                    title: "Sign Out",
                    icon: "rectangle.portrait.and.arrow.right.fill",
                    iconColor: .red,
                    showChevron: false,
                    role: .destructive,
                    action: onLogoutTap
                )
            }
            if matches("Reset Delete Local Data") {
                SettingsActionRow(
                    title: "Delete Local Data",
                    icon: "trash.fill",
                    iconColor: .red,
                    showChevron: false,
                    role: .destructive,
                    action: {}
                )
            }
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Destructive actions cannot be undone.")
        }
    }
    
    private func matches(_ keywords: String) -> Bool {
        if searchText.isEmpty { return true }
        return keywords.localizedCaseInsensitiveContains(searchText)
    }
}
