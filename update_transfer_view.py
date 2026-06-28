import re

with open("Memo/Features/Accounts/TransferView.swift", "r") as f:
    content = f.read()

# Replace State property
content = re.sub(
    r'@State private var viewModel: TransferViewModel\s+@Query\(filter: #Predicate<Account> \{ \$0\.isArchived == false \}, sort: \\Account\.sortOrder\)\s+private var accounts: \[Account\]\s+init\(context: ModelContext, transactionService: TransactionService\) \{\s+_viewModel = State\(wrappedValue: TransferViewModel\(transactionService: transactionService, modelContext: context\)\)\s+\}',
    '''@State private var viewModel: TransferViewModel?
    
    @Query(filter: #Predicate<Account> { $0.isArchived == false }, sort: \\Account.sortOrder)
    private var accounts: [Account]
    
    init(context: ModelContext, transactionService: TransactionService) {
    }''',
    content
)

# Replace body
body_start = content.find("    var body: some View {\n        NavigationStack {\n            Form {")
if body_start != -1:
    new_body_start = '''    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    content(viewModel: vm)
                } else {
                    Color.memoBackground
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = TransferViewModel(
                        transactionService: appContainer.transactionService,
                        modelContext: modelContext
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func content(viewModel: TransferViewModel) -> some View {
        @Bindable var viewModel = viewModel
        Form {'''
    content = content[:body_start] + new_body_start + content[body_start + len("    var body: some View {\n        NavigationStack {\n            Form {"):]

with open("Memo/Features/Accounts/TransferView.swift", "w") as f:
    f.write(content)
