//
//  MultiSymbolComparisonView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct MultiSymbolComparisonView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    @State private var firstSymbol: String = "AAPL"
    @State private var secondSymbol: String = "HPQ"
    @State private var range: TimeRange = .oneMonth
    @State private var comparisonSeries: [SymbolSeries] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .red]

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Compare any two tickers")
                        .font(.headline)

                    VStack(spacing: 10) {
                        TextField("First ticker", text: $firstSymbol)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)

                        TextField("Second ticker", text: $secondSymbol)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                    }

                    Button {
                        Task { await compareSymbols() }
                    } label: {
                        Label("Compare Stocks", systemImage: "chart.line.uptrend.xyaxis")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)

                if isLoading {
                    ProgressView("Loading comparison…")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !comparisonSeries.isEmpty {
                    comparisonLegend

                    MultiSymbolStockChartView(series: comparisonSeries, range: range)
                        .frame(height: 260)

                    timeRangeSelector

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(comparisonSummaries) { summary in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(summary.color)
                                            .frame(width: 8, height: 8)

                                        Text(summary.symbol)
                                            .font(.headline)
                                            .foregroundColor(summary.color)
                                    }
                                    Text("Current: \(summary.currentPrice, format: .currency(code: currencyCode))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(summary.rangeChange, format: .currency(code: currencyCode))
                                        .foregroundColor(summary.rangeChange < 0 ? .red : .green)
                                    Text(String(format: "%.2f%%", summary.rangePercent))
                                        .font(.caption)
                                        .foregroundColor(summary.rangePercent < 0 ? .red : .green)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Compare Stocks")
        .task {
            if comparisonSeries.isEmpty {
                await compareSymbols()
            }
        }
    }

    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TimeRange.allCases) { r in
                    Text(r.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(r == range ? .primary : .secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(r == range ? Color.blue.opacity(0.18) : Color.clear)
                        .clipShape(Capsule())
                        .onTapGesture {
                            range = r
                            Task { await compareSymbols() }
                        }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var comparisonSummaries: [ComparisonSummary] {
        comparisonSeries.compactMap { entry in
            comparisonSummary(for: entry)
        }
    }

    private var comparisonLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(comparisonSeries) { entry in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(entry.color)
                            .frame(width: 8, height: 8)
                        Text(entry.symbol)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(entry.color)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(entry.color.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compareSymbols() async {
        let first = normalizeSymbol(firstSymbol)
        let second = normalizeSymbol(secondSymbol)

        guard !first.isEmpty, !second.isEmpty else {
            errorMessage = "Enter two ticker symbols to compare."
            comparisonSeries = []
            return
        }

        guard first != second else {
            errorMessage = "Please enter two different tickers."
            comparisonSeries = []
            return
        }

        isLoading = true
        errorMessage = nil

        let firstHistory = await viewModel.fetchHistorySafe(for: first)
        let secondHistory = await viewModel.fetchHistorySafe(for: second)

        isLoading = false

        var freshSeries: [SymbolSeries] = []
        if !firstHistory.isEmpty {
            freshSeries.append(SymbolSeries(symbol: first, history: firstHistory, color: palette[0 % palette.count]))
        }
        if !secondHistory.isEmpty {
            freshSeries.append(SymbolSeries(symbol: second, history: secondHistory, color: palette[1 % palette.count]))
        }

        if freshSeries.isEmpty {
            errorMessage = "No price history found for those tickers."
        }

        comparisonSeries = freshSeries
    }

    private func normalizeSymbol(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func comparisonSummary(for entry: SymbolSeries) -> ComparisonSummary? {
        let sorted = entry.history.sorted { $0.date < $1.date }
        guard let last = sorted.last else { return nil }

        let start = range.dateWindow(from: last.date)
        let filtered = sorted.filter { $0.date >= start }
        guard let first = filtered.first?.close, let current = filtered.last?.close else { return nil }

        let rangeChange = current - first
        let rangePercent = first == 0 ? 0 : (rangeChange / first) * 100

        return ComparisonSummary(
            symbol: entry.symbol,
            color: entry.color,
            currentPrice: current,
            rangeChange: rangeChange,
            rangePercent: rangePercent
        )
    }
}

private struct ComparisonSummary: Identifiable {
    let id = UUID()
    let symbol: String
    let color: Color
    let currentPrice: Double
    let rangeChange: Double
    let rangePercent: Double
}
