//
//  OpenAICompatibleProvider.swift
//  Memo
//
//  HTTP-based fallback provider. Compatible with OpenAI, Mistral,
//  Ollama, or any OpenAI-compatible API.
//
//  Configuration is stored in UserDefaults (set via Settings screen).
//  Never crashes if keys are missing — just throws .unavailable.
//

import Foundation

struct OpenAICompatibleProvider: AIProvider {

    let name = "openai_compatible"

    // MARK: - Configuration

    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "openai_api_key")
    }

    private var baseURL: String {
        UserDefaults.standard.string(forKey: "openai_base_url")
        ?? "https://api.openai.com/v1"
    }

    private var model: String {
        UserDefaults.standard.string(forKey: "openai_model")
        ?? "gpt-4o-mini"
    }

    // MARK: - Availability

    var isAvailable: Bool {
        get async {
            guard let key = apiKey, !key.isEmpty else { return false }
            return URL(string: baseURL) != nil
        }
    }

    // MARK: - Parse

    func parse(input: String) async throws -> ParsedTransaction {
        guard await isAvailable, let key = apiKey else {
            throw AIProviderError.unavailable
        }

        let systemPrompt = """
        You are a financial assistant. Extract transaction details and respond ONLY with valid JSON.
        Schema: { "amount": number|null, "currencyCode": string|null, "merchantName": string|null,
          "categoryHint": string|null, "note": string|null, "dateString": string|null (YYYY-MM-DD),
          "transactionType": "expense"|"income", "confidence": number (0-1) }
        Rules: "k" = *1000, "m" = *1000000. Default transactionType to "expense".
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": input]
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "response_format": ["type": "json_object"],
            "max_tokens": 256,
            "temperature": 0.1
        ]

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIProviderError.networkError("Invalid base URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw AIProviderError.parseFailure("Failed to encode request body")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIProviderError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AIProviderError.networkError("HTTP \(status)")
        }

        return try parseResponse(data: data, rawInput: input)
    }

    // MARK: - Response Parsing

    private func parseResponse(data: Data, rawInput: String) throws -> ParsedTransaction {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = root["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String,
              let jsonData = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            throw AIProviderError.parseFailure("Could not decode API response")
        }

        var result = ParsedTransaction(rawInput: rawInput, providerName: name)

        if let a = json["amount"] as? Double, a > 0 { result.amount = Decimal(a) }
        result.currencyCode  = json["currencyCode"] as? String
        result.merchantName  = json["merchantName"] as? String
        result.categoryHint  = json["categoryHint"] as? String
        result.note          = json["note"] as? String
        result.confidence    = json["confidence"] as? Double ?? 0.6

        if let type = json["transactionType"] as? String {
            result.transactionType = type == "income" ? .income : .expense
        }

        if let ds = json["dateString"] as? String, !ds.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            result.date = formatter.date(from: ds)
        }

        return result
    }
}
