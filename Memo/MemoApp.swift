//
//  MemoApp.swift
//  Memo
//
//  App entry point. Wires together:
//  - PersistenceController (SwiftData)
//  - AppContainer (DI root)
//  - ContentView (navigation shell)
//

import SwiftUI
import SwiftData

@main
struct MemoApp: App {

    @State private var container = AppContainer()
    @State private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
                .environment(languageManager)
                .environment(\.locale, languageManager.currentLocale)
                .modelContainer(container.persistenceController.container)
        }
    }
}
