import Foundation

enum AppConstants {
    /// App Group identifier — must match in both targets' Signing & Capabilities
    static let appGroupID = "group.com.aijargonexplainer.shared"

    /// Key used to store/retrieve the Gemini API key in shared UserDefaults
    static let apiKeyStorageKey = "gemini_api_key"

    /// Gemini API endpoint
    static let geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"
}
