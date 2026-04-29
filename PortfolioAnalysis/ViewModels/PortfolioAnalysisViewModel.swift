//
//  PortfolioAnalysisViewModel.swift
//  PortfolioAnalysis
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PortfolioAnalysisViewModel: ObservableObject {

    // MARK: - Published State

    @Published var positions: [ImportedPosition] = []
    @Published var analysisResults: [PortfolioAnalysisResult] = []
    @Published var priceHistory: [String: [PricePoint]] = [:]
    @Published var isLoading: Bool = false

    // MARK: - Services

    private let diskStore = DiskPortfolioStore.shared
    private let marketData = DefaultMarketDataService()

    // MARK: - Legacy Key (for migration)

    private let legacyKey = "SavedPortfolioPositions"

    // MARK: - Startup

    func startupLoad() async {
        isLoading = true

        await migrateIfNeeded()

        positions = await diskStore.load()

        await loadAllPriceHistory()

        runAnalysis()

        isLoading = false
    }

    // MARK: - Auto Migration

    private func migrateIfNeeded() async {
        guard let data = UserDefaults.standard.data(forKey: legacyKey) else { return }

        do {
            let decoded = try JSONDecoder().decode([ImportedPosition].self, from: data)
            await diskStore.save(decoded)
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

    // MARK: - Analysis

    func runAnalysis() {
        analysisResults = positions.compactMap { pos in
            if pos.isCash {
                return .cash(position: pos)
            }

            guard let history = priceHistory[pos.symbol], !history.isEmpty else {
                return .noData(position: pos)
            }

            return .from(position: pos, history: history)
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

        Task { await diskStore.save(positions) }
        runAnalysis()
    }

    func updateCostBasis(for symbol: String, newCostBasis: Double) {
        guard let index = positions.firstIndex(where: { $0.symbol == symbol }) else { return }

        positions[index].costBasis = newCostBasis

        Task { await diskStore.save(positions) }
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
}
