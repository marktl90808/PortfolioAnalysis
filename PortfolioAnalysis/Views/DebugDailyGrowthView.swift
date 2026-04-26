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

            // Per-position snapshot (no more dayChangeAmount on ImportedPosition)
            VStack(alignment: .leading, spacing: 12) {
                Text("Positions Snapshot")
                    .font(.headline)

                ForEach(viewModel.positions) { position in
                    HStack {
                        Text(position.symbol)
                            .font(.headline)

                        Spacer()

                        Text(position.value.formatted(.currency(code: "USD")))
                            .foregroundColor(.secondary)
                    }

                    Divider()
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Debug Daily Growth")
    }
}
//end of file
