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
    private let importer = PortfolioImporter()          // CSV importer
    private let calculator = PortfolioCalculator()
    let priceService = DefaultMarketDataService()

    // MARK: - Import From File (CSV)
    func importFile(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let imported = try importer.parseCSVFile(text)
            applyImportedPositions(imported)
        } catch {
            errorMessage = "Failed to import file: \(error.localizedDescription)"
        }
    }

    // MARK: - Import From Paste (TSV)
    func importPastedPositions(_ positions: [ImportedPosition]) {
        applyImportedPositions(positions)
    }

    // MARK: - Apply Imported Data
    private func applyImportedPositions(_ imported: [ImportedPosition]) {
        guard !imported.isEmpty else {
            errorMessage = "No valid rows found."
            return
        }

        self.positions = imported
        errorMessage = nil
        recalcTotals()
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

    // MARK: - Safe History Fetch
    func fetchHistorySafe(for symbol: String) async -> [PricePoint] {
        do {
            return try await priceService.fetchPrices(for: symbol)
        } catch {
            print("History fetch failed for \(symbol): \(error)")
            return []
        }
    }
}
// end of file

