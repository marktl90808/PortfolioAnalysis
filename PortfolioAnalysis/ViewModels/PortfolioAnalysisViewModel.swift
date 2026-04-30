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
    @Published var slopeMethod: SlopeMethod = .simpleDelta

    // MARK: - Services

    private let diskStore = DiskPortfolioStore.shared
    private let marketData = DefaultMarketDataService()

    // MARK: - Legacy Key (for migration)

    private let legacyKey = "SavedPortfolioPositions"

    // MARK: - Startup

    func startupLoad() async {
        isLoading = true

        await migrateIfNeeded()

        let loaded = await diskStore.load()
        positions = loaded

        await loadAllPriceHistory()
        runAnalysis()

        isLoading = false
    }

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

    // MARK: - Analysis

    func runAnalysis() {
        analysisResults = positions.map { pos in
            if pos.isCash { return PortfolioAnalysisResult.cash(position: pos) }

            guard let history = priceHistory[pos.symbol], !history.isEmpty else {
                return PortfolioAnalysisResult.noData(position: pos)
            }

            return PortfolioAnalysisResult.from(position: pos, history: history, slopeMethod: slopeMethod)
        }
    }

    func importPastedPositions(_ imported: [ImportedPosition]) {
        positions = imported
        priceHistory = [:]
        analysisResults = []

        Task {
            await diskStore.save(imported)
            await loadAllPriceHistory()
            runAnalysis()
        }
    }

    // MARK: - Update Methods

    func updateSymbol(for oldSymbol: String, newSymbol: String) {
        guard let index = positions.firstIndex(where: { $0.symbol == oldSymbol }) else { return }

        positions[index].symbol = newSymbol

        if let oldHistory = priceHistory.removeValue(forKey: oldSymbol) {
            priceHistory[newSymbol] = oldHistory
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
        costBasis: Double?
    ) async {
        guard let index = positions.firstIndex(where: { $0.symbol == oldSymbol }) else { return }

        positions[index].symbol = newSymbol
        positions[index].quantity = quantity
        positions[index].value = positions[index].price * quantity

        if let costBasis {
            positions[index].costBasis = costBasis
        }

        priceHistory.removeValue(forKey: oldSymbol)

        await diskStore.save(positions)

        let history = await fetchHistorySafe(for: newSymbol)
        if !history.isEmpty {
            priceHistory[newSymbol] = history
        }

        runAnalysis()
    }

    // MARK: - Add / Remove

    func addPosition(_ pos: ImportedPosition) {
        positions.append(pos)
        Task { await diskStore.save(positions) }
        runAnalysis()
    }

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
}
