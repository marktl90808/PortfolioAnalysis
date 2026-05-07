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

    var body: some View {
        VStack(spacing: 12) {

            totalsSection

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
            .listStyle(.plain)
            .listRowInsets(EdgeInsets())
            .padding(.horizontal, -16)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Analysis Results")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort Mode", selection: $sortMode) {
                        ForEach(ResultsSortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.headline)
                }
            }
        }
    }

    private var sortedResults: [PortfolioAnalysisResult] {
        let nonCash = viewModel.analysisResults.filter { !$0.isCash }
        let cash = viewModel.analysisResults.filter { $0.isCash }

        let sortedNonCash: [PortfolioAnalysisResult]

        switch sortMode {
        case .gapAscending:
            sortedNonCash = nonCash.sorted { $0.percentDifferenceFromYearHigh < $1.percentDifferenceFromYearHigh }
        case .gapDescending:
            sortedNonCash = nonCash.sorted { $0.percentDifferenceFromYearHigh > $1.percentDifferenceFromYearHigh }
        case .alphaAZ:
            sortedNonCash = nonCash.sorted { $0.symbol < $1.symbol }
        case .alphaZA:
            sortedNonCash = nonCash.sorted { $0.symbol > $1.symbol }
        case .dayGrowthAscending:
            sortedNonCash = nonCash.sorted { dayChange(for: $0) < dayChange(for: $1) }
        case .dayGrowthDescending:
            sortedNonCash = nonCash.sorted { dayChange(for: $0) > dayChange(for: $1) }
        }

        return sortedNonCash + cash
    }

    private var totalsSection: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text("Portfolio Summary")
                .font(.headline)

            HStack {
                Text("Total Value:")
                Spacer()
                Text(portfolioTotal, format: .currency(code: "USD"))
            }

            HStack {
                Text("Cash Total:")
                Spacer()
                Text(cashTotal, format: .currency(code: "USD"))
            }

            HStack {
                Text("Invested:")
                Spacer()
                Text(investedTotal, format: .currency(code: "USD"))
            }

            HStack {
                Text("Total Gain/Loss:")
                Spacer()
                Text(totalGainLoss, format: .currency(code: "USD"))
            }

            HStack {
                Text("Day Change:")
                Spacer()
                Text(viewModel.dayChangeTotal, format: .currency(code: "USD"))
                    .foregroundColor(viewModel.dayChangeTotal < 0 ? .red : .green)
            }
        }
        .padding(.horizontal)
    }

    private func dayChange(for result: PortfolioAnalysisResult) -> Double {
        guard !result.isCash,
              let history = viewModel.priceHistory[result.symbol],
              history.count >= 2 else { return 0 }

        let latest = history[history.count - 1].close
        let previous = history[history.count - 2].close
        return (latest - previous) * result.quantity
    }
}
// End of file

