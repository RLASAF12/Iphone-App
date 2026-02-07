import Foundation

/// Persists saved terms to UserDefaults so they survive app restarts.
/// Works in both the main app and keyboard extension.
class SavedTermsStore: ObservableObject {
    @Published var terms: [ExplainedTerm] = []

    private let storageKey = "saved_terms"

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
        terms.removeAll { $0.id == term.id }
        persist()
    }

    func removeAll() {
        terms.removeAll()
        persist()
    }

    func isSaved(_ term: ExplainedTerm) -> Bool {
        terms.contains(where: { $0.term == term.term })
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(terms) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ExplainedTerm].self, from: data) {
            terms = decoded
        }
    }
}
