//
//  ContentView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PortfolioAnalysisViewModel()
    @State private var showPasteImport = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Button {
                    showPasteImport = true
                } label: {
                    Label("Import Portfolio Data", systemImage: "square.and.arrow.down")
                        .font(.title3.bold())
                }
                .buttonStyle(.borderedProminent)

                if !viewModel.analysisResults.isEmpty {
                    NavigationLink {
                        AnalysisResultsView(viewModel: viewModel)
                    } label: {
                        Label("View Analysis Results", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Portfolio Analysis")
            .sheet(isPresented: $showPasteImport) {
                PasteImportView(viewModel: viewModel)
            }
        }
        .developerLabel("ContentView")
    }
}
