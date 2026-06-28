//
//  ScanViewModel.swift
//  Memo
//
//  Handles document camera results, passes them to OCR, then AI pipeline.
//

import Foundation
import UIKit
import Observation

@MainActor
@Observable
final class ScanViewModel {
    
    var isProcessing = false
    var errorMessage: String? = nil
    
    var parsedTransaction: ParsedTransaction?
    var showPreview = false
    
    private let memoService: MemoService
    
    init(memoService: MemoService) {
        self.memoService = memoService
    }
    
    func processScannedImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            let parsed = try await memoService.parse(image: image)
            isProcessing = false
            self.parsedTransaction = parsed
            self.showPreview = true
        } catch {
            isProcessing = false
            self.errorMessage = error.localizedDescription
        }
    }
}
