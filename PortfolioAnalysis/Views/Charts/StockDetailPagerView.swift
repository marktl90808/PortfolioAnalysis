//
//  StockDetailPagerView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 5/8/2026.
//


import SwiftUI

struct StockDetailPagerView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    let orderedResults: [PortfolioAnalysisResult]
    let initialSymbol: String

    @State private var index: Int = 0

    var body: some View {
        TabView(selection: $index) {
            ForEach(orderedResults.indices, id: \.self) { i in
                let symbol = orderedResults[i].symbol

                StockDetailView(
                    initialSymbol: symbol,
                    viewModel: viewModel,
                    orderedResults: orderedResults
                )
                .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onAppear {
            if let start = orderedResults.firstIndex(where: { $0.symbol == initialSymbol }) {
                index = start
            }
        }
    }
}
