//
//  AnalysisResultsView.swift
//  PortfolioAnalysis
//

import SwiftUI

// MARK: - Sort Modes
enum ResultsSortMode: String, CaseIterable, Identifiable {
    case gapAscending = "Gap: Low → High"
    case gapDescending = "Gap: High → Low"
    case valueAscending = "Value: Low → High"
    case valueDescending = "Value: High → Low"
    case tickerAscending = "Ticker: A → Z"
    case tickerDescending = "Ticker: Z → A"

    var id: String { rawValue }
}

struct AnalysisResultsView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    let results: [PortfolioAnalysisResult]
    let cashTotal: Double
    let dailyGrowthTotal: Double

    @State private var sortMode: ResultsSortMode = .gapAscending

    private func percentBelow(_ result: PortfolioAnalysisResult) -> Double {
        let current = result.analysis.currentPrice
        let high = result.analysis.yearHighPrice
        return high > 0 ? (1 - (current / high)) * 100 : 0
    }

    private var sortedResults: [PortfolioAnalysisResult] {
        switch sortMode {
        case .gapAscending:
            return results.sorted { percentBelow($0) < percentBelow($1) }
        case .gapDescending:
            return results.sorted { percentBelow($0) > percentBelow($1) }
        case .valueAscending:
            return results.sorted { ($0.totalValue ?? 0) < ($1.totalValue ?? 0) }
        case .valueDescending:
            return results.sorted { ($0.totalValue ?? 0) > ($1.totalValue ?? 0) }
        case .tickerAscending:
            return results.sorted { $0.analysis.symbol < $1.analysis.symbol }
        case .tickerDescending:
            return results.sorted { $0.analysis.symbol > $1.analysis.symbol }
        }
    }

    // MARK: - Row Components

    private func symbolAndNameView(for result: PortfolioAnalysisResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.analysis.symbol)
                    .font(.headline)
                if !result.position.name.isEmpty {
                    Text(result.position.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    private func quantityAndPriceView(for result: PortfolioAnalysisResult) -> some View {
        let qty = result.quantity ?? 0
        let currentPrice = result.analysis.currentPrice

        return HStack(spacing: 12) {
            Text(String(format: "Qty: %.3f", qty))
            Text("Current: \(currentPrice, format: .currency(code: "USD"))")
        }
        .font(.subheadline)
    }

    private func valueAndGapView(for result: PortfolioAnalysisResult) -> some View {
        let totalValue = result.totalValue ?? 0
        let gapDollar = result.analysis.dollarDifferenceFromYearHigh

        return HStack(spacing: 12) {
            Text("Value: \(totalValue, format: .currency(code: "USD"))")
            Text("Gap: \(gapDollar, format: .currency(code: "USD"))")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }

    private func growthAndPercentView(for result: PortfolioAnalysisResult) -> some View {
        let qty = result.quantity ?? 0
        let currentPrice = result.analysis.currentPrice
        let costBasis = result.position.costBasis ?? 0

        let currentValue = qty * currentPrice
        let growth = currentValue - costBasis
        let percent = costBasis > 0 ? (growth / costBasis) * 100 : 0

        let arrow: String
        let color: Color

        if growth > 0 {
            arrow = "▲"
            color = .green
        } else if growth < 0 {
            arrow = "▼"
            color = .red
        } else {
            arrow = "—"
            color = .secondary
        }

        return HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text(arrow)
                Text(growth, format: .currency(code: "USD"))
            }
            .foregroundColor(color)

            Text(String(format: "%.2f%%", percent))
                .foregroundColor(color)
                .font(.caption)
        }
        .font(.caption)
    }

    private func trendDirectionView(for result: PortfolioAnalysisResult) -> some View {
        let d = result.analysis.directionChange

        let text: String
        let icon: String
        let color: Color

        switch d {
        case .improving:
            text = "Improving"
            icon = "arrow.up.right"
            color = .green
        case .worsening:
            text = "Worsening"
            icon = "arrow.down.right"
            color = .red
        case .bullishReversal:
            text = "Bullish Reversal"
            icon = "arrow.triangle.2.circlepath"
            color = .green
        case .bearishReversal:
            text = "Bearish Reversal"
            icon = "arrow.triangle.2.circlepath"
            color = .red
        case .flat:
            text = "Flat"
            icon = "minus"
            color = .secondary
        }

        return HStack {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .foregroundColor(color)
    }

    private func headerView() -> some View {
        let totalGrowth = viewModel.totalGrowth
        let totalCost = viewModel.totalCostBasis
        let headerPercent = totalCost > 0 ? (totalGrowth / totalCost) * 100 : 0

        return VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("Results")
                    .font(.largeTitle.bold())

                Spacer()

                Menu {
                    Picker("Sort Mode", selection: $sortMode) {
                        ForEach(ResultsSortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } label: {
                    Label(sortMode.rawValue, systemImage: "arrow.up.arrow.down.circle")
                        .font(.caption.weight(.semibold))
                }
            }

            Text("Sorted using: \(sortMode.rawValue)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Slope method picker
            Picker("Slope Method", selection: $viewModel.slopeMethod) {
                ForEach(SlopeMethod.allCases) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(.segmented)

            // Cash Total
            HStack(spacing: 6) {
                Text("Cash Total:")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(cashTotal, format: .currency(code: "USD"))
                    .font(.caption.weight(.semibold))
            }

            // Daily Growth
            HStack(spacing: 6) {
                Text("Daily Growth:")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(dailyGrowthTotal, format: .currency(code: "USD"))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(
                        dailyGrowthTotal > 0 ? .green :
                        (dailyGrowthTotal < 0 ? .red : .secondary)
                    )
            }

            // Growth + Percent (header)
            if totalCost > 0 {
                HStack(spacing: 6) {
                    Text("Growth:")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(totalGrowth, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(
                                totalGrowth > 0 ? .green :
                                (totalGrowth < 0 ? .red : .secondary)
                            )

                        Text(String(format: "%.2f%%", headerPercent))
                            .font(.caption2)
                            .foregroundColor(
                                headerPercent > 0 ? .green :
                                (headerPercent < 0 ? .red : .secondary)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                headerView()

                ForEach(Array(sortedResults.enumerated()), id: \.offset) { _, result in
                    NavigationLink {
                        StockDetailView(
                            viewModel: viewModel,
                            symbol: result.analysis.symbol
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            symbolAndNameView(for: result)
                            quantityAndPriceView(for: result)
                            valueAndGapView(for: result)
                            growthAndPercentView(for: result)
                            trendDirectionView(for: result)

                            ResultHighComparisonView(
                                current: result.analysis.currentPrice,
                                high: result.analysis.yearHighPrice
                            )

                            Text("Tap for chart")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .animation(.easeInOut(duration: 0.25), value: sortMode)

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle("Analysis Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}
