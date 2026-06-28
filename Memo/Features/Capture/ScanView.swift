//
//  ScanView.swift
//  Memo
//
//  Uses VisionKit to scan documents (receipts).
//

import SwiftUI
import VisionKit

@MainActor
struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppContainer.self) private var appContainer
    
    @State private var viewModel: ScanViewModel
    
    init(appContainer: AppContainer) {
        _viewModel = State(wrappedValue: ScanViewModel(memoService: appContainer.memoService))
    }
    
    var body: some View {
        ZStack {
            if viewModel.isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Reading Receipt...")
                        .font(.memoHeadline)
                        .foregroundStyle(.memoPrimaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.memoBackground)
            } else {
                DocumentCameraView { image in
                    if let image = image {
                        Task { await viewModel.processScannedImage(image) }
                    } else {
                        dismiss()
                    }
                }
                .ignoresSafeArea()
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
                dismiss()
            }
        }
        .alert("Scan Failed", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
                dismiss()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - UIViewControllerRepresentable

struct DocumentCameraView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var completion: (UIImage?) -> Void
        
        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
                // For now, just take the first page
                completion(scan.imageOfPage(at: 0))
            } else {
                completion(nil)
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            completion(nil)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document camera error: \(error.localizedDescription)")
            completion(nil)
        }
    }
}
