//
//  StockDetailView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct StockDetailView: View {
    let result: PortfolioAnalysisResult
    let history: [PricePoint]        // 1-year history from ViewModel.priceHistory

    @State private var range: TimeRange = .oneMonth
    @State private var showMA20 = false
    @State private var showMA200 = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - Symbol Header
                VStack(spacing: 4) {
                    Text(result.symbol)
                        .font(.largeTitle.bold())

                    Text(result.currentPrice,
                         format: .currency(code: Locale.current.currencyCode ?? "USD"))
                        .font(.title2)
                        .foregroundColor(.primary)

                    let pct = result.percentDifferenceFromYearHigh
                    Text(String(format: "%.2f%% from 52‑week high", pct))
                        .font(.caption)
                        .foregroundColor(pct < 0 ? .red : .green)
                }
                .padding(.top, 8)


                // MARK: - Pro Chart
                StockPriceChartView(
                    history: history,
                    range: range,
                    showMA20: showMA20,
                    showMA200: showMA200
                )
                .frame(height: 260)
                .padding(.horizontal, 8)


                // MARK: - Time Range Selector
                HStack(spacing: 10) {
                    ForEach(TimeRange.allCases) { r in
                        Text(r.rawValue)
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(r == range ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                            .onTapGesture { range = r }
                    }
                }
                .padding(.horizontal)


                // MARK: - MA Toggles
                HStack(spacing: 20) {
                    Toggle("MA20", isOn: $showMA20)
                    Toggle("MA200", isOn: $showMA200)
                }
                .padding(.horizontal)
                .toggleStyle(.switch)


                // MARK: - Position Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position Details")
                        .font(.headline)

                    HStack {
                        Text("Shares:")
                        Spacer()
                        Text("\(result.quantity)")
                    }

                    HStack {
                        Text("Cost Basis:")
                        Spacer()
                        Text(result.costBasis,
                             format: .currency(code: Locale.current.currencyCode ?? "USD"))
                    }

                    HStack {
                        Text("Current Value:")
                        Spacer()
                        Text(result.totalValue,
                             format: .currency(code: Locale.current.currencyCode ?? "USD"))
                    }

                    HStack {
                        Text("52‑Week High:")
                        Spacer()
                        Text(result.yearHighPrice,
                             format: .currency(code: Locale.current.currencyCode ?? "USD"))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(result.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }
}
