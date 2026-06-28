//
//  LocalParser.swift
//  Memo
//
//  Fast, deterministic regex-based parser.
//  Target execution time: < 10ms.
//

import Foundation

struct LocalParser {
    
    // MARK: - Entry Point
    
    func parse(input: String) -> LocalParsingResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return LocalParsingResult(transactionType: .expense, confidence: 0.0, missingFields: ["amount"])
        }
        
        var result = LocalParsingResult(
            transactionType: detectTransactionType(from: trimmed),
            confidence: 0.0
        )
        
        result.date          = extractDate(from: trimmed)
        result.amount        = extractAmount(from: trimmed)
        result.merchantGuess = extractMerchant(from: trimmed)
        
        // Confidence scoring
        var score = 0.0
        if result.amount != nil { score += 0.60 } else { result.missingFields.append("amount") }
        if result.merchantGuess != nil { score += 0.25 } else { result.missingFields.append("merchant") }
        if result.date != nil { score += 0.10 }
        
        // Local parser cannot determine category — always escalate to LLM
        result.missingFields.append("category")
        
        result.confidence = min(score, 0.95)
        
        return result
    }
    
    // MARK: - Amount Extraction
    
    private func extractAmount(from input: String) -> Decimal? {
        let patterns: [String] = [
            #"(?:^|\s)(\d+[\.,]?\d*)\s*k(?:\s|$)"#,
            #"(?:^|\s)(\d+[\.,]?\d*)\s*m(?:\s|$)"#,
            #"(?:rp|idr|usd|\$|€|£)\s*(\d[\d\.,]*)"#,
            #"(?:^|\s)(\d{1,3}(?:[.,]\d{3})+)(?:\s|$)"#,
            #"(?:^|\s)(\d+(?:\.\d{1,2})?)(?:\s|$)"#,
        ]
        
        let lower = input.lowercased()
        
        for (idx, pattern) in patterns.enumerated() {
            if let match = lower.firstMatch(pattern: pattern),
               let rawStr = match {
                
                let cleaned = rawStr
                    .replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if let base = Decimal(string: cleaned) {
                    switch idx {
                    case 0: return base * 1_000
                    case 1: return base * 1_000_000
                    default: return base
                    }
                }
            }
        }
        return nil
    }
    
    // MARK: - Date Extraction
    
    private func extractDate(from input: String) -> Date? {
        let lower = input.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        let relativeMap: [String: Int] = [
            "today": 0, "tadi": 0,
            "yesterday": -1, "kemarin": -1, "yest": -1,
            "2 days ago": -2, "2 hari lalu": -2,
            "3 days ago": -3, "3 hari lalu": -3,
        ]
        
        for (keyword, offset) in relativeMap {
            if lower.contains(keyword) {
                return calendar.date(byAdding: .day, value: offset, to: now)?.startOfDay
            }
        }
        
        let dayNames = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"]
        for (idx, day) in dayNames.enumerated() {
            if lower.contains(day) {
                return calendar.previousWeekday(idx + 1, before: now)
            }
        }
        
        return nil
    }
    
    // MARK: - Merchant Extraction
    
    private func extractMerchant(from input: String) -> String? {
        let accountHintRegex = try? NSRegularExpression(pattern: #"(?:using|from|with|pakai|via)\s+[a-zA-Z0-9]+"#, options: .caseInsensitive)
        let cleanedInput = accountHintRegex?.stringByReplacingMatches(in: input, range: NSRange(input.startIndex..., in: input), withTemplate: "") ?? input
        
        var words = cleanedInput.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        let dateKeywords = Set([
            "today","yesterday","kemarin","tadi","monday","tuesday",
            "wednesday","thursday","friday","saturday","sunday",
            "2","3","days","ago","hari","lalu"
        ])
        
        let amountRegex = try? NSRegularExpression(pattern: #"^\d+[\.,]?\d*[kmb]?$"#, options: .caseInsensitive)
        let currencyPrefixes = Set(["rp","idr","usd","$","€","£"])
        
        words = words.filter { word in
            let lower = word.lowercased()
            if dateKeywords.contains(lower) { return false }
            if currencyPrefixes.contains(lower) { return false }
            let range = NSRange(word.startIndex..., in: word)
            if amountRegex?.firstMatch(in: word, range: range) != nil { return false }
            return true
        }
        
        let merchant = words.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return merchant.isEmpty ? nil : merchant.capitalized
    }
    
    // MARK: - Transaction Type Detection
    
    private func detectTransactionType(from input: String) -> TransactionType {
        let lower = input.lowercased()
        let incomeKeywords = ["gajian","salary","gaji","income","masuk","terima","received","refund","cashback"]
        for kw in incomeKeywords {
            if lower.contains(kw) { return .income }
        }
        return .expense
    }
}

// MARK: - String Regex Helper

private extension String {
    func firstMatch(pattern: String) -> String?? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return Optional(nil)
        }
        let range = NSRange(self.startIndex..., in: self)
        guard let match = regex.firstMatch(in: self, range: range) else {
            return Optional(nil)
        }
        if match.numberOfRanges > 1,
           let captureRange = Range(match.range(at: 1), in: self) {
            return Optional(Optional(String(self[captureRange])))
        }
        return Optional(nil)
    }
}

// MARK: - Calendar Helper

private extension Calendar {
    func previousWeekday(_ weekday: Int, before date: Date) -> Date? {
        var components = DateComponents()
        components.weekday = weekday
        return self.nextDate(after: date, matching: components, matchingPolicy: .previousTimePreservingSmallerComponents, direction: .backward)
    }
}
