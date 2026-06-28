//
//  ImportViewModel.swift
//  Memo
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
@Observable
final class ImportViewModel {
    
    var isProcessing = false
    var errorMessage: String? = nil
    
    var parsedTransaction: ParsedTransaction?
    var showPreview = false
    
    private let memoService: MemoService
    private let csvParser = CSVParserService()
    
    init(memoService: MemoService) {
        self.memoService = memoService
    }
    
    // MARK: - Photos
    
    func processImageItem(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        isProcessing = true
        errorMessage = nil
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                
                do {
                    let parsed = try await memoService.parse(image: image)
                    handleResult(.success(parsed))
                } catch {
                    handleResult(.failure(error))
                }
            } else {
                throw NSError(domain: "Import", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load image data."])
            }
        } catch {
            errorMessage = error.localizedDescription
            isProcessing = false
        }
    }
    
    // MARK: - Documents (PDF, CSV)
    
    func processDocument(url: URL) async {
        isProcessing = true
        errorMessage = nil
        
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let ext = url.pathExtension.lowercased()
            if ext == "pdf" {
                let data = try Data(contentsOf: url)
                do {
                    let parsed = try await memoService.parse(pdfData: data)
                    handleResult(.success(parsed))
                } catch {
                    handleResult(.failure(error))
                }
            } else if ext == "csv" {
                // For simplicity, we just take the first transaction right now
                let results = try csvParser.parse(url: url)
                if let first = results.first {
                    self.parsedTransaction = first
                    self.showPreview = true
                    self.isProcessing = false
                } else {
                    self.errorMessage = "No transactions found in CSV."
                    self.isProcessing = false
                }
            } else {
                self.errorMessage = "Unsupported file format."
                self.isProcessing = false
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.isProcessing = false
        }
    }
    
    private func handleResult(_ result: Result<ParsedTransaction, Error>) {
        isProcessing = false
        switch result {
        case .success(let parsed):
            self.parsedTransaction = parsed
            self.showPreview = true
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        }
    }
}
