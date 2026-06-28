//
//  ImportView.swift
//  Memo
//
//  Action sheet and handlers for importing files (Receipts, PDFs, CSVs).
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@MainActor
struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer
    
    @State private var viewModel: ImportViewModel
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showDocumentPicker = false
    
    init(appContainer: AppContainer) {
        _viewModel = State(wrappedValue: ImportViewModel(memoService: appContainer.memoService))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Import Image (Receipt/Screenshot)", systemImage: "photo")
                    }
                    .onChange(of: selectedPhotoItem) { _, item in
                        Task { await viewModel.processImageItem(item) }
                    }
                    
                    Button {
                        showDocumentPicker = true
                    } label: {
                        Label("Import PDF or CSV", systemImage: "doc.text")
                    }
                } footer: {
                    Text("Memo uses on-device Vision and AI to extract transaction details.")
                }
                
                if viewModel.isProcessing {
                    HStack {
                        Spacer()
                        ProgressView("Processing...")
                        Spacer()
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.memoExpense)
                        .font(.memoCaption)
                }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [UTType.pdf, UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task { await viewModel.processDocument(url: url) }
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .fullScreenCover(isPresented: $viewModel.showPreview) {
            if let parsed = viewModel.parsedTransaction {
                NavigationStack {
                    TransactionPreviewView(parsed: parsed)
                        .environment(appContainer)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Cancel") {
                                    viewModel.showPreview = false
                                    dismiss()
                                }
                            }
                        }
                }
            }
        }
        .onChange(of: viewModel.showPreview) { _, showing in
            if !showing {
                dismiss() // Dismiss import sheet when preview finishes
            }
        }
    }
}
