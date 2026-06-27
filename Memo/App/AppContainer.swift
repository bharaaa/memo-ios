//
//  AppContainer.swift
//  Memo
//
//  Dependency injection root. All services are created here and
//  injected via SwiftUI's environment. ViewModels receive what they
//  need — nothing more.
//
//  To inject into a view:
//    @Environment(AppContainer.self) private var container
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppContainer {

    // MARK: - Services (created once, shared)

    let memoService: MemoService
    let transactionService: TransactionService
    let categoryService: CategoryService
    let ocrService: OCRService

    // MARK: - Persistence

    let persistenceController: PersistenceController

    // MARK: - User Preferences

    @ObservationIgnored
    @AppStorage("preferredCurrencyCode")
    var preferredCurrencyCode: String = "IDR"

    @ObservationIgnored
    @AppStorage("hasCompletedOnboarding")
    var hasCompletedOnboarding: Bool = false

    @ObservationIgnored
    @AppStorage("userName")
    var userName: String = ""

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        let context = persistenceController.container.mainContext

        self.memoService         = MemoService()
        self.transactionService  = TransactionService(context: context)
        self.categoryService     = CategoryService(context: context)
        self.ocrService          = OCRService()
    }

    // MARK: - Onboarding Completion

    func completeOnboarding(currency: String, name: String) {
        preferredCurrencyCode = currency
        userName = name
        hasCompletedOnboarding = true

        // Seed default categories and accounts in the chosen currency
        try? persistenceController.seedDefaultDataIfNeeded(currencyCode: currency)
    }
}
