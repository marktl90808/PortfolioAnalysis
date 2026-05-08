//
//  PortfolioAnalysisViewModel.swift
//  PortfolioAnalysis
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PortfolioAnalysisViewModel: ObservableObject {

    // MARK: - Published State

    @Published var positions: [ImportedPosition] = []
    @Published var analysisResults: [PortfolioAnalysisResult] = []
    @Published var priceHistory: [String: [PricePoint]] = [:]
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String? = nil
    @Published var slopeMethod: SlopeMethod = .simpleDelta

    // MARK: - Sorting

    enum SortMode {
        case symbol
        case value
        case gain
        case accountNumber
    }

    @Published var sortMode: SortMode = .symbol

    // MARK: - Account Totals Summary

    struct AccountTotals: Identifiable {
        let id: String              // accountNumber
        let nickname: String        // accountNickname
        let totalValue: Double
        let cashValue: Double
    }

    var accountSummaries: [AccountTotals] {
        let grouped = Dictionary(grouping: positions, by: { $0.accountNumber })

        return grouped.map { accountNumber, positions in
            let nickname = positions.first?.accountNickname ?? accountNumber

            let totalValue = positions.reduce(0) { $0 + $1.value }
            let cashValue = positions
                .filter { $0.isCash }
                .reduce(0) { $0 + $1.value }

            return AccountTotals(
                id: accountNumber,
                nickname: nickname,
                totalValue: totalValue,
                cashValue: cashValue
            )
        }
        .sorted { $0.nickname < $1.nickname }
    }

    // MARK: - Services

    private let diskStore = DiskPortfolioStore.shared
    private let marketData: MarketDataService = DualSourceMarketDataService()

    // MARK: - Legacy Key (for migration)

    private let legacyKey = "SavedPortfolioPositions"

    // MARK: - Normalization Helpers

    private func normalize(_ position: ImportedPosition) -> ImportedPosition {
        var p = position
        p.symbol = p.symbol
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        p.name = p.name
            .smartTitleCase()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return p
    }

    private func normalizeAllPositions() {
        positions = positions.map { normalize($0) }
    }

    // MARK: - Startup

    func startupLoad() async {
        isLoading = true
        loadingMessage = "Refreshing data… Please wait"

        await migrateIfNeeded()

        let loaded = await diskStore.load()
        positions = loaded.map { normalize($0) }   // ⭐ normalize on load

        await loadAllPriceHistory()
        runAnalysis()

        loadingMessage = nil
        isLoading = false
    }

    // MARK: - Totals

    var cashTotal: Double {
        positions.filter(\.isCash).reduce(0) { $0 + $1.value }
    }

    var portfolioTotal: Double {
        positions.reduce(0) { partial, position in
            partial + currentMarketValue(for: position)
        }
    }

    var dayChangeTotal: Double {
        positions.reduce(0) { partial, position in
            partial + dayChange(for: position)
        }
    }

    // MARK: - Auto Migration

    private func migrateIfNeeded() async {
        guard let data = UserDefaults.standard.data(forKey: legacyKey) else { return }

        do {
            let decoder = JSONDecoder()
            let oldPositions = try decoder.decode([ImportedPosition].self, from: data)
            await diskStore.save(oldPositions)
            UserDefaults.standard.removeObject(forKey: legacyKey)
        } catch {
            print("⚠️ Migration failed: \(error)")
        }
    }

    // MARK: - Price History Loading

    private func loadAllPriceHistory() async {
        priceHistory = [:]

        for pos in positions where !pos.isCash {
            do {
                let history = try await marketData.fetchPrices(for: pos.symbol)
                priceHistory[pos.symbol] = history
            } catch {
                print("⚠️ Failed to load history for \(pos.symbol): \(error)")
            }
        }
    }

    func fetchHistorySafe(for symbol: String) async -> [PricePoint] {
        if let cached = priceHistory[symbol], !cached.isEmpty { return cached }

        do {
            let history = try await marketData.fetchPrices(for: symbol)
            priceHistory[symbol] = history
            return history
        } catch {
            print("⚠️ Failed to fetch history for \(symbol): \(error)")
            return []
        }
    }

    // MARK: - Symbol Validation / Lookup

    func validateSymbol(_ symbol: String) async -> (isValid: Bool, displayName: String) {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return (false, "") }
        do {
            let history = try await marketData.fetchPrices(for: trimmed)
            if !history.isEmpty {
                return (true, trimmed)
            }
            return (false, trimmed)
        } catch {
            return (false, trimmed)
        }
    }

    // MARK: - Refresh

    func refresh() async {
        isLoading = true
        loadingMessage = "Refreshing data… Please wait"

        normalizeAllPositions()          // ⭐ keep data clean
        await loadAllPriceHistory()
        runAnalysis()

        loadingMessage = nil
        isLoading = false
    }

    // MARK: - Refresh Market Data

    func refreshMarketData() async {
        isLoading = true
        loadingMessage = "Refreshing market data…"

        normalizeAllPositions()          // ⭐ normalize before using symbols
        priceHistory = [:]

        for pos in positions where !pos.isCash {
            do {
                let history = try await marketData.fetchPrices(for: pos.symbol)
                priceHistory[pos.symbol] = history
            } catch {
                print("⚠️ Failed to refresh history for \(pos.symbol): \(error)")
            }
        }

        runAnalysis()

        loadingMessage = nil
        isLoading = false
    }

    // MARK: - Analysis

    func runAnalysis() {
        analysisResults = positions.map { pos in
            if pos.isCash { return PortfolioAnalysisResult.cash(position: pos) }

            guard let history = priceHistory[pos.symbol], !history.isEmpty else {
                return PortfolioAnalysisResult.noData(position: pos)
            }

            return PortfolioAnalysisResult.from(
                position: pos,
                history: history,
                slopeMethod: slopeMethod
            )
        }
    }

    // MARK: - Import

    func importPastedPositions(_ imported: [ImportedPosition]) {
        positions = imported.map { normalize($0) }   // ⭐ normalize on import
        priceHistory = [:]
        analysisResults = []

        Task {
            loadingMessage = "Refreshing data… Please wait"
            isLoading = true

            await diskStore.save(positions)
            await loadAllPriceHistory()
            runAnalysis()

            loadingMessage = nil
            isLoading = false
        }
    }

    // MARK: - Update Methods

    func updateSymbol(for oldSymbol: String, newSymbol: String) {
        guard let index = positions.firstIndex(where: { $0.symbol == oldSymbol }) else { return }

        let normalizedNew = newSymbol
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        positions[index].symbol = normalizedNew

        if let oldHistory = priceHistory.removeValue(forKey: oldSymbol) {
            priceHistory[normalizedNew] = oldHistory
        }

        Task { await diskStore.save(positions) }
        runAnalysis()
    }

    func updateQuantity(for symbol: String, newQuantity: Double) {
        guard let index = positions.firstIndex(where: { $0.symbol == symbol }) else { return }

        positions[index].quantity = newQuantity
        positions[index].value = positions[index].price * newQuantity

        Task { await diskStore.save(positions) }
        runAnalysis()
    }

    func updateCostBasis(for symbol: String, newCostBasis: Double) {
        guard let index = positions.firstIndex(where: { $0.symbol == symbol }) else { return }

        positions[index].costBasis = newCostBasis

        Task { await diskStore.save(positions) }
        runAnalysis()
    }

    func updateHolding(
        oldSymbol: String,
        newSymbol: String,
        quantity: Double,
        costBasis: Double?,
        purchaseDate: Date?
    ) async {

        guard let index = positions.firstIndex(where: { $0.symbol == oldSymbol }) else { return }

        let normalizedNew = newSymbol
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        positions[index].symbol = normalizedNew
        positions[index].quantity = quantity
        positions[index].value = positions[index].price * quantity

        if let costBasis {
            positions[index].costBasis = costBasis
        }

        positions[index].purchaseDate = purchaseDate

        if oldSymbol != normalizedNew {
            if let oldHistory = priceHistory.removeValue(forKey: oldSymbol) {
                priceHistory[normalizedNew] = oldHistory
            }
        }

        await diskStore.save(positions)

        let history = await fetchHistorySafe(for: normalizedNew)
        if !history.isEmpty {
            priceHistory[normalizedNew] = history
        }

        runAnalysis()
    }

    // MARK: - Add / Remove

    func addPosition(_ pos: ImportedPosition) {
        positions.append(normalize(pos))          // ⭐ normalize on add
        Task { await diskStore.save(positions) }
        runAnalysis()
    }

    // ⭐ NEW — required by AddPositionView
    func addManualPosition(_ pos: ImportedPosition) {
        positions.append(normalize(pos))          // ⭐ normalize on manual add
        analysisResults = []

        Task {
            await diskStore.save(positions)
            await loadAllPriceHistory()
            runAnalysis()
        }
    }

    // MARK: Sell a position, convert profit to cash, and update the portfolio accordingly
    func sellPosition(symbol: String) async {
        guard let index = positions.firstIndex(where: { $0.symbol == symbol }) else { return }

        let pos = positions[index]
        let proceeds = pos.value

        // 1. Remove the sold position
        positions.remove(at: index)
        priceHistory.removeValue(forKey: symbol)

        // 2. Add proceeds to cash
        if let cashIndex = positions.firstIndex(where: { $0.isCash }) {
            positions[cashIndex].value += proceeds
        } else {
            // Create a new cash position
            let cash = ImportedPosition(
                symbol: "CASH",
                name: "Cash",
                quantity: 1,
                price: proceeds,
                value: proceeds,
                costBasis: nil,
                unitCost: nil,
                purchaseDate: nil,
                accountNumber: "CASH",
                accountNickname: "Cash"
            )
            positions.append(cash)
        }

        // 3. Save + re-run analysis
        await diskStore.save(positions)
        runAnalysis()
    }

    // MARK: Remove a position without selling (e.g. for cleanup or error correction)
    func removePosition(symbol: String) {
        positions.removeAll { $0.symbol == symbol }
        priceHistory.removeValue(forKey: symbol)

        Task { await diskStore.save(positions) }
        runAnalysis()
    }

    // MARK: - Clear All

    func clearPortfolio() {
        positions = []
        priceHistory = [:]
        analysisResults = []

        Task { await diskStore.clear() }
    }

    // MARK: - Totals Helpers

    private func currentMarketValue(for position: ImportedPosition) -> Double {
        if position.isCash { return position.value }

        let marketPrice = priceHistory[position.symbol]?.last?.close ?? position.price
        return position.quantity * marketPrice
    }

    private func dayChange(for position: ImportedPosition) -> Double {
        guard !position.isCash,
              let history = priceHistory[position.symbol],
              history.count >= 2 else { return 0 }

        let latest = history[history.count - 1].close
        let previous = history[history.count - 2].close
        return (latest - previous) * position.quantity
    }

    // MARK: - Portfolio Day Change Summary

    var portfolioDayChangeAmount: Double {
        dayChangeTotal
    }

    var portfolioDayChangePercent: Double {
        let total = portfolioTotal
        guard total != 0 else { return 0 }
        return dayChangeTotal / (total - dayChangeTotal)
    }

    // MARK: - Sorting Helper for UI

    func sortedResultsExcludingCash() -> [PortfolioAnalysisResult] {
        let nonCash: [PortfolioAnalysisResult] = analysisResults.filter { !$0.isCash }

        switch sortMode {

        case .symbol:
            return nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                a.symbol < b.symbol
            }

        case .value:
            return nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                a.totalValue > b.totalValue
            }

        case .gain:
            return nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                a.gainLoss > b.gainLoss
            }

        case .accountNumber:
            return nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                let aAcct = positions.first(where: { $0.symbol == a.symbol })?.accountNumber ?? ""
                let bAcct = positions.first(where: { $0.symbol == b.symbol })?.accountNumber ?? ""

                if aAcct == bAcct {
                    return a.symbol < b.symbol
                }
                return aAcct < bAcct
            }
        }
    }
}

//End of PortfolioAnalysisViewModel.swift
