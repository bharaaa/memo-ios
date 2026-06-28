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
    let accountRepository: AccountRepositoryProtocol
    let transactionRepository: TransactionRepositoryProtocol
    let categoryRepository: CategoryRepositoryProtocol

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

    init(persistenceController: PersistenceController? = nil) {
        let pc = persistenceController ?? PersistenceController.shared
        self.persistenceController = pc
        let context = pc.container.mainContext

        let categoryRepo = CategoryRepository(context: context)
        let transactionRepo = TransactionRepository(context: context)
        let accountRepo = AccountRepository(context: context)
        
        self.categoryRepository  = categoryRepo
        self.transactionRepository = transactionRepo
        self.accountRepository   = accountRepo
        
        self.categoryService     = CategoryService(repository: categoryRepo, context: context)
        self.transactionService  = TransactionService(
            repository: transactionRepo,
            accountRepository: accountRepo,
            categoryService: self.categoryService,
            context: context,
            conversionEngine: ConversionEngine(),
            currencyService: CurrencyService.shared
        )
        self.memoService         = MemoService()
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
