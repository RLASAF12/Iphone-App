import Foundation

class GeminiService {

    /// Sends text to Gemini API and returns a plain-English explanation of AI terms found in it.
    func explainAITerms(text: String) async throws -> String {
        let apiKey = SharedDefaults.apiKey
        guard !apiKey.isEmpty else {
            return "No API key configured. Open the main app to set your Gemini API key."
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
        Format as a bullet list: "- TERM: explanation". \
        If there are no AI/tech terms, say "No AI terms found in this text." \
        Keep the total response under 150 words. Be concise and friendly.

        Text: \(text)
        """

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 300,
                "temperature": 0.3
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
            return "Invalid request. Please check your API key in the main app."
        case 401, 403:
            return "Authentication failed. Please check your API key in the main app."
        case 429:
            return "Rate limit reached. The free tier allows ~15 requests per minute. Please wait a moment and try again."
        default:
            return "API Error (HTTP \(httpResponse.statusCode)). Please try again."
        }

        // Parse the Gemini response JSON
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return "Could not parse the response. Please try again."
    }
}
