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
    @Published private(set) var positions: [ImportedPosition] = []
    @Published private(set) var portfolioTotal: Double = 0
    @Published private(set) var totalCostBasis: Double = 0
    @Published private(set) var totalGrowth: Double = 0
    @Published private(set) var cashTotal: Double = 0
    @Published private(set) var dayChangeTotal: Double = 0
    @Published var errorMessage: String?

    // MARK: - Services
    private let importer = PortfolioImporter()
    private let calculator = PortfolioCalculator()
    let priceService = DefaultMarketDataService()

    // MARK: - Import From File
    func importFile(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            importPastedText(text)
        } catch {
            errorMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }

    // MARK: - Import From Paste
    func importPastedText(_ text: String) {
        do {
            let imported = try importer.parseCSV(text)
            positions = imported
            errorMessage = nil
            recalcTotals()
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Recalculate Totals
    func recalcTotals() {
        let result = calculator.calculateTotals(for: positions, using: priceService)

        portfolioTotal = result.portfolioTotal
        totalCostBasis = result.totalCostBasis
        totalGrowth = result.totalGrowth
        cashTotal = result.cashTotal
        dayChangeTotal = result.dayChangeTotal
    }

    // MARK: - Reset State
    func resetState() {
        positions = []
        portfolioTotal = 0
        totalCostBasis = 0
        totalGrowth = 0
        cashTotal = 0
        dayChangeTotal = 0
        errorMessage = nil
    }

    // MARK: - Safe History Fetch (Option A)
    func fetchHistorySafe(for symbol: String) async -> [PricePoint] {
        do {
            // Uses your existing priceService.fetchPrices(for:)
            let points = try await priceService.fetchPrices(for: symbol)
            return points
        } catch {
            print("History fetch failed for \(symbol): \(error)")
            return []
        }
    }
}

