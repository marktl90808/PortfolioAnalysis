//
//  StockDetailView.swift
//  PortfolioAnalysis
//

import SwiftUI
import Charts

struct StockDetailView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    let symbol: String

    @State private var history: [PricePoint] = []
    @State private var isLoading = false
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 16) {

            // MARK: - Header
            Text(symbol)
                .font(.largeTitle.bold())
                .padding(.top, 12)

            // MARK: - Chart
            if isLoading {
                ProgressView("Loading…")
                    .padding(.top, 40)
            } else if let error = loadError {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top, 40)
            } else if history.isEmpty {
                Text("No price history available")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                Chart(history) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Close", point.close)
                    )
                    .foregroundStyle(.blue)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 260)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.bottom)
        .task {
            await loadHistory()
        }
        .onDisappear {
            history.removeAll()
        }
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Load History (Option A)
    @MainActor
    private func loadHistory() async {
        isLoading = true
        loadError = nil

        let result = await viewModel.fetchHistorySafe(for: symbol)

        if result.isEmpty {
            loadError = "Unable to load price history."
        } else {
            history = result
        }

        isLoading = false
    }
}
