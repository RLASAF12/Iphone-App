import Foundation

/// Represents a single explained term
struct ExplainedTerm: Codable, Identifiable, Equatable {
    var id = UUID()
    let term: String
    let explanation: String
}

class GeminiService {

    /// Sends text to Gemini API and returns structured term explanations as JSON.
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
        IMPORTANT: Respond ONLY with a JSON array. No markdown, no asterisks, no extra text. \
        Each item must have "term" and "explanation" keys. \
        Example: [{"term":"LLM","explanation":"Large Language Model. An AI program trained on massive text data to understand and generate human language."}] \
        If there are no AI/tech terms, return: [{"term":"No AI terms","explanation":"No AI or technology terms were found in this text."}] \
        Keep each explanation under 30 words.

        Text: \(text)
        """

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 500,
                "temperature": 0.2
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
            return [ExplainedTerm(term: "Error", explanation: "Invalid request. Check your API key.")]
        case 401, 403:
            return [ExplainedTerm(term: "Error", explanation: "Authentication failed. Check your API key.")]
        case 429:
            return [ExplainedTerm(term: "Rate Limit", explanation: "Too many requests. Free tier allows ~15/min. Wait a moment.")]
        default:
            return [ExplainedTerm(term: "Error", explanation: "API Error (HTTP \(httpResponse.statusCode)). Try again.")]
        }

        // Parse Gemini response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {

            let cleaned = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let jsonData = cleaned.data(using: .utf8),
               let terms = try? JSONDecoder().decode([ExplainedTerm].self, from: jsonData) {
                return terms
            }

            // Fallback: return raw text as single term
            return [ExplainedTerm(term: "Result", explanation: cleaned)]
        }

        return [ExplainedTerm(term: "Error", explanation: "Could not parse the response. Try again.")]
    }
}
