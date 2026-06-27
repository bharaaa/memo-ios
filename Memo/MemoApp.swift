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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
                .modelContainer(container.persistenceController.container)
        }
    }
}
