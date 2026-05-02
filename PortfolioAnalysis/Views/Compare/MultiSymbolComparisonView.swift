//
//  MultiSymbolComparisonView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct MultiSymbolComparisonView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    @State private var searchText: String = ""
    @State private var selectedSymbols: [String] = []
    @State private var mode: CompareMode = .performance   // Performance | Price

    private let maxSymbols = 3

    var body: some View {
        VStack(spacing: 12) {

            // Search bar
            TextField("Add symbol…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Autocomplete
            if !searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.analysisResults.filter {
                            $0.symbol.lowercased().contains(searchText.lowercased())
                        }) { result in
                            Button {
                                addSymbol(result.symbol)
                            } label: {
                                Text(result.symbol)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 10)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Selected symbol chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedSymbols, id: \.self) { symbol in
                        HStack(spacing: 6) {
                            Text(symbol)
                            Image(systemName: "xmark.circle.fill")
                                .onTapGesture { removeSymbol(symbol) }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
            }

            // Segmented toggle
            Picker("", selection: $mode) {
                Text("Performance").tag(CompareMode.performance)
                Text("Price").tag(CompareMode.price)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Chart
            MultiSymbolStockChartView(
                symbols: selectedSymbols,
                histories: historiesForSelectedSymbols,
                mode: mode
            )
            .frame(height: 320)
            .padding(.horizontal, 8)

            Spacer()
        }
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var historiesForSelectedSymbols: [String: [PricePoint]] {
        var dict: [String: [PricePoint]] = [:]
        for symbol in selectedSymbols {
            dict[symbol] = viewModel.priceHistory[symbol] ?? []
        }
        return dict
    }

    private func addSymbol(_ symbol: String) {
        guard !selectedSymbols.contains(symbol),
              selectedSymbols.count < maxSymbols else { return }
        selectedSymbols.append(symbol)
        searchText = ""
    }

    private func removeSymbol(_ symbol: String) {
        selectedSymbols.removeAll { $0 == symbol }
    }
}

enum CompareMode {
    case performance
    case price
}
// MARK: End of MultiSymbolComparisonView.swift

