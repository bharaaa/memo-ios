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
    @State private var selectedTab = 0

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
    }

    // MARK: - Main Tabs

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            // Home
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView()
            }

            // Memories (all transactions)
            Tab("Memories", systemImage: "brain", value: 1) {
                TransactionListView()
            }

            // Settings
            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                SettingsView()
            }
        }
        .tint(.memoPrimary)
    }
}

#Preview {
    ContentView()
        .environment(AppContainer())
        .modelContainer(PersistenceController.shared.container)
}
