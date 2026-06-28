//
//  ContentView.swift
//  Memo
//
//  Root navigation shell.
//  - Shows OnboardingView on first launch
//  - Then shows the TabView with Home + Memories + Settings
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(AppContainer.self) private var appContainer
    @Environment(LanguageManager.self) private var languageManager
    @State private var selectedTab = 0
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some View {
        Group {
            if !appContainer.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                mainTabs
                    .transition(.opacity.animation(.easeIn(duration: 0.4)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: appContainer.hasCompletedOnboarding)
        .preferredColorScheme(appTheme.colorScheme)
        .environment(\.locale, languageManager.currentLocale)
    }

    // MARK: - Main Tabs

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            // Home
            HomeView()
                .tabItem {
                    Label(L10n.tabHome, systemImage: "house.fill")
                }
                .tag(0)

            // Memories (all transactions)
            TransactionListView()
                .tabItem {
                    Label(L10n.tabMemories, systemImage: "brain")
                }
                .tag(1)

            // Settings
            SettingsView()
                .tabItem {
                    Label(L10n.tabSettings, systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(.memoPrimary)
    }
}

#Preview {
    ContentView()
        .environment(AppContainer())
        .environment(LanguageManager.shared)
        .modelContainer(PersistenceController.shared.container)
}
