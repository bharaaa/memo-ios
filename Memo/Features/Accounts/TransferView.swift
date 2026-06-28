//
//  TransferView.swift
//  Memo
//

import SwiftUI
import SwiftData

@MainActor
struct TransferView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: TransferViewModel
    
    @Query(filter: #Predicate<Account> { $0.isArchived == false }, sort: \Account.sortOrder)
    private var accounts: [Account]
    
    init(context: ModelContext, transactionService: TransactionService) {
        _viewModel = State(wrappedValue: TransferViewModel(transactionService: transactionService, modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", text: $viewModel.amountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("From", selection: $viewModel.sourceAccount) {
                        Text("Select Account").tag(Account?.none)
                        ForEach(accounts) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }
                    
                    Picker("To", selection: $viewModel.destinationAccount) {
                        Text("Select Account").tag(Account?.none)
                        ForEach(accounts) { account in
                            Text(account.name).tag(Account?.some(account))
                        }
                    }
                }
                
                Section {
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    TextField("Note (Optional)", text: $viewModel.note)
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.memoExpense)
                            .font(.memoCaption)
                    }
                }
            }
            .navigationTitle("New Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if viewModel.save() {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isSaving)
                }
            }
        }
    }
}
