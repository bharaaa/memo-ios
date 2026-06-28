//
//  TransactionMergeEngine.swift
//  Memo
//
//  Safely merges parser outputs without overwriting user-confirmed fields.
//

import Foundation

struct TransactionMergeEngine {
    
    /// Merges a Foundation or External parsing result into an existing ParsedTransaction.
    /// It only overwrites fields that were previously nil or unconfident.
    func merge(semantic: SemanticParsingResult, into transaction: inout ParsedTransaction) {
        
        // Always respect user data. Only update if the current field is empty.
        
        if transaction.merchantName == nil || transaction.merchantName?.isEmpty == true {
            transaction.merchantName = semantic.merchantName
        }
        
        if transaction.categoryHint == nil || transaction.categoryHint?.isEmpty == true {
            transaction.categoryHint = semantic.categoryHint
        }
        
        if transaction.accountHint == nil || transaction.accountHint?.isEmpty == true {
            transaction.accountHint = semantic.accountHint
        }
        
        if transaction.note == nil || transaction.note?.isEmpty == true {
            transaction.note = semantic.note
        }
        
        if transaction.paymentMethod == nil {
            transaction.paymentMethod = semantic.paymentMethod
        }
        
        // Increase confidence based on the semantic engine's confidence
        if semantic.confidence > transaction.confidence {
            transaction.confidence = semantic.confidence
        }
    }
}
