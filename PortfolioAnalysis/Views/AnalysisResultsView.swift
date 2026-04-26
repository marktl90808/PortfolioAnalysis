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

// MARK: - View
struct AnalysisResultsView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel   // ← REQUIRED FIX

    let results: [PortfolioAnalysisResult]
    let cashTotal: Double
    let dailyGrowthTotal: Double

    @State private var sortMode: ResultsSortMode = .gapAscending

    private func percentBelow(_ result: PortfolioAnalysisResult) -> Double {
        let current = result.analysis.currentPrice
        let high = result.analysis.yearHighPrice
        return high > 0 ? (1 - (current / high)) * 100 : 0
    }

    // MARK: - Sorting Logic
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
    @ViewBuilder
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

    @ViewBuilder
    private func quantityAndPriceView(for result: PortfolioAnalysisResult) -> some View {
        let qty: Double = result.quantity ?? 0
        let currentPrice: Double = result.analysis.currentPrice

        HStack(spacing: 12) {
            Text(String(format: "Qty: %.3f", qty))
            Text("Current: \(currentPrice, format: .currency(code: "USD"))")
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private func valueAndGapView(for result: PortfolioAnalysisResult) -> some View {
        let totalValue: Double = result.totalValue ?? 0
        let gapDollar: Double = result.analysis.dollarDifferenceFromYearHigh

        HStack(spacing: 12) {
            Text("Value: \(totalValue, format: .currency(code: "USD"))")
            Text("Gap: \(gapDollar, format: .currency(code: "USD"))")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: Header
                VStack(alignment: .leading, spacing: 8) {

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

                    HStack(spacing: 6) {
                        Text("Cash Total:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text(cashTotal, format: .currency(code: "USD"))
                            .font(.caption.weight(.semibold))
                    }

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
                }

                // MARK: Results List
                ForEach(Array(sortedResults.enumerated()), id: \.offset) { _, result in
                    NavigationLink {
                        StockDetailView(
                            viewModel: viewModel,                 // ← FIX
                            symbol: result.analysis.symbol        // ← FIX
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            symbolAndNameView(for: result)
                            quantityAndPriceView(for: result)
                            valueAndGapView(for: result)

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
// end of AnalysisResultsView.swift
