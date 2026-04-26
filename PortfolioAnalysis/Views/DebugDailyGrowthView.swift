//
//  DebugDailyGrowthView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct DebugDailyGrowthView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    var body: some View {
        VStack(spacing: 16) {

            Text("Daily Growth Debug")
                .font(.title2.bold())

            // Total day change
            Text(viewModel.dayChangeTotal.formatted(.currency(code: "USD")))
                .font(.largeTitle.bold())
                .foregroundColor(viewModel.dayChangeTotal >= 0 ? .green : .red)

            Divider().padding(.vertical, 8)

            // Per‑position imported day change (if available)
            VStack(alignment: .leading, spacing: 12) {
                Text("Imported Per‑Position Day Change")
                    .font(.headline)

                ForEach(viewModel.positions) { position in
                    if let dc = position.dayChangeAmount {
                        HStack {
                            Text(position.ticker)
                                .font(.headline)

                            Spacer()

                            Text(dc.formatted(.currency(code: "USD")))
                                .foregroundColor(dc >= 0 ? .green : .red)
                        }

                        Divider()
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Debug Daily Growth")
    }
}
