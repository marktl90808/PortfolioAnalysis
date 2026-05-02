import SwiftUI
import Combine
import Foundation

@MainActor
final class DiscrepancyLogStore: ObservableObject, Sendable {

    static let shared = DiscrepancyLogStore()

    @Published private(set) var entries: [LogEntry] = []

    struct LogEntry: Identifiable, Sendable {
        let id = UUID()
        let timestamp: Date
        let symbol: String
        let message: String
    }

    private init() {}

    func add(symbol: String, message: String) {
        let entry = LogEntry(timestamp: Date(), symbol: symbol, message: message)
        entries.insert(entry, at: 0)
    }

    func clear() {
        entries.removeAll()
    }

    // MARK: - Grouped View

    var groupedBySymbol: [(symbol: String, entries: [LogEntry])] {
        let groups = Dictionary(grouping: entries) { $0.symbol }
        return groups
            .map { (symbol: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.symbol < $1.symbol }
    }
}
