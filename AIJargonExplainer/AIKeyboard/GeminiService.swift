import Foundation

/// Represents a single explained term
struct ExplainedTerm: Codable, Identifiable, Equatable {
    var id: UUID

    let term: String
    let explanation: String

    // Custom CodingKeys — only encode/decode "term" and "explanation"
    // so that Gemini's JSON (which has no "id") parses correctly.
    enum CodingKeys: String, CodingKey {
        case term
        case explanation
    }

    init(term: String, explanation: String) {
        self.id = UUID()
        self.term = term
        self.explanation = explanation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.term = try container.decode(String.self, forKey: .term)
        self.explanation = try container.decode(String.self, forKey: .explanation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(term, forKey: .term)
        try container.encode(explanation, forKey: .explanation)
    }

    static func == (lhs: ExplainedTerm, rhs: ExplainedTerm) -> Bool {
        lhs.term == rhs.term && lhs.explanation == rhs.explanation
    }
}

class GeminiService {

    /// Sends text to Gemini API and returns structured term explanations.
    func explainAITerms(text: String) async throws -> [ExplainedTerm] {
        let apiKey = SharedDefaults.apiKey
        guard !apiKey.isEmpty, apiKey != "PASTE_YOUR_GEMINI_API_KEY_HERE" else {
            return [ExplainedTerm(term: "Error", explanation: "No API key configured. Open Constants.swift and paste your Gemini API key.")]
        }

        guard let url = URL(string: AppConstants.geminiEndpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 15

        let prompt = """
        You are a helpful assistant that explains AI and technology jargon in plain, simple English. \
        The user copied the following text from a social media post. \
        Identify every AI-related term, acronym, or technical jargon and explain each one in 1-2 simple sentences. \
        IMPORTANT: Respond ONLY with a valid JSON array. No markdown, no code fences, no backticks, no asterisks, no extra text before or after the array. \
        Each item must have exactly two keys: "term" and "explanation". \
        Example response: [{"term":"LLM","explanation":"Large Language Model. An AI program trained on massive text data to understand and generate human language."}] \
        If there are no AI/tech terms, return: [{"term":"No AI terms found","explanation":"No AI or technology jargon was detected in this text."}] \
        Keep each explanation under 30 words. Return ONLY the JSON array, nothing else.

        Text to analyze: \(text)
        """

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 600,
                "temperature": 0.1
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 400:
            return [ExplainedTerm(term: "Error", explanation: "Invalid request. Check your API key and try again.")]
        case 401, 403:
            return [ExplainedTerm(term: "Error", explanation: "Authentication failed. Check your Gemini API key.")]
        case 429:
            return [ExplainedTerm(term: "Rate Limit", explanation: "Too many requests. Free tier allows ~15 per minute. Wait a moment and try again.")]
        default:
            return [ExplainedTerm(term: "Error", explanation: "API Error (HTTP \(httpResponse.statusCode)). Please try again.")]
        }

        // Parse Gemini response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let rawText = parts.first?["text"] as? String {

            return parseTerms(from: rawText)
        }

        return [ExplainedTerm(term: "Error", explanation: "Could not parse the API response. Please try again.")]
    }

    /// Robust JSON extraction from Gemini's response text
    private func parseTerms(from rawText: String) -> [ExplainedTerm] {
        // Step 1: Clean up the response
        var cleaned = rawText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code fences
        cleaned = cleaned
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```JSON", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove any leading text before the first [
        if let startIndex = cleaned.firstIndex(of: "[") {
            cleaned = String(cleaned[startIndex...])
        }

        // Remove any trailing text after the last ]
        if let endIndex = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[...endIndex])
        }

        // Step 2: Try to decode as JSON array
        if let jsonData = cleaned.data(using: .utf8),
           let terms = try? JSONDecoder().decode([ExplainedTerm].self, from: jsonData),
           !terms.isEmpty {
            return terms
        }

        // Step 3: Try manual JSON parsing as fallback
        if let jsonData = cleaned.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
            let terms = jsonArray.compactMap { dict -> ExplainedTerm? in
                guard let term = dict["term"] as? String,
                      let explanation = dict["explanation"] as? String else { return nil }
                return ExplainedTerm(term: term, explanation: explanation)
            }
            if !terms.isEmpty { return terms }
        }

        // Step 4: Final fallback — strip all markdown and return as single explanation
        let plainText = rawText
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to split by lines and create terms from bullet-point style responses
        let lines = plainText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var fallbackTerms: [ExplainedTerm] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Look for patterns like "Term: explanation" or "Term - explanation"
            if let colonRange = trimmed.range(of: ": ") {
                let term = String(trimmed[trimmed.startIndex..<colonRange.lowerBound])
                    .trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "-•")))
                let explanation = String(trimmed[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !term.isEmpty && !explanation.isEmpty {
                    fallbackTerms.append(ExplainedTerm(term: term, explanation: explanation))
                }
            }
        }

        if !fallbackTerms.isEmpty { return fallbackTerms }

        // Absolute last resort
        return [ExplainedTerm(term: "Explanation", explanation: plainText)]
    }
}
