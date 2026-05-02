//
//  AnalysisResultsView.swift
//  PortfolioAnalysis
//

import SwiftUI

enum ResultsSortMode: String, CaseIterable, Identifiable {
    case gapAscending = "52WH: Low → High"
    case gapDescending = "52WH: High → Low"
    case alphaAZ = "Alphabetical A → Z"
    case alphaZA = "Alphabetical Z → A"
    case dayGrowthAscending = "Day Change: Low → High"
    case dayGrowthDescending = "Day Change: High → Low"

    var id: String { rawValue }
}

struct AnalysisResultsView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    @State private var sortMode: ResultsSortMode = .gapAscending

    // MARK: - Computed Totals

    private var cashTotal: Double {
        viewModel.analysisResults
            .filter { $0.isCash }
            .map { $0.totalValue }
            .reduce(0, +)
    }

    private var investedTotal: Double {
        viewModel.analysisResults
            .filter { !$0.isCash }
            .map { $0.totalValue }
            .reduce(0, +)
    }

    private var portfolioTotal: Double {
        cashTotal + investedTotal
    }

    private var totalGainLoss: Double {
        viewModel.analysisResults
            .map { $0.gainLoss }
            .reduce(0, +)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {

            // Header row with title + Sort text link
            HStack {
                Text("Analysis Results")
                    .font(.title2.bold())

                Spacer()

                Menu {
                    Picker("Sort Mode", selection: $sortMode) {
                        ForEach(ResultsSortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } label: {
                    Text("Sort")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Totals Section
            totalsSection

            // Results List
            List {
                ForEach(sortedResults) { result in
                    let dayChange = dayChange(for: result)

                    if viewModel.priceHistory[result.symbol] != nil {
                        NavigationLink {
                            StockDetailView(
                                initialSymbol: result.symbol,
                                viewModel: viewModel,
                                orderedResults: sortedResults
                            )
                        } label: {
                            PositionRowView(result: result, dayChange: dayChange)
                        }
                    } else {
                        PositionRowView(result: result, dayChange: dayChange)
                    }
                }
            }
        }
        .navigationTitle("Analysis Results")
    }

    // MARK: - Sorting Logic

    private var sortedResults: [PortfolioAnalysisResult] {
        let nonCash = viewModel.analysisResults.filter { !$0.isCash }
        let cash = viewModel.analysisResults.filter { $0.isCash }

        let sortedNonCash: [PortfolioAnalysisResult]

        switch sortMode {

        case .gapAscending:
            // 52WH: lowest (most negative) to highest
            sortedNonCash = nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                a.percentDifferenceFromYearHigh < b.percentDifferenceFromYearHigh
            }

        case .gapDescending:
            // 52WH: highest (closest to / above high) to lowest
            sortedNonCash = nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                a.percentDifferenceFromYearHigh > b.percentDifferenceFromYearHigh
            }

        case .alphaAZ:
            sortedNonCash = nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                a.symbol < b.symbol
            }

        case .alphaZA:
            sortedNonCash = nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                a.symbol > b.symbol
            }

        case .dayGrowthAscending:
            sortedNonCash = nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                dayChange(for: a) < dayChange(for: b)
            }

        case .dayGrowthDescending:
            sortedNonCash = nonCash.sorted { (a: PortfolioAnalysisResult, b: PortfolioAnalysisResult) in
                dayChange(for: a) > dayChange(for: b)
            }
        }

        // Cash always at bottom
        return sortedNonCash + cash
    }

    // MARK: - Totals Section

    private var totalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Portfolio Summary")
                .font(.headline)

            // Portfolio Total (Cash + Positions)
            HStack {
                Text("Total Value:")
                Spacer()
                Text(portfolioTotal, format: .currency(code: "USD"))
            }

            // Cash Total
            HStack {
                Text("Cash Total:")
                Spacer()
                Text(cashTotal, format: .currency(code: "USD"))
            }

            // Invested Total
            HStack {
                Text("Invested:")
                Spacer()
                Text(investedTotal, format: .currency(code: "USD"))
            }

            // Total Gain/Loss
            HStack {
                Text("Total Gain/Loss:")
                Spacer()
                Text(totalGainLoss, format: .currency(code: "USD"))
            }

            // Day Change
            HStack {
                Text("Day Change:")
                Spacer()
                Text(viewModel.dayChangeTotal, format: .currency(code: "USD"))
                    .foregroundColor(viewModel.dayChangeTotal < 0 ? .red : .green)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func dayChange(for result: PortfolioAnalysisResult) -> Double {
        guard !result.isCash,
              let history = viewModel.priceHistory[result.symbol],
              history.count >= 2 else { return 0 }

        let latest = history[history.count - 1].close
        let previous = history[history.count - 2].close
        return (latest - previous) * result.quantity
    }
}
// MARK: End of AnalysisResultsView.swift

