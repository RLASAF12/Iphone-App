import Foundation

/// Wrapper around App Group UserDefaults for sharing data between the main app and keyboard extension.
struct SharedDefaults {

    static var shared: UserDefaults? {
        UserDefaults(suiteName: AppConstants.appGroupID)
    }

    static var apiKey: String {
        get { shared?.string(forKey: AppConstants.apiKeyStorageKey) ?? "" }
        set { shared?.set(newValue, forKey: AppConstants.apiKeyStorageKey) }
    }
}
