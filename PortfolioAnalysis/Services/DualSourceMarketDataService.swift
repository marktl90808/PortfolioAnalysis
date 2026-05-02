//
//  DualSourceMarketDataService.swift
//  PortfolioAnalysis
//

import Foundation

// MARK: - Primary Adapter (wraps your existing DefaultMarketDataService)

struct PrimaryMarketDataServiceAdapter: MarketDataService {

    private let service = DefaultMarketDataService()

    func fetchQuote(for symbol: String) async throws -> MarketQuote {
        try await service.fetchQuote(for: symbol)
    }

    func fetchPrices(for symbol: String) async throws -> [PricePoint] {
        try await service.fetchPrices(for: symbol)
    }

    func cachedPrice(for symbol: String) -> Double? {
        service.cachedPrice(for: symbol)
    }

    func cachedQuote(for symbol: String) -> MarketQuote? {
        service.cachedQuote(for: symbol)
    }
}

// MARK: - Secondary Adapter (placeholder for now)

struct SecondaryMarketDataServiceAdapter: MarketDataService {

    func fetchQuote(for symbol: String) async throws -> MarketQuote {
        throw NSError(domain: "SecondaryMarketDataService", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Secondary provider not implemented"
        ])
    }

    func fetchPrices(for symbol: String) async throws -> [PricePoint] {
        throw NSError(domain: "SecondaryMarketDataService", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Secondary provider not implemented"
        ])
    }

    func cachedPrice(for symbol: String) -> Double? {
        nil
    }

    func cachedQuote(for symbol: String) -> MarketQuote? {
        nil
    }
}

// MARK: - Comparison Result

struct PriceDataComparison {
    let latestDifference: Double
    let dayChangeDifference: Double
    let historyLengthDifference: Int
}

// MARK: - Dual Source Service

final class DualSourceMarketDataService: MarketDataService {

    private let primary: MarketDataService
    private let secondary: MarketDataService

    init(
        primary: MarketDataService = PrimaryMarketDataServiceAdapter(),
        secondary: MarketDataService = PolygonMarketDataService(apiKey: "MYDY2HoAh0kxsYX9OJtUI5l5VT1yJCe9")
    )
 {
        self.primary = primary
        self.secondary = secondary
    }

    // MARK: - Protocol Conformance

    func fetchQuote(for symbol: String) async throws -> MarketQuote {
        do {
            return try await primary.fetchQuote(for: symbol)
        } catch {
            print("⚠️ Primary quote failed for \(symbol): \(error)")
            return try await secondary.fetchQuote(for: symbol)
        }
    }

    func fetchPrices(for symbol: String) async throws -> [PricePoint] {
        do {
            let primaryHistory = try await primary.fetchPrices(for: symbol)

            // Compare with secondary in background
            Task.detached {
                await self.compareWithSecondary(symbol: symbol, primaryHistory: primaryHistory)
            }

            return primaryHistory

        } catch {
            print("⚠️ Primary prices failed for \(symbol): \(error)")
            return try await secondary.fetchPrices(for: symbol)
        }
    }

    func cachedPrice(for symbol: String) -> Double? {
        primary.cachedPrice(for: symbol) ?? secondary.cachedPrice(for: symbol)
    }

    func cachedQuote(for symbol: String) -> MarketQuote? {
        primary.cachedQuote(for: symbol) ?? secondary.cachedQuote(for: symbol)
    }

    // MARK: - Comparison Logic

    private func compareWithSecondary(symbol: String, primaryHistory: [PricePoint]) async {
        do {
            let secondaryHistory = try await secondary.fetchPrices(for: symbol)
            let comparison = compare(primaryHistory, secondaryHistory)
            logDiscrepancyIfNeeded(symbol: symbol, comparison: comparison)
        } catch {
            print("⚠️ Secondary provider failed for \(symbol): \(error)")
        }
    }

    private func compare(_ a: [PricePoint], _ b: [PricePoint]) -> PriceDataComparison {
        let latestA = a.last?.close ?? 0
        let latestB = b.last?.close ?? 0

        let prevA = a.dropLast().last?.close ?? latestA
        let prevB = b.dropLast().last?.close ?? latestB

        let changeA = latestA - prevA
        let changeB = latestB - prevB

        let lengthDiff = a.count - b.count

        return PriceDataComparison(
            latestDifference: latestA - latestB,
            dayChangeDifference: changeA - changeB,
            historyLengthDifference: lengthDiff
        )
    }

    private func logDiscrepancyIfNeeded(symbol: String, comparison: PriceDataComparison) {
        let priceThreshold = 0.05
        let changeThreshold = 0.10
        let lengthThreshold = 3

        var messages: [String] = []

        if abs(comparison.latestDifference) > priceThreshold {
            messages.append("Latest price differs by \(comparison.latestDifference)")
        }

        if abs(comparison.dayChangeDifference) > changeThreshold {
            messages.append("Day change differs by \(comparison.dayChangeDifference)")
        }

        if abs(comparison.historyLengthDifference) > lengthThreshold {
            messages.append("History length differs by \(comparison.historyLengthDifference)")
        }

        guard !messages.isEmpty else { return }

        let combined = messages.joined(separator: ", ")

        print("⚠️ Data discrepancy for \(symbol): \(combined)")

        // NEW: send to log viewer
        Task { @MainActor in
            DiscrepancyLogStore.shared.add(symbol: symbol, message: combined)
        }
    }

}
