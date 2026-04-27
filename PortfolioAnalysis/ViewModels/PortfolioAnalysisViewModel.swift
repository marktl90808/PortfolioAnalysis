//
//  PortfolioAnalysisViewModel.swift
//  PortfolioAnalysis
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PortfolioAnalysisViewModel: ObservableObject {
    // MARK: - Persistence Key
    private let savedPortfolioKey = "SavedPortfolioPositions"

    // MARK: - Published State
    @Published private(set) var positions: [ImportedPosition] = []
    @Published private(set) var portfolioTotal: Double = 0
    @Published private(set) var totalCostBasis: Double = 0
    @Published private(set) var totalGrowth: Double = 0
    @Published private(set) var cashTotal: Double = 0
    @Published private(set) var dayChangeTotal: Double = 0
    @Published private(set) var errorMessage: String?

    @Published var analysisResults: [PortfolioAnalysisResult] = []
    @Published var slopeMethod: SlopeMethod = .simpleDelta

    // MARK: - Services
    private let importer = PortfolioImporter()
    private let calculator = PortfolioCalculator()
    private let trendAnalyzer = DefaultTrendAnalyzer()
    let priceService = DefaultMarketDataService()

    // MARK: - Init
    init() {
        loadSavedPortfolio()
    }

    // MARK: - Import From File (CSV)
    func importFile(url: URL) {
        do {
            let _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

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

        // Persist new positions
        savePortfolio()

        recalcTotals()

        Task {
            await runAnalysis()
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

    // MARK: - Run Full Trend Analysis
    func runAnalysis() async {
        var results: [PortfolioAnalysisResult] = []

        for pos in positions {
            guard let symbol = pos.symbol.nonEmpty else { continue }

            let history = await fetchHistorySafe(for: symbol)

            let trend = trendAnalyzer.analyze(
                symbol: symbol,
                prices: history,
                slopeMethod: slopeMethod
            )

            let result = PortfolioAnalysisResult(
                symbol: symbol,
                quantity: pos.quantity ?? 0,
                costBasis: pos.costBasis ?? 0,
                currentPrice: trend.currentPrice,
                yearHighPrice: trend.yearHighPrice,
                dollarDifferenceFromYearHigh: trend.dollarDifferenceFromYearHigh,
                percentDifferenceFromYearHigh: trend.percentDifferenceFromYearHigh,
                trend: trend.trend,
                shortTermSlope: trend.shortTermSlope,
                mediumTermSlope: trend.mediumTermSlope,
                longTermSlope: trend.longTermSlope,
                directionChange: trend.directionChange,
                slopeMethodUsed: trend.slopeMethodUsed,
                isCash: pos.isCash        // <-- ADD THIS
)

            results.append(result)
        }

        self.analysisResults = results
    }

    // MARK: - Reset State
    func resetState() {
        positions = []
        portfolioTotal = 0
        totalCostBasis = 0
        totalGrowth = 0
        cashTotal = 0
        dayChangeTotal = 0
        analysisResults = []
        errorMessage = nil

        // Clear persisted data
        UserDefaults.standard.removeObject(forKey: savedPortfolioKey)
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

    // MARK: - Persistence
    private func savePortfolio() {
        guard !positions.isEmpty else {
            UserDefaults.standard.removeObject(forKey: savedPortfolioKey)
            return
        }

        if let encoded = try? JSONEncoder().encode(positions) {
            UserDefaults.standard.set(encoded, forKey: savedPortfolioKey)
        }
    }

    private func loadSavedPortfolio() {
        guard let data = UserDefaults.standard.data(forKey: savedPortfolioKey),
              let decoded = try? JSONDecoder().decode([ImportedPosition].self, from: data) else {
            return
        }

        self.positions = decoded

        // Rebuild totals and analysis from saved positions
        recalcTotals()

        Task {
            await runAnalysis()
        }
    }
}

// MARK: - Helper
private extension String {
    var nonEmpty: String? {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
