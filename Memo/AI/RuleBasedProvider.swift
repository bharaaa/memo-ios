//
//  RuleBasedProvider.swift
//  Memo
//
//  Deterministic, regex-based parser — the first line of defence.
//  For simple inputs like "Coffee 35k" or "Grab 120", this runs
//  in microseconds with no AI call required.
//
//  Confidence is set high (≥ 0.9) when all key fields are extracted,
//  allowing the orchestrator to skip AI entirely.
//

import Foundation

struct RuleBasedProvider: AIProvider {

    let name = "rule_based"

    var isAvailable: Bool { true }

    // MARK: - Entry Point

    func parse(input: String) async throws -> ParsedTransaction {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AIProviderError.invalidInput("Empty input")
        }

        var result = ParsedTransaction(
            rawInput: trimmed,
            providerName: name
        )

        result.date          = extractDate(from: trimmed)
        result.amount        = extractAmount(from: trimmed)
        result.merchantName  = extractMerchant(from: trimmed)
        result.accountHint   = extractAccountHint(from: trimmed)
        result.transactionType = detectTransactionType(from: trimmed)
        result.paymentMethod = detectPaymentMethod(from: trimmed)

        // Confidence scoring
        var score = 0.0
        if result.amount != nil    { score += 0.60 }
        if result.merchantName != nil { score += 0.25 }
        if result.date != nil      { score += 0.10 }
        result.confidence = min(score, 0.95)

        guard result.isUsable else {
            throw AIProviderError.lowConfidence(result.confidence)
        }

        return result
    }

    // MARK: - Amount Extraction

    private func extractAmount(from input: String) -> Decimal? {
        // Patterns:
        //   35k → 35000     |  1.5m → 1500000
        //   35.000 → 35000  |  35,000 → 35000
        //   Rp35000 / IDR35000
        //   plain 45 (bare number)

        let patterns: [String] = [
            // "35k", "35.5k", "35,5k"
            #"(?:^|\s)(\d+[\.,]?\d*)\s*k(?:\s|$)"#,
            // "1.5m", "2m"
            #"(?:^|\s)(\d+[\.,]?\d*)\s*m(?:\s|$)"#,
            // "Rp 35.000" or "IDR35000"
            #"(?:rp|idr|usd|\$|€|£)\s*(\d[\d\.,]*)"#,
            // "35.000" or "35,000" (thousands separator)
            #"(?:^|\s)(\d{1,3}(?:[.,]\d{3})+)(?:\s|$)"#,
            // plain integer or decimal: "45", "12.50"
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

        // Day-name detection: "monday", "tuesday", etc.
        let dayNames = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"]
        for (idx, day) in dayNames.enumerated() {
            if lower.contains(day) {
                return calendar.previousWeekday(idx + 1, before: now)
            }
        }

        return nil // will default to "now" in the preview screen
    }

    // MARK: - Merchant Extraction

    private func extractMerchant(from input: String) -> String? {
        // Remove account hints first
        let accountHintRegex = try? NSRegularExpression(pattern: #"(?:using|from|with|pakai|via)\s+[a-zA-Z0-9]+"#, options: .caseInsensitive)
        let cleanedInput = accountHintRegex?.stringByReplacingMatches(in: input, range: NSRange(input.startIndex..., in: input), withTemplate: "") ?? input

        // Strip known date words and amount-like tokens, what remains is the merchant.
        var words = cleanedInput.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Remove date keywords
        let dateKeywords = Set([
            "today","yesterday","kemarin","tadi","monday","tuesday",
            "wednesday","thursday","friday","saturday","sunday",
            "2","3","days","ago","hari","lalu"
        ])

        // Remove amount-like tokens
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
    
    // MARK: - Account Extraction
    
    private func extractAccountHint(from input: String) -> String? {
        let pattern = #"(?:using|from|with|pakai|via)\s+([a-zA-Z0-9]+)"#
        if let match = input.lowercased().firstMatch(pattern: pattern), let account = match {
            return account.capitalized
        }
        return nil
    }

    // MARK: - Payment Method Detection

    private func detectPaymentMethod(from input: String) -> PaymentMethod? {
        let lower = input.lowercased()
        if lower.contains("cash") || lower.contains("tunai") { return .cash }
        if lower.contains("debit") || lower.contains("kartu debit") { return .debit }
        if lower.contains("credit") || lower.contains("cc") || lower.contains("kredit") { return .credit }
        if lower.contains("transfer") || lower.contains("tf") { return .transfer }
        return nil
    }
}

// MARK: - String Regex Helper

private extension String {
    /// Returns the first capture group match for the given regex pattern, or nil.
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
    /// Returns the most recent date where weekday == target (1=Sun…7=Sat).
    func previousWeekday(_ weekday: Int, before date: Date) -> Date? {
        var components = DateComponents()
        components.weekday = weekday
        return self.nextDate(after: date, matching: components, matchingPolicy: .previousTimePreservingSmallerComponents, direction: .backward)
    }
}
