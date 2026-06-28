import re

with open("Memo/Features/Accounts/AccountDetailView.swift", "r") as f:
    content = f.read()

# Replace State property
content = re.sub(
    r'@State private var viewModel: AccountFormViewModel\s+init\(account: Account\? = nil, context: ModelContext, defaultCurrency: String\) \{\s+_viewModel = State\(wrappedValue: AccountFormViewModel\(\s+account: account,\s+modelContext: context,\s+defaultCurrency: defaultCurrency\s+\)\)\s+\}',
    '''@State private var viewModel: AccountFormViewModel?
    private let accountToEdit: Account?
    
    init(account: Account? = nil, context: ModelContext, defaultCurrency: String) {
        self.accountToEdit = account
    }''',
    content
)

# Replace body
body_start = content.find("    var body: some View {\n        Form {")
if body_start != -1:
    new_body_start = '''    var body: some View {
        Group {
            if let vm = viewModel {
                content(viewModel: vm)
            } else {
                Color.memoBackground
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AccountFormViewModel(
                    account: accountToEdit,
                    modelContext: modelContext,
                    defaultCurrency: appContainer.preferredCurrencyCode
                )
            }
        }
    }
    
    @ViewBuilder
    private func content(viewModel: AccountFormViewModel) -> some View {
        @Bindable var viewModel = viewModel
        Form {'''
    content = content[:body_start] + new_body_start + content[body_start + len("    var body: some View {\n        Form {"):]

with open("Memo/Features/Accounts/AccountDetailView.swift", "w") as f:
    f.write(content)
