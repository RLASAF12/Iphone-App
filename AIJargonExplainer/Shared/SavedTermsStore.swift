import Foundation

/// Persists saved terms using App Groups shared UserDefaults
/// so the keyboard extension and main app stay in sync.
class SavedTermsStore: ObservableObject {
    @Published var terms: [ExplainedTerm] = []

    private let storageKey = "saved_terms"

    /// Shared container between app and keyboard extension
    private var defaults: UserDefaults {
        UserDefaults(suiteName: "group.com.harelasaf.aijargonexplainer") ?? .standard
    }

    init() {
        load()
    }

    func save(_ term: ExplainedTerm) {
        // Don't save duplicates
        guard !terms.contains(where: { $0.term == term.term }) else { return }
        terms.insert(term, at: 0)
        persist()
    }

    func remove(_ term: ExplainedTerm) {
        terms.removeAll { $0.term == term.term }
        persist()
    }

    func removeAll() {
        terms.removeAll()
        persist()
    }

    func isSaved(_ term: ExplainedTerm) -> Bool {
        terms.contains(where: { $0.term == term.term })
    }

    /// Reload from shared storage (call when app comes to foreground)
    func reload() {
        load()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(terms) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ExplainedTerm].self, from: data) {
            terms = decoded
        }
    }
}
