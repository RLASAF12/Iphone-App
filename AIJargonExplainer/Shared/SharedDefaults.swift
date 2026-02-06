import Foundation

/// Simplified API key access — reads directly from Constants.swift.
/// No App Groups needed. Just paste your key in Constants.swift.
struct SharedDefaults {

    static var apiKey: String {
        return AppConstants.geminiAPIKey
    }
}
