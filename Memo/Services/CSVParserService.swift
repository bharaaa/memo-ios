//
//  CSVParserService.swift
//  Memo
//
//  Parses simple CSV bank statements.
//

import Foundation

struct CSVParserService {
    
    enum CSVError: Error {
        case unreadableFile
        case noDataFound
    }
    
    /// Parses a simple CSV format (Date, Description, Amount)
    func parse(url: URL) throws -> [ParsedTransaction] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw CSVError.noDataFound
        }
        
        var transactions: [ParsedTransaction] = []
        
        // Skip header line
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            if columns.count >= 3 {
                let dateStr = columns[0].trimmingCharacters(in: .whitespaces)
                let desc = columns[1].trimmingCharacters(in: .whitespaces)
                let amountStr = columns[2].trimmingCharacters(in: .whitespaces)
                
                // Very basic parsing
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: dateStr) ?? Date()
                
                let stripped = amountStr.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".-")).inverted).joined()
                
                if let amountDouble = Double(stripped) {
                    let type: TransactionType = amountDouble < 0 ? .expense : .income
                    
                    let parsed = ParsedTransaction(
                        amount: Decimal(abs(amountDouble)),
                        currencyCode: nil, // Leave for preferred
                        merchantName: desc,
                        categoryHint: desc,
                        note: "Imported from CSV",
                        date: date,
                        paymentMethod: .transfer,
                        transactionType: type,
                        confidence: 1.0, // Definite from CSV
                        rawInput: line,
                        providerName: "CSV Import"
                    )
                    transactions.append(parsed)
                }
            }
        }
        
        return transactions
    }
}
