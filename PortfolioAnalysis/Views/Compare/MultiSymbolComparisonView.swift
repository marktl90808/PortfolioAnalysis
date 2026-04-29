//
//  MultiSymbolComparisonView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/28/2026.
//


import SwiftUI

struct MultiSymbolComparisonView: View {
    let results: [PortfolioAnalysisResult]
    let histories: [String: [PricePoint]]

    @State private var range: TimeRange = .oneMonth

    private var series: [SymbolSeries] {
        results.compactMap { r in
            guard let h = histories[r.symbol], !h.isEmpty else { return nil }
            return SymbolSeries(symbol: r.symbol, history: h)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            MultiSymbolStockChartView(series: series, range: range)
                .frame(height: 260)

            HStack {
                ForEach(TimeRange.allCases) { r in
                    Text(r.rawValue)
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(r == range ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                        .onTapGesture { range = r }
                }
            }
            .padding(.horizontal)

            List(results, id: \.symbol) { r in
                HStack {
                    Text(r.symbol)
                    Spacer()
                    Text(r.totalValue, format: .currency(code: Locale.current.currencyCode ?? "USD"))
                }
            }
        }
        .navigationTitle("Compare")
    }
}
