//
//  ContentExtractionService.swift
//  Memo
//
//  Unified entry point for extracting transactions from various content types.
//  Designed to be shared between the main app and future Share Extensions.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ContentExtractionService {
    
    private let memoService: MemoService
    private let csvParser = CSVParserService()
    
    init(memoService: MemoService) {
        self.memoService = memoService
    }
    
    enum ExtractionError: Error, LocalizedError {
        case unsupportedContent
        case dataConversionFailed
        
        var errorDescription: String? {
            switch self {
            case .unsupportedContent:
                return "The shared content type is not supported by Memo."
            case .dataConversionFailed:
                return "Failed to read the provided data."
            }
        }
    }
    
    /// Extract a transaction from text, image, or URL (e.g. PDF/CSV).
    func extract(from item: Any) async -> Result<ParsedTransaction, Error> {
        
        // 1. Text (e.g. highlighted text shared from browser)
        if let text = item as? String {
            do {
                let parsed = try await memoService.parse(input: text)
                return .success(parsed)
            } catch {
                return .failure(error)
            }
        }
        
        // 2. Image (e.g. screenshot shared from Photos)
        if let image = item as? UIImage {
            do {
                let parsed = try await memoService.parse(image: image)
                return .success(parsed)
            } catch {
                return .failure(error)
            }
        }
        
        // 3. URL (PDF or CSV file)
        if let url = item as? URL {
            let ext = url.pathExtension.lowercased()
            
            do {
                if ext == "pdf" {
                    let data = try Data(contentsOf: url)
                    do {
                        let parsed = try await memoService.parse(pdfData: data)
                        return .success(parsed)
                    } catch {
                        return .failure(error)
                    }
                } else if ext == "csv" {
                    let results = try csvParser.parse(url: url)
                    if let first = results.first {
                        return .success(first)
                    } else {
                        return .failure(CSVParserService.CSVError.noDataFound)
                    }
                } else {
                    return .failure(ExtractionError.unsupportedContent)
                }
            } catch {
                return .failure(error)
            }
        }
        
        // 4. Data (Fallback for raw data if provided directly)
        if let data = item as? Data {
            do {
                if let image = UIImage(data: data) {
                    let parsed = try await memoService.parse(image: image)
                    return .success(parsed)
                }
                let parsed = try await memoService.parse(pdfData: data)
                return .success(parsed)
            } catch {
                return .failure(error)
            }
        }
        
        return .failure(ExtractionError.unsupportedContent)
    }
}
