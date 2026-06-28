//
//  TransactionParsingPipeline.swift
//  Memo
//
//  The central orchestrator for the layered AI parsing architecture.
//  It yields a fast local result instantly, then runs semantic models
//  in the background, yielding updated results as they arrive.
//

import Foundation

struct TransactionParsingPipeline {
    
    private let localParser = LocalParser()
    private let mergeEngine = TransactionMergeEngine()
    private let escalationEngine = EscalationEngine()
    
    // Dependencies on the actual AI providers
    private let appleFM = AppleFoundationProvider()
    private let openAI = OpenAICompatibleProvider()
    
    /// Parses the input string and yields results progressively.
    /// The first yield is guaranteed to be fast (< 10ms).
    func parse(input: String, selectedProvider: AIProviderType) -> AsyncStream<ParsedTransaction> {
        AsyncStream { continuation in
            Task {
                do {
                    // 1. Fast Local Parse
                    let localResult = localParser.parse(input: input)
                    
                    var transaction = ParsedTransaction(
                        amount: localResult.amount,
                        currencyCode: localResult.currencyCode,
                        merchantName: localResult.merchantGuess,
                        date: localResult.date,
                        transactionType: localResult.transactionType,
                        confidence: localResult.confidence,
                        status: .parsing,
                        rawInput: input,
                        providerName: "rule_based"
                    )
                    
                    // Yield the optimistic result immediately
                    continuation.yield(transaction)
                    
                    // 2. Decide if we need semantic AI
                    let needsAI = escalationEngine.needsExternalReasoning(for: transaction, missingFields: localResult.missingFields)
                    
                    if needsAI {
                        // 3. Run Semantic AI (Apple Foundation or External)
                        var semanticResult: SemanticParsingResult?
                        var providerUsed = "unknown"
                        
                        switch selectedProvider {
                        case .appleFoundation:
                            if await appleFM.isAvailable {
                                // Try Apple Foundation
                                let aiParsed = try await appleFM.parse(input: input)
                                semanticResult = extractSemantic(from: aiParsed)
                                providerUsed = appleFM.name
                            } else {
                                // Fallback to External if Apple is unavailable but requested?
                                // Architecture rules: don't silently fallback if they explicitly selected Apple.
                                // We will respect selectedProvider. If it's unavailable, we just fail the semantic pass.
                            }
                        case .externalAPI:
                            if await openAI.isAvailable {
                                let aiParsed = try await openAI.parse(input: input)
                                semanticResult = extractSemantic(from: aiParsed)
                                providerUsed = openAI.name
                            }
                        }
                        
                        // 4. Merge results
                        if let semantic = semanticResult {
                            mergeEngine.merge(semantic: semantic, into: &transaction)
                            transaction.providerName = providerUsed
                        }
                    }
                    
                    // Finalize
                    transaction.status = .ready
                    continuation.yield(transaction)
                    continuation.finish()
                    
                } catch {
                    // If semantic AI fails, we still have the local result.
                    // Just mark it as ready (or failed semantic) and finish.
                    // We shouldn't throw away the fast local result.
                    var finalTransaction = ParsedTransaction(rawInput: input)
                    finalTransaction.status = .failed
                    continuation.yield(finalTransaction) // We yield a failed status to notify the UI
                    continuation.finish()
                }
            }
        }
    }
    
    private func extractSemantic(from parsed: ParsedTransaction) -> SemanticParsingResult {
        return SemanticParsingResult(
            merchantName: parsed.merchantName,
            categoryHint: parsed.categoryHint,
            accountHint: parsed.accountHint,
            note: parsed.note,
            paymentMethod: parsed.paymentMethod,
            confidence: parsed.confidence
        )
    }
}
