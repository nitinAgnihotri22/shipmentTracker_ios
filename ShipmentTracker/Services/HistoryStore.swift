import Foundation

protocol HistoryStoring {
    func loadHistory(for email: String) -> [HistoryItem]
    func saveHistoryItem(_ item: HistoryItem, for email: String)
    func clearHistory(for email: String)
}

final class HistoryStore: HistoryStoring {
    private let store: LocalStore

    init(store: LocalStore = LocalStore()) {
        self.store = store
    }

    func loadHistory(for email: String) -> [HistoryItem] {
        let key = historyKey(for: email)
        return store.load([HistoryItem].self, forKey: key) ?? []
    }

    func saveHistoryItem(_ item: HistoryItem, for email: String) {
        let key = historyKey(for: email)
        var current = loadHistory(for: email).filter { $0.id != item.id }
        current.insert(item, at: 0)
        if current.count > 40 {
            current = Array(current.prefix(40))
        }
        try? store.save(current, forKey: key)
    }

    func clearHistory(for email: String) {
        store.remove(forKey: historyKey(for: email))
    }

    private func historyKey(for email: String) -> String {
        "logistics.history.\(email.lowercased())"
    }
}
