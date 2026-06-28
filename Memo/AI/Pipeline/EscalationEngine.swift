//
//  EscalationEngine.swift
//  Memo
//
//  Determines if a transaction requires external reasoning (LLM).
//

import Foundation

struct EscalationEngine {
    
    /// Evaluates if the current state of a ParsedTransaction requires escalation
    /// to an external LLM for semantic understanding.
    func needsExternalReasoning(for transaction: ParsedTransaction, missingFields: [String]) -> Bool {
        // 1. Missing Critical Fields
        if transaction.amount == nil || transaction.amount! <= 0 {
            return true
        }
        
        // 2. Missing Semantic Context
        if transaction.merchantName == nil || transaction.merchantName?.isEmpty == true {
            return true
        }
        
        // 3. Low Confidence
        if transaction.confidence < 0.7 {
            return true
        }
        
        // 4. Potentially complex missing fields
        if missingFields.contains("category") || missingFields.contains("account") {
            // Note: In a real app we might check if we can resolve these locally first
            // For now, if we don't have a category hint, escalate to Foundation/External
            return true
        }
        
        return false
    }
}
